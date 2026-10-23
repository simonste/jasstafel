import 'dart:async';
import 'dart:typed_data';

import 'package:jasstafel/common/sync/sync_transport.dart';
import 'package:test/test.dart';

/// A radio that is on, and tells what its streams carry.
class _Radio extends UnsupportedSyncTransport {
  final stateController = StreamController<BluetoothState>.broadcast();
  final messageController = StreamController<SyncMessage>.broadcast();

  @override
  BluetoothState get state => BluetoothState.on;
  @override
  Stream<BluetoothState> get stateChanged => stateController.stream;
  @override
  Stream<SyncMessage> get messages => messageController.stream;
}

void main() {
  test('the radio is set up only once the sync is used', () async {
    var created = 0;
    final radio = _Radio();
    final transport = LazySyncTransport(() {
      created++;
      return radio;
    });

    // As the session does from the start.
    final states = <BluetoothState>[];
    final messages = <SyncMessage>[];
    transport.stateChanged.listen(states.add);
    transport.messages.listen(messages.add);
    expect(created, 0);

    // As the sync dialog does.
    expect(transport.state, BluetoothState.on);
    await transport.startScan();
    expect(created, 1);

    radio.stateController.add(BluetoothState.off);
    radio.messageController.add((peer: 'a', data: Uint8List(1)));
    await Future<void>.delayed(Duration.zero);
    expect(states, [BluetoothState.off]);
    expect(messages.single.peer, 'a');
  });

  test('without the plugin there is no Bluetooth', () {
    final transport = LazySyncTransport(() => throw UnimplementedError());
    expect(transport.state, BluetoothState.unsupported);
  });
}
