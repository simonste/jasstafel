import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/sync/merge.dart';
import 'package:jasstafel/common/sync/sync_transport.dart';

/// The version of the messages exchanged. Raised when their format changes,
/// so that apps of different versions don't corrupt each other's boards.
const protocolVersion = 1;

/// The role the local device plays in a sync session.
enum SyncRole { idle, host, client }

/// Something that happened to a session without the player asking for it.
enum SyncEvent {
  /// The host ended the session.
  ended,

  /// The connection to the host was lost and couldn't be restored.
  connectionLost,

  /// A device left the hosted session.
  deviceLeft,

  /// The other device runs an app version with other messages.
  versionMismatch,

  /// The connection to the host was lost, it is being restored.
  reconnecting,

  /// The connection to the host is restored.
  reconnected,

  /// Bluetooth was turned off, which ended the session.
  bluetoothOff,

  /// The host has as many devices as it takes, see [SyncSession.maxClients].
  full,
}

/// Immutable snapshot of the sync state, exposed for the UI.
class SyncStatus {
  final SyncRole role;
  final int connectedPeers;

  /// The name of the hosted or joined session: the host's Bluetooth name,
  /// or e.g. "Jasstafel K7".
  final String? sessionName;

  const SyncStatus({
    this.role = SyncRole.idle,
    this.connectedPeers = 0,
    this.sessionName,
  });

  bool get active => role != SyncRole.idle;

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.role == role &&
      other.connectedPeers == connectedPeers &&
      other.sessionName == sessionName;

  @override
  int get hashCode => Object.hash(role, connectedPeers, sessionName);
}

/// The state of a board as it is synced: its score, its shared settings and
/// the name of the host's profile it is in.
class BoardState {
  final Board board;
  final Map<String, dynamic> data;
  final Map<String, dynamic> settings;
  final String profile;

  const BoardState(this.board, this.data, this.settings, {this.profile = ''});

  factory BoardState.fromJson(Map<String, dynamic> json) => BoardState(
    Board.values.byName(json['board'] as String),
    json['data'] as Map<String, dynamic>,
    (json['settings'] as Map<String, dynamic>?) ?? {},
    profile: json['profile'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'board': board.name,
    'data': data,
    'settings': settings,
    'profile': profile,
  };

  /// Keeps the changes of both [ours] and [theirs], made from this state.
  BoardState merge(BoardState ours, BoardState theirs) => BoardState(
    theirs.board,
    mergeJson(data, ours.data, theirs.data) as Map<String, dynamic>,
    mergeJson(settings, ours.settings, theirs.settings, counters: false)
        as Map<String, dynamic>,
    profile: ours.profile,
  );

  @override
  bool operator ==(Object other) =>
      other is BoardState &&
      other.board == board &&
      other.profile == profile &&
      const DeepCollectionEquality().equals(other.data, data) &&
      const DeepCollectionEquality().equals(other.settings, settings);

  @override
  int get hashCode => board.hashCode;
}

/// The boards as the session sees them: the one on screen, and a way to
/// show a state that arrived.
abstract class SyncBoards {
  /// The state of the board on screen, or null while none is.
  BoardState? get current;

  /// Shows [state]: updates the board on screen if it is that board, or
  /// stores it and opens its board. The session set [SyncSession.switchingTo]
  /// then, and expects [SyncSession.boardLoaded] once the board is open.
  Future<void> show(BoardState state);
}

/// A session name with a short code to tell sessions apart, avoiding
/// characters that are easily confused. For a host without a known
/// Bluetooth name.
String _newSessionName() {
  // cspell:disable-next-line
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random();
  final code = List.generate(2, (_) => chars[random.nextInt(chars.length)]);
  return 'Jasstafel ${code.join()}';
}

/// A random id for a client, see [SyncSession._clientId].
String _newClientId() {
  final random = Random();
  return List.generate(8, (_) => random.nextInt(36).toRadixString(36)).join();
}

/// A sync session between devices, over a [SyncTransport].
///
/// One device hosts, the others join. Board state is exchanged as JSON, so
/// every change propagates to all connected devices.
///
/// The host keeps the state of the session: it numbers every state it sends,
/// and a client tells which state its change was made from. If changes of two
/// devices cross, the host merges them (see [mergeJson]) and sends the result
/// to everyone, so no entry is lost.
///
/// The session follows the board that is open: switching the board on any
/// device switches it on all of them.
///
/// Time is counted in ticks of its own timers rather than read from the
/// clock, so the session runs under `fakeAsync` in tests.
class SyncSession {
  SyncSession(this._transport, this._boards) {
    _listen();
  }

  final SyncTransport _transport;
  final SyncBoards _boards;

  /// How often host and clients tell each other they are still there. A link
  /// outlives the app on the other side, so it doesn't tell.
  static const pingInterval = Duration(seconds: 5);

  /// How many pings the other side may miss before it is taken for gone.
  static const silenceTicks = 3;

  /// How long a client keeps trying to get back to a host it lost, as when
  /// the host walks out of range for a while.
  static const reconnectTimeout = Duration(minutes: 2);
  static const reconnectPause = Duration(seconds: 3);

  /// How long a host stays in the join list without being seen.
  static const staleAfter = Duration(seconds: 5);

  /// How long a client waits for the host to take in its change, before it
  /// takes the host's state anyway.
  static const ackTimeout = Duration(seconds: 5);

  /// How long changes are collected before they are sent.
  static const debounce = Duration(milliseconds: 150);

  /// How many devices may join a hosted session. Bluetooth takes only a few
  /// links at once, and every change goes to each device in turn.
  static const maxClients = 6;

  /// How many states the host keeps to merge changes made from them.
  static const historySize = 32;

  /// How long ending the session may wait for the radio, for each step.
  static const cleanupTimeout = Duration(seconds: 3);

  final status = ValueNotifier<SyncStatus>(const SyncStatus());
  final _events = StreamController<SyncEvent>.broadcast();

  /// What happened to the session without the player asking for it.
  Stream<SyncEvent> get events => _events.stream;

  /// The hosts found while searching, for the join list.
  final hosts = ValueNotifier<List<SyncHost>>([]);
  final _hostAge = <String, int>{};
  Timer? _pruneTimer;

  SyncRole _role = SyncRole.idle;
  String? _sessionName;
  bool _stopping = false;

  /// Ending the links of a session that ended, until done.
  Future<void>? _cleanup;

  /// Counts the sessions ended, for a connection that completes after its
  /// session ended to tell.
  int _ended = 0;
  Timer? _heartbeat;

  // Host state.
  final _peers = <String>{};
  final _silence = <String, int>{};

  /// The states sent by number, the latest being [_version].
  final _history = <int, BoardState>{};
  int _version = 0;

  /// The latest change of each client taken in, by its number.
  final _acks = <String, int>{};

  /// The latest change of each client and the state it was made from.
  final _lastChanges = <String, (int, BoardState)>{};

  /// The latest change taken in by client id. Unlike [_acks] it outlives a
  /// reconnect, so a change sent again isn't merged twice.
  final _applied = <String, int>{};

  // Client state.
  String? _hostId;
  bool _connected = false;
  int _hostSilence = 0;
  bool _reconnecting = false;
  bool _giveUp = false;
  Timer? _reconnectDeadline;

  /// The number of the host's state the board was last updated to.
  int _baseVersion = 0;

  /// Whether a state of the host arrived since joining. The first one is
  /// shown even if the board here looks the same, for the player to choose
  /// the profile to show it in.
  bool _joined = false;

  /// Tells this client's changes apart from those of other clients, also
  /// after a reconnect, when the host knows the client by a new peer.
  String _clientId = '';

  /// The number of the latest change sent to the host.
  int _sentChanges = 0;

  /// The latest change sent, with the state it was made from, until the
  /// host sends a state again. Sent again after a reconnect, as it may not
  /// have reached the host.
  ({int base, int change, BoardState state})? _unacked;

  /// Runs while the host hasn't taken in the latest change yet.
  Timer? _ackTimer;

  /// The state the other devices are known to have, or to get soon.
  BoardState? _known;

  /// The board another device switched to, until it is loaded here. It isn't
  /// sent back then.
  Board? _switchingTo;

  /// The board to switch to, as another device did.
  Board? get switchingTo => _switchingTo;

  // Outgoing coalescing.
  Timer? _debounce;
  BoardState? _pending;

  final _subscriptions = <StreamSubscription<void>>[];

  bool get isActive => _role != SyncRole.idle;

  BluetoothState get bluetoothState => _transport.state;
  Stream<BluetoothState> get bluetoothStateChanged => _transport.stateChanged;
  Future<bool> authorize() => _transport.authorize();
  Future<void> showAppSettings() => _transport.showAppSettings();
  Future<bool> scanNeedsLocation() => _transport.scanNeedsLocation();
  Future<void> openLocationSettings() => _transport.openLocationSettings();

  /// [message] as sent, with the protocol version.
  static Uint8List _encode(Map<String, dynamic> message) =>
      utf8.encode(jsonEncode({'proto': protocolVersion, ...message}));

  static final _ping = _encode({'ping': true});

  void _listen() {
    _subscriptions.addAll([
      // Bluetooth turned off ends the session, there is no radio left to
      // serve it.
      _transport.stateChanged.listen((state) {
        if (!isActive || _stopping) return;
        if (state == BluetoothState.on) return;
        stop();
        _events.add(SyncEvent.bluetoothOff);
      }),
      _transport.hostSeen.listen((host) {
        if (_role != SyncRole.client) return;
        _hostAge[host.id] = 0;
        final list = [...hosts.value];
        final index = list.indexWhere((h) => h.id == host.id);
        if (index >= 0) {
          list[index] = host;
        } else {
          list.add(host);
        }
        hosts.value = list;
      }),
      _transport.peerJoined.listen((peer) {
        if (_role != SyncRole.host) return;
        if (_peers.length >= maxClients && !_peers.contains(peer)) {
          _refuse(peer);
          return;
        }
        _peers.add(peer);
        _silence[peer] = 0;
        _sendSnapshotTo(peer);
        _publishStatus();
      }),
      _transport.peerLeft.listen((peer) {
        _removePeer(peer);
        _publishStatus();
      }),
      _transport.hostLost.listen((host) {
        if (_role != SyncRole.client || _stopping || host != _hostId) return;
        _connected = false;
        _publishStatus();
        _reconnect();
      }),
      _transport.messages.listen((message) {
        if (_role == SyncRole.host) {
          _onMessageFromPeer(message.peer, message.data);
        } else if (_role == SyncRole.client && message.peer == _hostId) {
          _onMessageFromHost(message.data);
        }
      }),
    ]);
  }

  /// Releases the timers and subscriptions, for tests.
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _cancelTimers();
    _pruneTimer?.cancel();
    _events.close();
  }

  void _cancelTimers() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _debounce?.cancel();
    _debounce = null;
    _ackTimer?.cancel();
    _ackTimer = null;
    _reconnectDeadline?.cancel();
    _reconnectDeadline = null;
  }

  /// Tells [peer] the session is full, then ends its link.
  Future<void> _refuse(String peer) async {
    try {
      await _transport
          .send(peer, _encode({'full': true}))
          .timeout(cleanupTimeout);
    } catch (_) {}
    try {
      await _transport.disconnectPeer(peer).timeout(cleanupTimeout);
    } catch (_) {}
  }

  void _removePeer(String peer) {
    _silence.remove(peer);
    _acks.remove(peer);
    _lastChanges.remove(peer);
    final left = _peers.remove(peer);
    // Not for the devices disconnected by ending the session.
    if (left && _role == SyncRole.host && !_stopping) {
      _events.add(SyncEvent.deviceLeft);
    }
  }

  /// Starts hosting a session.
  Future<void> startHost() async {
    await stop();
    await _transport.authorize();
    final deviceName = (await _transport.deviceName())?.trim() ?? '';
    final name = deviceName.isEmpty ? _newSessionName() : deviceName;
    await _transport.startHosting(name);
    _role = SyncRole.host;
    _sessionName = name;
    _startHeartbeat();
    _publishStatus();
  }

  /// Starts searching for a host to join.
  Future<void> startDiscovery() async {
    await stop();
    await _transport.authorize();
    hosts.value = [];
    _role = SyncRole.client;
    _publishStatus();
    await _startScan();
  }

  Future<void> _startScan() async {
    _pruneTimer?.cancel();
    _pruneTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _hostAge.updateAll((_, age) => age + 1);
      final list = hosts.value
          .where((h) => (_hostAge[h.id] ?? 0) < staleAfter.inSeconds)
          .toList();
      if (list.length != hosts.value.length) hosts.value = list;
    });
    await _transport.startScan();
  }

  Future<void> _stopScan() async {
    _pruneTimer?.cancel();
    _pruneTimer = null;
    await _transport.stopScan();
  }

  /// Connects to a host found while searching. Returns false if connecting
  /// failed, the search is resumed then.
  Future<bool> connectToHost(String host) async {
    await _stopScan();
    _sessionName = hosts.value.firstWhereOrNull((h) => h.id == host)?.name;
    _hostId = host;
    _clientId = _newClientId();
    _baseVersion = 0;
    _joined = false;
    _sentChanges = 0;
    _unacked = null;
    _known = null;
    final session = _ended;
    try {
      await _transport.connect(host);
    } catch (_) {
      if (_role == SyncRole.client) await _startScan();
      return false;
    }
    if (_endedSince(session, host)) return false;
    _onConnected();
    return true;
  }

  /// Whether the session ended since [session], while connecting to [host].
  /// The link that came up after is ended, nothing is left to use it.
  bool _endedSince(int session, String host) {
    if (session == _ended) return false;
    _transport.disconnect(host).timeout(cleanupTimeout).catchError((_) {});
    return true;
  }

  void _onConnected() {
    _connected = true;
    _hostSilence = 0;
    _startHeartbeat();
    // The host sends the session board once subscribed.
    _publishStatus();
  }

  /// Connects again after the connection to the host was lost, trying for
  /// [reconnectTimeout] before giving the session up.
  Future<void> _reconnect() async {
    final host = _hostId;
    if (_reconnecting || host == null) return;
    _reconnecting = true;
    _giveUp = false;
    _reconnectDeadline = Timer(reconnectTimeout, () => _giveUp = true);
    _events.add(SyncEvent.reconnecting);
    try {
      final session = _ended;
      while (_role == SyncRole.client && !_stopping && !_giveUp) {
        try {
          await _transport.connect(host);
          if (_endedSince(session, host)) return;
          _onConnected();
          _resendChange();
          _events.add(SyncEvent.reconnected);
          return;
        } catch (_) {}
        await Future.delayed(reconnectPause);
      }
    } finally {
      _reconnecting = false;
      _reconnectDeadline?.cancel();
      _reconnectDeadline = null;
    }
    if (_role != SyncRole.client || _stopping) return;
    await stop();
    _events.add(SyncEvent.connectionLost);
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(pingInterval, (_) {
      if (_role == SyncRole.host) {
        for (final peer in _peers.toList()) {
          final silence = (_silence[peer] ?? 0) + 1;
          _silence[peer] = silence;
          if (silence > silenceTicks) {
            _removePeer(peer);
            _publishStatus();
            _transport.disconnectPeer(peer).catchError((_) {});
          } else {
            _transport.send(peer, _ping).catchError((_) {});
          }
        }
      } else if (_role == SyncRole.client && _connected) {
        final host = _hostId!;
        if (++_hostSilence > silenceTicks) {
          _connected = false;
          _publishStatus();
          _transport.disconnect(host).catchError((_) {});
          _reconnect();
        } else {
          _transport.send(host, _ping).catchError((_) {});
        }
      }
    });
  }

  /// Ends the session, whatever the role.
  ///
  /// The session ends at once; ending the links follows. Each step of that
  /// may take [cleanupTimeout] at most: with Bluetooth turned off, or a link
  /// that died unnoticed, the radio may never answer, and the session would
  /// go on as if connected.
  Future<void> stop() async {
    final cleanup = _cleanup;
    if (cleanup != null) await cleanup;
    if (_role == SyncRole.idle) return;
    final role = _role;
    final host = _hostId;
    final connected = _connected;
    final peers = _peers.toList();

    _ended++;
    _stopping = true;
    _giveUp = true;
    _cancelTimers();
    _pending = null;
    _peers.clear();
    _silence.clear();
    _history.clear();
    _version = 0;
    _acks.clear();
    _lastChanges.clear();
    _applied.clear();
    _hostId = null;
    _unacked = null;
    _connected = false;
    _hostSilence = 0;
    _known = null;
    _role = SyncRole.idle;
    _sessionName = null;
    _switchingTo = null;
    _publishStatus();

    Future<void> step(Future<void> Function() action) async {
      try {
        await action().timeout(cleanupTimeout);
      } catch (_) {}
    }

    final done = _cleanup = () async {
      if (role == SyncRole.host) {
        // Tell the clients to leave, the host can't reliably end the links.
        final end = _encode({'end': true});
        for (final peer in peers) {
          await step(() => _transport.send(peer, end));
        }
        await step(_transport.stopHosting);
      } else {
        await step(_stopScan);
        if (host != null && connected) {
          await step(() => _transport.disconnect(host));
        }
      }
    }();
    try {
      await done;
    } finally {
      _cleanup = null;
      _stopping = false;
      _giveUp = false;
    }
  }

  /// Queues [state] of the open board to be sent to the other devices.
  void broadcast(BoardState state) {
    if (!isActive) return;
    // The latest change wins over a switch of another device not done yet.
    _switchingTo = null;
    _pending = state;
    _debounce?.cancel();
    _debounce = Timer(debounce, () {
      final state = _pending;
      _pending = null;
      if (state == null) return;
      if (_role == SyncRole.host) {
        _commit(state);
      } else {
        _sendChange(state);
      }
    });
  }

  /// Shares changes of the open board that weren't saved through it, such
  /// as its settings. Not while switching to another device's board, which
  /// would switch them back, nor before a joined host sent its board, which
  /// would replace the host's.
  void shareChanges() {
    final current = _boards.current;
    if (!isActive || current == null || _pending != null) return;
    if (_switchingTo != null || _known == null) return;
    if (current != _known) broadcast(current);
  }

  /// Shares a board that just loaded, so the other devices switch to it.
  /// Not when it is the board another device switched to, unless it opened
  /// in another profile on the host, which names the profiles.
  void boardLoaded(BoardState state) {
    if (_switchingTo == state.board) {
      _switchingTo = null;
      if (_role != SyncRole.host || state.profile == _known?.profile) return;
    }
    broadcast(state);
  }

  /// Sends a change to the host, telling the state it was made from.
  void _sendChange(BoardState state) {
    if (_hostId == null) return;
    _known = state;
    _unacked = (base: _baseVersion, change: ++_sentChanges, state: state);
    _resendChange();
  }

  /// Sends [_unacked], if there is one, and waits for the host to take it
  /// in.
  void _resendChange() {
    final host = _hostId;
    final change = _unacked;
    if (host == null || change == null) return;
    _ackTimer?.cancel();
    _ackTimer = Timer(ackTimeout, () => _ackTimer = null);
    _transport
        .send(
          host,
          _encode({
            ...change.state.toJson(),
            'base': change.base,
            'change': change.change,
            'client': _clientId,
          }),
        )
        .catchError((_) {});
  }

  /// Makes [state] the session's latest and sends it to all clients.
  void _commit(BoardState state) {
    _known = state;
    _history[++_version] = state;
    _history.remove(_version - historySize);
    for (final peer in _peers.toList()) {
      _sendStateTo(peer);
    }
  }

  void _sendStateTo(String peer) {
    final state = _history[_version];
    if (state == null) return;
    _transport
        .send(
          peer,
          _encode({
            ...state.toJson(),
            'version': _version,
            'ack': _acks[peer] ?? 0,
          }),
        )
        .catchError((_) {});
  }

  void _sendSnapshotTo(String peer) {
    final current = _boards.current;
    if (current != null) {
      _known = current;
      _history[++_version] = current;
      _history.remove(_version - historySize);
    }
    _sendStateTo(peer);
  }

  /// The latest state of [board] here.
  BoardState? _latest(Board board) {
    final current = _boards.current;
    if (current != null && current.board == board) return current;
    for (var version = _version; _history.containsKey(version); version--) {
      if (_history[version]!.board == board) return _history[version];
    }
    return null;
  }

  void _onMessageFromPeer(String peer, Uint8List message) {
    final Map<String, dynamic> json;
    final BoardState theirs;
    _silence[peer] = 0;
    try {
      json = jsonDecode(utf8.decode(message)) as Map<String, dynamic>;
      if (json['proto'] != protocolVersion) {
        // Its app can't take part, drop it rather than its board.
        _removePeer(peer);
        _publishStatus();
        _transport.disconnectPeer(peer).catchError((_) {});
        _events.add(SyncEvent.versionMismatch);
        return;
      }
      if (json['ping'] == true) return;
      theirs = BoardState.fromJson(json);
    } catch (_) {
      return;
    }
    final base = json['base'] as int? ?? 0;
    final change = json['change'] as int? ?? 0;
    final client = json['client'] as String? ?? peer;
    _acks[peer] = change;
    if (change <= (_applied[client] ?? 0)) {
      // Sent again after a reconnect, but it was taken in before.
      _sendStateTo(peer);
      return;
    }
    _applied[client] = change;

    // A client sending again before getting the state with its last change
    // made this change from its last one, which is merged already.
    final last = _lastChanges[peer];
    final baseState = last != null && last.$1 == base
        ? last.$2
        : _history[base];
    _lastChanges[peer] = (base, theirs);

    var state = theirs;
    final ours = _latest(theirs.board);
    if (baseState != null && ours != null && baseState.board == theirs.board) {
      state = baseState.merge(ours, theirs);
    } else if (ours != null) {
      // The host's profile, the client's may have another name.
      state = BoardState(
        state.board,
        state.data,
        state.settings,
        profile: ours.profile,
      );
    }
    // A change of the host not sent yet is in the merged state.
    _debounce?.cancel();
    _debounce = null;
    _pending = null;
    _commit(state);
    _show(state);
  }

  void _onMessageFromHost(Uint8List message) {
    final Map<String, dynamic> json;
    final BoardState state;
    _hostSilence = 0;
    try {
      json = jsonDecode(utf8.decode(message)) as Map<String, dynamic>;
      if (json['proto'] != protocolVersion) {
        stop();
        _events.add(SyncEvent.versionMismatch);
        return;
      }
      if (json['ping'] == true) return;
      if (json['end'] == true) {
        stop();
        _events.add(SyncEvent.ended);
        return;
      }
      if (json['full'] == true) {
        stop();
        _events.add(SyncEvent.full);
        return;
      }
      state = BoardState.fromJson(json);
    } catch (_) {
      return;
    }
    // A change not taken in by the host yet would be overwritten, it sends a
    // state with it soon.
    if (_pending != null) return;
    final ack = json['ack'] as int? ?? 0;
    if (ack < _sentChanges && _ackTimer != null) return;
    _ackTimer?.cancel();
    _ackTimer = null;
    // Taken in, or given up on after [ackTimeout].
    _unacked = null;
    _baseVersion = json['version'] as int? ?? 0;
    _known = state;
    final first = !_joined;
    _joined = true;
    _show(state, always: first);
  }

  /// Shows [state] here, switching the board if it is another one. Unless
  /// [always], not if the board here is the same already.
  Future<void> _show(BoardState state, {bool always = false}) async {
    final current = _boards.current;
    if (current != null && current.board == state.board) {
      if (state == current && !always) return;
    } else {
      _switchingTo = state.board;
    }
    await _boards.show(state);
  }

  void _publishStatus() {
    final peers = _role == SyncRole.host ? _peers.length : (_connected ? 1 : 0);
    status.value = SyncStatus(
      role: _role,
      connectedPeers: peers,
      sessionName: _sessionName,
    );
  }
}
