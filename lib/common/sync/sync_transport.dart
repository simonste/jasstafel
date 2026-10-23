import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// The state of the Bluetooth radio, as far as the sync needs to know it.
/// [unknown] until the radio first tells, as while iOS asks for the
/// permission.
enum BluetoothState { unknown, unsupported, unauthorized, off, on }

/// The most bytes of a session name an advertisement holds: of its 31
/// bytes, 3 are for the flags, 4 for the manufacturer data header and id and
/// 4 for the magic bytes.
const maxSessionNameBytes = 20;

/// [name] as it is advertised: cut to [maxSessionNameBytes] UTF-8 bytes
/// without splitting characters.
String truncateSessionName(String name) {
  final buffer = StringBuffer();
  var length = 0;
  for (final rune in name.runes) {
    length += utf8.encode(String.fromCharCode(rune)).length;
    if (length > maxSessionNameBytes) break;
    buffer.writeCharCode(rune);
  }
  return buffer.toString();
}

/// A host found while searching for a shared board.
class SyncHost {
  final String id;
  final String name;

  /// The signal strength in dBm, stronger is nearer.
  final int rssi;

  const SyncHost({required this.id, required this.name, required this.rssi});
}

typedef SyncMessage = ({String peer, Uint8List data});

/// The radio as the sync session sees it: peers known by an id, whole
/// messages, no Bluetooth types. [BleSyncTransport] is the real one,
/// tests use a fake.
abstract class SyncTransport {
  BluetoothState get state;
  Stream<BluetoothState> get stateChanged;

  /// Asks for the runtime permissions, returns whether they were granted.
  Future<bool> authorize();
  Future<void> showAppSettings();

  /// Whether searching finds nothing because the location is turned off,
  /// as up to Android 11.
  Future<bool> scanNeedsLocation();
  Future<void> openLocationSettings();

  /// The name the device goes by in Bluetooth, or null where it isn't
  /// known.
  Future<String?> deviceName();

  /// Advertises a session named [name] and takes clients.
  Future<void> startHosting(String name);
  Future<void> stopHosting();

  /// A client that subscribed to the hosted session.
  Stream<String> get peerJoined;

  /// A client that unsubscribed or whose link ended.
  Stream<String> get peerLeft;
  Future<void> disconnectPeer(String peer);

  Future<void> startScan();
  Future<void> stopScan();

  /// Every advertisement of a host seen while scanning.
  Stream<SyncHost> get hostSeen;

  /// Connects to [host] and subscribes to its messages. Throws when it
  /// fails.
  Future<void> connect(String host);
  Future<void> disconnect(String host);

  /// The host whose link ended.
  Stream<String> get hostLost;

  Stream<SyncMessage> get messages;

  /// Sends [data] to [peer], a client of the hosted session or the host
  /// connected to. Completes once sent.
  Future<void> send(String peer, Uint8List data);
}

/// The transport where there is no Bluetooth: on the web, on Linux, and in
/// widget tests. Everything is a no-op.
class UnsupportedSyncTransport implements SyncTransport {
  const UnsupportedSyncTransport();

  @override
  BluetoothState get state => BluetoothState.unsupported;
  @override
  Stream<BluetoothState> get stateChanged => const Stream.empty();
  @override
  Future<bool> authorize() async => false;
  @override
  Future<void> showAppSettings() async {}
  @override
  Future<bool> scanNeedsLocation() async => false;
  @override
  Future<void> openLocationSettings() async {}
  @override
  Future<String?> deviceName() async => null;
  @override
  Future<void> startHosting(String name) async {}
  @override
  Future<void> stopHosting() async {}
  @override
  Stream<String> get peerJoined => const Stream.empty();
  @override
  Stream<String> get peerLeft => const Stream.empty();
  @override
  Future<void> disconnectPeer(String peer) async {}
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Stream<SyncHost> get hostSeen => const Stream.empty();
  @override
  Future<void> connect(String host) async => throw StateError('no Bluetooth');
  @override
  Future<void> disconnect(String host) async {}
  @override
  Stream<String> get hostLost => const Stream.empty();
  @override
  Stream<SyncMessage> get messages => const Stream.empty();
  @override
  Future<void> send(String peer, Uint8List data) async {}
}

/// Creates the transport only once the sync is used: on iOS, the radio asks
/// for the Bluetooth permission as soon as it is set up, and warns when
/// Bluetooth is off. Most players never sync, they aren't to be asked.
///
/// Reading [state] or calling a method sets the radio up, listening to the
/// streams doesn't. Where creating it throws [UnimplementedError], as in
/// widget tests without the plugin, there is no Bluetooth.
class LazySyncTransport implements SyncTransport {
  LazySyncTransport(this._create);

  final SyncTransport Function() _create;
  SyncTransport? _transport;

  final _stateChanged = StreamController<BluetoothState>.broadcast();
  final _peerJoined = StreamController<String>.broadcast();
  final _peerLeft = StreamController<String>.broadcast();
  final _hostSeen = StreamController<SyncHost>.broadcast();
  final _hostLost = StreamController<String>.broadcast();
  final _messages = StreamController<SyncMessage>.broadcast();

  /// Whether the radio is set up.
  bool get created => _transport != null;

  SyncTransport get _radio {
    final existing = _transport;
    if (existing != null) return existing;
    SyncTransport transport;
    try {
      transport = _create();
    } on UnimplementedError {
      transport = const UnsupportedSyncTransport();
    }
    _transport = transport;
    transport.stateChanged.listen(_stateChanged.add);
    transport.peerJoined.listen(_peerJoined.add);
    transport.peerLeft.listen(_peerLeft.add);
    transport.hostSeen.listen(_hostSeen.add);
    transport.hostLost.listen(_hostLost.add);
    transport.messages.listen(_messages.add);
    return transport;
  }

  @override
  BluetoothState get state => _radio.state;
  @override
  Stream<BluetoothState> get stateChanged => _stateChanged.stream;
  @override
  Future<bool> authorize() => _radio.authorize();
  @override
  Future<void> showAppSettings() => _radio.showAppSettings();
  @override
  Future<bool> scanNeedsLocation() => _radio.scanNeedsLocation();
  @override
  Future<void> openLocationSettings() => _radio.openLocationSettings();
  @override
  Future<String?> deviceName() => _radio.deviceName();
  @override
  Future<void> startHosting(String name) => _radio.startHosting(name);
  @override
  Future<void> stopHosting() => _radio.stopHosting();
  @override
  Stream<String> get peerJoined => _peerJoined.stream;
  @override
  Stream<String> get peerLeft => _peerLeft.stream;
  @override
  Future<void> disconnectPeer(String peer) => _radio.disconnectPeer(peer);
  @override
  Future<void> startScan() => _radio.startScan();
  @override
  Future<void> stopScan() => _radio.stopScan();
  @override
  Stream<SyncHost> get hostSeen => _hostSeen.stream;
  @override
  Future<void> connect(String host) => _radio.connect(host);
  @override
  Future<void> disconnect(String host) => _radio.disconnect(host);
  @override
  Stream<String> get hostLost => _hostLost.stream;
  @override
  Stream<SyncMessage> get messages => _messages.stream;
  @override
  Future<void> send(String peer, Uint8List data) => _radio.send(peer, data);
}
