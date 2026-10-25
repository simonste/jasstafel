import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jasstafel/common/sync/sync_transport.dart';

/// UUIDs identifying the Jasstafel sync GATT service and characteristic.
final _serviceUuid = UUID.fromString('f0d1b2c3-1a2b-4c3d-8e5f-a1b2c3d4e5f6');
final _characteristicUuid = UUID.fromString(
  'f0d1b2c3-1a2b-4c3d-8e5f-a1b2c3d4e5f7',
);

/// Identifies a Jasstafel session in the manufacturer specific data, using
/// the company id reserved for testing and the bytes "JTAF". Other apps may
/// use the test id too, the magic keeps them out of the join list.
const _manufacturerId = 0xFFFF;
const _manufacturerMagic = [0x4A, 0x54, 0x41, 0x46];

/// An advertisement holds 31 bytes: 3 for the flags, 4 for the manufacturer
/// data header and id, 4 for the magic bytes, leaving 20 for the name.
const _maxNameBytes = 20;

/// The most a message may hold. A board is a few kilobytes, so anything
/// larger is a broken or hostile device, not a board.
const _maxMessageBytes = 256 * 1024;

/// How long one attempt to connect to a host may take.
const _connectTimeout = Duration(seconds: 8);

/// How long a single operation of the radio may take. With Bluetooth turned
/// off, or a link that died unnoticed, some never complete, and everything
/// sent after them would wait for good.
const _opTimeout = Duration(seconds: 5);

bool get _advertisesLocalName =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// The advertisement of a session named [name].
///
/// iOS and macOS only advertise a local name and service UUIDs. Android
/// would rename the Bluetooth adapter to the local name and Windows doesn't
/// support it, so they put the name into the manufacturer specific data,
/// which leaves no room for the 128-bit service UUID.
Advertisement _advertisement(String name) {
  if (_advertisesLocalName) {
    return Advertisement(name: name, serviceUUIDs: [_serviceUuid]);
  }
  return Advertisement(
    manufacturerSpecificData: [
      ManufacturerSpecificData(
        id: _manufacturerId,
        data: Uint8List.fromList([..._manufacturerMagic, ..._truncate(name)]),
      ),
    ],
  );
}

/// [name] UTF-8 encoded, cut to [_maxNameBytes] without splitting characters.
List<int> _truncate(String name) {
  final bytes = <int>[];
  for (final rune in name.runes) {
    final encoded = utf8.encode(String.fromCharCode(rune));
    if (bytes.length + encoded.length > _maxNameBytes) break;
    bytes.addAll(encoded);
  }
  return bytes;
}

/// The name of the session [advertisement] belongs to, or null if it isn't a
/// Jasstafel session.
String? _sessionName(Advertisement advertisement) {
  for (final data in advertisement.manufacturerSpecificData) {
    if (data.id == _manufacturerId &&
        data.data.length >= _manufacturerMagic.length &&
        const ListEquality<int>().equals(
          data.data.sublist(0, _manufacturerMagic.length),
          _manufacturerMagic,
        )) {
      return utf8.decode(
        data.data.sublist(_manufacturerMagic.length),
        allowMalformed: true,
      );
    }
  }
  if (advertisement.serviceUUIDs.contains(_serviceUuid)) {
    return advertisement.name ?? '';
  }
  return null;
}

/// Reassembles length-prefixed messages from a stream of BLE chunks. A
/// message announced longer than [_maxMessageBytes] is dropped, and what
/// follows is read as a new message.
class _Reassembler {
  final _buffer = BytesBuilder();
  int? _expected;

  List<Uint8List> add(Uint8List data) {
    _buffer.add(data);
    var bytes = _buffer.toBytes();
    final messages = <Uint8List>[];
    while (true) {
      if (_expected == null) {
        if (bytes.length < 4) break;
        _expected = ByteData.sublistView(bytes, 0, 4).getUint32(0, Endian.big);
        bytes = bytes.sublist(4);
        if (_expected! > _maxMessageBytes) {
          _expected = null;
          bytes = Uint8List(0);
          break;
        }
      }
      if (bytes.length < _expected!) break;
      messages.add(bytes.sublist(0, _expected!));
      bytes = bytes.sublist(_expected!);
      _expected = null;
    }
    _buffer
      ..clear()
      ..add(bytes);
    return messages;
  }

  void reset() {
    _buffer.clear();
    _expected = null;
  }
}

/// Splits a payload into a length-prefixed sequence of BLE-sized chunks.
List<Uint8List> _frame(Uint8List payload, int chunkSize) {
  final size = chunkSize < 20 ? 20 : chunkSize;
  final full = Uint8List(4 + payload.length);
  ByteData.sublistView(full, 0, 4).setUint32(0, payload.length, Endian.big);
  full.setRange(4, full.length, payload);

  final chunks = <Uint8List>[];
  for (var i = 0; i < full.length; i += size) {
    final end = (i + size < full.length) ? i + size : full.length;
    chunks.add(Uint8List.sublistView(full, i, end));
  }
  return chunks;
}

/// The sync transport over Bluetooth Low Energy: the host is a peripheral
/// with one characteristic the clients write to and get notified on.
///
/// Throws [UnimplementedError] where the plugin isn't registered, as in
/// widget tests.
class BleSyncTransport implements SyncTransport {
  BleSyncTransport()
    : _peripheralManager = PeripheralManager(),
      _centralManager = CentralManager() {
    _listen();
  }

  final PeripheralManager _peripheralManager;
  final CentralManager _centralManager;

  static const _platform = MethodChannel('jasstafel/platform');

  final _stateChanged = StreamController<BluetoothState>.broadcast();
  final _peerJoined = StreamController<String>.broadcast();
  final _peerLeft = StreamController<String>.broadcast();
  final _hostSeen = StreamController<SyncHost>.broadcast();
  final _hostLost = StreamController<String>.broadcast();
  final _messages = StreamController<SyncMessage>.broadcast();

  // Host side.
  GATTCharacteristic? _characteristic;
  final _centrals = <String, Central>{};
  final _joined = <String>{};
  final _buffers = <String, _Reassembler>{};

  // Client side.
  final _peripherals = <String, Peripheral>{};
  Peripheral? _host;
  GATTCharacteristic? _hostCharacteristic;
  final _hostBuffer = _Reassembler();

  /// All sends in a row, so chunks of different messages never interleave.
  Future<void> _sendChain = Future.value();

  static BluetoothState _map(BluetoothLowEnergyState state) => switch (state) {
    BluetoothLowEnergyState.unsupported => BluetoothState.unsupported,
    BluetoothLowEnergyState.unauthorized => BluetoothState.unauthorized,
    BluetoothLowEnergyState.poweredOn => BluetoothState.on,
    _ => BluetoothState.off,
  };

  @override
  BluetoothState get state => _map(_centralManager.state);

  @override
  Stream<BluetoothState> get stateChanged => _stateChanged.stream;
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

  void _listen() {
    // Both managers report the adapter's state.
    _centralManager.stateChanged.listen(
      (event) => _stateChanged.add(_map(event.state)),
    );
    _peripheralManager.stateChanged.listen(
      (event) => _stateChanged.add(_map(event.state)),
    );

    _centralManager.discovered.listen((event) {
      final name = _sessionName(event.advertisement);
      if (name == null) return;
      final id = event.peripheral.uuid.toString();
      _peripherals[id] = event.peripheral;
      _hostSeen.add(SyncHost(id: id, name: name, rssi: event.rssi));
    });

    _peripheralManager.characteristicWriteRequested.listen((event) async {
      await _peripheralManager.respondWriteRequest(event.request);
      final id = event.central.uuid.toString();
      final buffer = _buffers.putIfAbsent(id, () => _Reassembler());
      for (final message in buffer.add(event.request.value)) {
        _messages.add((peer: id, data: message));
      }
    });

    _peripheralManager.characteristicNotifyStateChanged.listen((event) {
      final id = event.central.uuid.toString();
      if (event.state) {
        _centrals[id] = event.central;
        _joined.add(id);
        _peerJoined.add(id);
      } else {
        _left(id);
      }
    });

    // Not supported on Darwin, where a client that leaves unsubscribes, or
    // else the heartbeat drops it.
    try {
      _peripheralManager.connectionStateChanged.listen((event) {
        if (event.state == ConnectionState.disconnected) {
          _left(event.central.uuid.toString());
        }
      });
    } on UnsupportedError {
      // Nothing to listen to.
    }

    _centralManager.characteristicNotified.listen((event) {
      if (event.characteristic.uuid != _characteristicUuid) return;
      final host = _host;
      if (host == null) return;
      for (final message in _hostBuffer.add(event.value)) {
        _messages.add((peer: host.uuid.toString(), data: message));
      }
    });

    _centralManager.connectionStateChanged.listen((event) {
      final host = _host;
      if (event.state == ConnectionState.disconnected &&
          host != null &&
          event.peripheral.uuid == host.uuid) {
        _host = null;
        _hostCharacteristic = null;
        _hostBuffer.reset();
        _hostLost.add(host.uuid.toString());
      }
    });
  }

  void _left(String id) {
    _centrals.remove(id);
    _buffers.remove(id);
    if (_joined.remove(id)) _peerLeft.add(id);
  }

  @override
  Future<bool> authorize() async {
    try {
      final central = await _centralManager.authorize();
      final peripheral = await _peripheralManager.authorize();
      return central && peripheral;
    } on UnsupportedError {
      // Not required on this platform.
      return true;
    }
  }

  @override
  Future<void> showAppSettings() => _centralManager.showAppSettings();

  @override
  Future<bool> scanNeedsLocation() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _platform.invokeMethod<bool>('scanNeedsLocation') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> openLocationSettings() =>
      _platform.invokeMethod('openLocationSettings');

  /// Only Android tells apps the Bluetooth name, iOS answers "iPhone".
  @override
  Future<String?> deviceName() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _platform.invokeMethod<String>('deviceName');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> startHosting(String name) async {
    final characteristic = GATTCharacteristic.mutable(
      uuid: _characteristicUuid,
      properties: [
        GATTCharacteristicProperty.read,
        GATTCharacteristicProperty.write,
        GATTCharacteristicProperty.writeWithoutResponse,
        GATTCharacteristicProperty.notify,
      ],
      permissions: [
        GATTCharacteristicPermission.read,
        GATTCharacteristicPermission.write,
      ],
      descriptors: [],
    );
    _characteristic = characteristic;
    await _peripheralManager.removeAllServices();
    await _peripheralManager.addService(
      GATTService(
        uuid: _serviceUuid,
        isPrimary: true,
        includedServices: [],
        characteristics: [characteristic],
      ),
    );
    await _peripheralManager.startAdvertising(_advertisement(name));
  }

  @override
  Future<void> stopHosting() async {
    try {
      await _peripheralManager.stopAdvertising().timeout(_opTimeout);
      await _peripheralManager.removeAllServices().timeout(_opTimeout);
    } catch (_) {}
    // The host can't rely on the clients ending the links. Not supported
    // on Darwin.
    try {
      final centrals = await _peripheralManager
          .retrieveConnectedCentrals()
          .timeout(_opTimeout);
      for (final central in centrals) {
        await _peripheralManager.disconnect(central).timeout(_opTimeout);
      }
    } catch (_) {}
    _characteristic = null;
    _centrals.clear();
    _joined.clear();
    _buffers.clear();
  }

  @override
  Future<void> disconnectPeer(String peer) async {
    final central = _centrals[peer];
    if (central != null) {
      await _peripheralManager.disconnect(central).timeout(_opTimeout);
    }
  }

  @override
  Future<void> startScan() => _centralManager.startDiscovery();

  @override
  Future<void> stopScan() =>
      _centralManager.stopDiscovery().timeout(_opTimeout);

  @override
  Future<void> connect(String host) async {
    final peripheral = _peripherals[host];
    if (peripheral == null) throw StateError('unknown host $host');
    // Android often fails the first attempt with GATT error 133.
    for (var attempt = 1; ; attempt++) {
      try {
        await _subscribe(peripheral).timeout(_connectTimeout);
        return;
      } catch (_) {
        try {
          await _centralManager.disconnect(peripheral).timeout(_opTimeout);
        } catch (_) {}
        if (attempt == 2) rethrow;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> _subscribe(Peripheral peripheral) async {
    await _centralManager.connect(peripheral);
    try {
      await _centralManager.requestMTU(peripheral, mtu: 512);
    } on UnsupportedError {
      // MTU negotiation only matters on Android.
    }

    final services = await _centralManager.discoverGATT(peripheral);
    final service = services.firstWhere((s) => s.uuid == _serviceUuid);
    final characteristic = service.characteristics.firstWhere(
      (c) => c.uuid == _characteristicUuid,
    );

    _hostBuffer.reset();
    await _centralManager.setCharacteristicNotifyState(
      peripheral,
      characteristic,
      state: true,
    );
    // Only now, so a failed attempt isn't taken for a lost link.
    _host = peripheral;
    _hostCharacteristic = characteristic;
  }

  @override
  Future<void> disconnect(String host) async {
    final peripheral = _peripherals[host];
    if (_host?.uuid == peripheral?.uuid) {
      // Ended on purpose, not lost.
      _host = null;
      _hostCharacteristic = null;
      _hostBuffer.reset();
    }
    if (peripheral != null) {
      await _centralManager.disconnect(peripheral).timeout(_opTimeout);
    }
  }

  @override
  Future<void> send(String peer, Uint8List data) {
    final sending = _sendChain.then((_) => _send(peer, data));
    _sendChain = sending.catchError((_) {});
    return sending;
  }

  Future<void> _send(String peer, Uint8List payload) async {
    final central = _centrals[peer];
    if (central != null) return _notify(central, payload);
    final host = _host;
    if (host != null && host.uuid.toString() == peer) return _write(payload);
  }

  Future<void> _notify(Central central, Uint8List payload) async {
    final characteristic = _characteristic;
    if (characteristic == null) return;
    var chunkSize = 20;
    try {
      chunkSize = await _peripheralManager
          .getMaximumNotifyLength(central)
          .timeout(_opTimeout);
    } catch (_) {}
    var sent = 0;
    for (final chunk in _frame(payload, chunkSize)) {
      try {
        await _peripheralManager
            .notifyCharacteristic(central, characteristic, value: chunk)
            .timeout(_opTimeout);
        sent++;
      } catch (e) {
        // The client has part of the message and would read the next one
        // as its rest, or the radio is stuck. Dropping the link starts both
        // sides over. Not supported on Darwin, the heartbeat drops the
        // client there.
        if (sent > 0 || e is TimeoutException) {
          try {
            await _peripheralManager.disconnect(central).timeout(_opTimeout);
          } catch (_) {}
        }
        return;
      }
    }
  }

  Future<void> _write(Uint8List payload) async {
    final peripheral = _host;
    final characteristic = _hostCharacteristic;
    if (peripheral == null || characteristic == null) return;
    var chunkSize = 20;
    try {
      chunkSize = await _centralManager
          .getMaximumWriteLength(
            peripheral,
            type: GATTCharacteristicWriteType.withResponse,
          )
          .timeout(_opTimeout);
    } catch (_) {}
    var sent = 0;
    for (final chunk in _frame(payload, chunkSize)) {
      try {
        await _centralManager
            .writeCharacteristic(
              peripheral,
              characteristic,
              value: chunk,
              type: GATTCharacteristicWriteType.withResponse,
            )
            .timeout(_opTimeout);
        sent++;
      } catch (e) {
        // The host has part of the message, or the radio is stuck, see
        // _notify. The link is reported lost, so the session connects again.
        if (sent > 0 || e is TimeoutException) {
          try {
            await _centralManager.disconnect(peripheral).timeout(_opTimeout);
          } catch (_) {}
        }
        return;
      }
    }
  }
}
