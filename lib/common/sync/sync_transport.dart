import 'dart:async';
import 'dart:typed_data';

/// The state of the Bluetooth radio, as far as the sync needs to know it.
enum BluetoothState { unsupported, unauthorized, off, on }

/// A host found while searching for a shared board.
class SyncHost {
  final String id;
  final String name;

  /// The signal strength in dBm, stronger is nearer.
  final int rssi;

  const SyncHost({required this.id, required this.name, required this.rssi});
}

/// A message received from a peer.
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
