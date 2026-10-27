import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/sync/sync_history.dart';
import 'package:jasstafel/common/sync/sync_session.dart';
import 'package:jasstafel/common/sync/sync_transport.dart';

/// The radios of all devices in a test, linked as a real network would be.
class FakeNetwork {
  final transports = <String, FakeTransport>{};
  final hosting = <String, FakeTransport>{};

  /// Every host advertises once more, as they do all the time.
  void advertise() {
    for (final transport in transports.values) {
      transport._seeHosts();
    }
  }
}

/// A radio in a [FakeNetwork]. Messages are delivered in a microtask.
class FakeTransport implements SyncTransport {
  FakeTransport(this.id, this.network) {
    network.transports[id] = this;
  }

  final String id;
  final FakeNetwork network;

  BluetoothState _state = BluetoothState.on;
  final _stateChanged = StreamController<BluetoothState>.broadcast();
  final _peerJoined = StreamController<String>.broadcast();
  final _peerLeft = StreamController<String>.broadcast();
  final _hostSeen = StreamController<SyncHost>.broadcast();
  final _hostLost = StreamController<String>.broadcast();
  final _messages = StreamController<SyncMessage>.broadcast();

  String? hostingName;
  String? name;
  final clients = <String>{};
  String? connectedHost;
  bool scanning = false;

  /// Whether the device takes connections, false while it is "away".
  bool reachable = true;

  /// Whether the app on the device is running, false while it is "frozen":
  /// nothing is sent and nothing received is handled.
  bool running = true;

  /// Whether what the device sends gets lost, as on a link about to drop.
  bool losing = false;

  /// Whether sending fails, as the radio reports when it is busy.
  bool failing = false;

  /// Whether the radio refuses to search, as it does now and then.
  bool scanFailing = false;

  /// Whether the radio leaves requests unanswered, as with Bluetooth turned
  /// off: ending links, stopping and sending never complete.
  bool stuck = false;

  Future<void> _hang() => Completer<void>().future;

  /// Holds connecting until completed, as a slow radio does.
  Completer<void>? connecting;

  /// Every message sent, decoded, with its receiver.
  final sent = <(String, Map<String, dynamic>)>[];

  void setState(BluetoothState state) {
    _state = state;
    _stateChanged.add(state);
  }

  @override
  BluetoothState get state => _state;
  @override
  Stream<BluetoothState> get stateChanged => _stateChanged.stream;
  @override
  Future<bool> authorize() async => true;
  @override
  Future<void> showAppSettings() async {}
  @override
  Future<bool> scanNeedsLocation() async => false;
  @override
  Future<void> openLocationSettings() async {}
  @override
  Future<String?> deviceName() async => name;
  @override
  Stream<String> get peerJoined => _peerJoined.stream;
  @override
  Stream<String> get peerLeft => _peerLeft.stream;
  @override
  Stream<SyncHost> get hostSeen => _hostSeen.stream;
  @override
  Stream<String> get hostLost => _hostLost.stream;
  @override
  Stream<SyncMessage> get messages => _messages.stream;

  @override
  Future<void> startHosting(String name) async {
    hostingName = name;
    network.hosting[id] = this;
    network.advertise();
  }

  @override
  Future<void> stopHosting() async {
    if (stuck) return _hang();
    hostingName = null;
    network.hosting.remove(id);
    for (final client in clients.toList()) {
      network.transports[client]?._hostGone(id);
    }
    clients.clear();
  }

  @override
  Future<void> disconnectPeer(String peer) async {
    if (clients.remove(peer)) _peerLeft.add(peer);
    network.transports[peer]?._hostGone(id);
  }

  void _hostGone(String host) {
    if (connectedHost != host) return;
    connectedHost = null;
    _hostLost.add(host);
  }

  void _clientGone(String client) {
    if (clients.remove(client)) _peerLeft.add(client);
  }

  @override
  Future<void> startScan() async {
    if (scanFailing) throw StateError('scan failed');
    scanning = true;
    _seeHosts();
  }

  void _seeHosts() {
    if (!scanning) return;
    for (final host in network.hosting.values) {
      if (host.id == id) continue;
      _hostSeen.add(SyncHost(id: host.id, name: host.hostingName!, rssi: -50));
    }
  }

  @override
  Future<void> stopScan() async {
    if (stuck) return _hang();
    scanning = false;
  }

  @override
  Future<void> connect(String host) async {
    await connecting?.future;
    final target = network.hosting[host];
    if (!running) throw StateError('frozen');
    if (target == null || !target.reachable) throw StateError('no host');
    connectedHost = host;
    target.clients.add(id);
    target._peerJoined.add(id);
  }

  @override
  Future<void> disconnect(String host) async {
    if (stuck) return _hang();
    if (connectedHost != host) return;
    connectedHost = null;
    network.transports[host]?._clientGone(id);
  }

  /// Hands [message] to the session as if [from] had sent it, whether or
  /// not it is linked.
  void deliver(String from, Map<String, dynamic> message) {
    _messages.add((peer: from, data: utf8.encode(jsonEncode(message))));
  }

  @override
  Future<void> send(String peer, Uint8List data) async {
    if (stuck) return _hang();
    if (failing) throw StateError('send failed');
    if (!running || losing) return;
    final linked = clients.contains(peer) || connectedHost == peer;
    final target = network.transports[peer];
    if (!linked || target == null) return;
    sent.add((peer, jsonDecode(utf8.decode(data)) as Map<String, dynamic>));
    scheduleMicrotask(() {
      if (target.running) target._messages.add((peer: id, data: data));
    });
  }
}

class FakeBoards implements SyncBoards {
  @override
  BoardState? current;

  /// The session, told when another board opened, as the real boards do.
  SyncSession? session;

  /// The profile another board opens in, else the one of the state.
  String? profile;

  final shown = <BoardState>[];

  /// The boards stored here, as they open.
  final stored = <Board, BoardState>{};

  @override
  Future<void> show(BoardState state) async {
    final opened = current?.board != state.board;
    shown.add(state);
    current = state;
    if (!opened) return;
    final loaded = BoardState(
      state.board,
      state.data,
      state.settings,
      profile: profile ?? state.profile,
    );
    current = loaded;
    session?.boardLoaded(loaded);
  }

  @override
  Future<void> open(Board board) async {
    final opened =
        stored[board] ??
        BoardState(board, const {}, const {}, profile: profile ?? '');
    current = opened;
    session?.boardLoaded(opened);
  }
}

/// A device: its radio, its boards and its session.
class Device {
  Device(String id, FakeNetwork network)
    : transport = FakeTransport(id, network),
      boards = FakeBoards() {
    session = SyncSession(transport, boards, history);
    boards.session = session;
    session.events.listen(events.add);
  }

  final FakeTransport transport;
  final FakeBoards boards;
  final history = FakeHistory();
  late final SyncSession session;
  final events = <SyncEvent>[];
}

/// A history in memory, taking games as the database does.
class FakeHistory implements SyncHistory {
  final games = <String, GameRow>{};
  final deleted = <String>{};

  /// Every message of games taken in, by the number of games in it.
  final batches = <int>[];

  @override
  Future<Map<String, int>> revisions() async => {
    for (final MapEntry(:key, :value) in games.entries)
      key: SyncHistory.revisionOf(value),
    for (final id in deleted) id: SyncHistory.deleted,
  };

  @override
  Future<List<GameRow>> rows(Iterable<String> ids) async => [
    for (final id in ids) ?games[id],
  ];

  @override
  Future<void> take(List<GameRow> rows) async {
    batches.add(rows.length);
    for (final row in rows) {
      final id = row['id'] as String;
      if (deleted.contains(id)) continue;
      final kept = games[id];
      if (kept == null ||
          SyncHistory.revisionOf(kept) < SyncHistory.revisionOf(row)) {
        games[id] = row;
      }
    }
  }
}
