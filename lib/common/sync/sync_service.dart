import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/sync/ble_sync_transport.dart';
import 'package:jasstafel/common/sync/sync_session.dart';
import 'package:jasstafel/common/sync/sync_transport.dart';
import 'package:jasstafel/settings/board_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:jasstafel/common/sync/sync_session.dart'
    show SyncRole, SyncEvent, SyncStatus;
export 'package:jasstafel/common/sync/sync_transport.dart'
    show BluetoothState, SyncHost;

/// The app's sync session: the [SyncSession] over Bluetooth, wired to the
/// board on screen, the preferences and the Android activity.
class SyncService implements SyncBoards {
  SyncService._() {
    SyncTransport transport = const UnsupportedSyncTransport();
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
      try {
        transport = BleSyncTransport();
      } on UnimplementedError {
        // No plugin, as in widget tests.
      }
    }
    _session = SyncSession(transport, this);
  }

  static final SyncService instance = SyncService._();

  late final SyncSession _session;

  static const _platform = MethodChannel('jasstafel/platform');

  // Bound board.
  BoardData<BoardSettings, Score>? _boundData;
  VoidCallback? _onRemoteUpdate;
  VoidCallback? _onSwitchBoard;

  ValueListenable<SyncStatus> get status => _session.status;
  Stream<SyncEvent> get events => _session.events;
  ValueListenable<List<SyncHost>> get hosts => _session.hosts;
  bool get isActive => _session.isActive;

  /// The board to switch to, as another device did.
  Board? get switchingTo => _session.switchingTo;

  BluetoothState get bluetoothState => _session.bluetoothState;
  Stream<BluetoothState> get bluetoothStateChanged =>
      _session.bluetoothStateChanged;
  Future<bool> authorize() => _session.authorize();
  Future<void> showAppSettings() => _session.showAppSettings();
  Future<bool> scanNeedsLocation() => _session.scanNeedsLocation();
  Future<void> openLocationSettings() => _session.openLocationSettings();

  Future<void> startHost() => _session.startHost();
  Future<void> startClientDiscovery() => _session.startDiscovery();
  Future<bool> connectToHost(String host) => _session.connectToHost(host);
  Future<void> stop() => _session.stop();
  void shareChanges() => _session.shareChanges();

  /// Moves the app to the background, which keeps the session going, see
  /// MainActivity.
  Future<void> moveToBackground() =>
      _platform.invokeMethod<void>('moveTaskToBack').catchError((_) {});

  /// For tests: the session's status as a notifier to set.
  @visibleForTesting
  ValueNotifier<SyncStatus> get statusNotifier => _session.status;

  /// Binds the board on screen so its changes are shared and received states
  /// are applied. [onSwitchBoard] opens [switchingTo], the board another
  /// device switched to.
  void bind({
    required BoardData<BoardSettings, Score> data,
    required VoidCallback onRemoteUpdate,
    required VoidCallback onSwitchBoard,
  }) {
    _boundData = data;
    _onRemoteUpdate = onRemoteUpdate;
    _onSwitchBoard = onSwitchBoard;
    BoardData.onSaveBroadcast = (data, json) {
      if (identical(data, _boundData)) {
        _session.broadcast(_stateOf(data, json));
      }
    };
    BoardData.onLoaded = (data) {
      if (identical(data, _boundData)) _session.boardLoaded(_stateOf(data));
    };
  }

  /// Unbinds the board when its screen is disposed. The session goes on, so
  /// navigation doesn't drop it.
  void unbind(BoardData<BoardSettings, Score> data) {
    if (!identical(_boundData, data)) return;
    _boundData = null;
    _onRemoteUpdate = null;
    _onSwitchBoard = null;
    BoardData.onSaveBroadcast = null;
    BoardData.onLoaded = null;
  }

  static BoardState _stateOf(
    BoardData<BoardSettings, Score> data, [
    String? json,
  ]) => BoardState(
    data.boardType,
    jsonDecode(json ?? data.currentJson()) as Map<String, dynamic>,
    data.sharedSettings(),
  );

  @override
  BoardState? get current {
    final data = _boundData;
    return data == null ? null : _stateOf(data);
  }

  @override
  Future<void> show(BoardState state) async {
    final data = _boundData;
    if (data != null && data.boardType == state.board) {
      try {
        data.applyRemote(jsonEncode(state.data), state.settings);
      } catch (_) {
        return;
      }
      _onRemoteUpdate?.call();
      return;
    }

    // Another device switched the board: store its state for the board to
    // load, then open it.
    await BoardData.storeSharedSettings(state.board, state.settings);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      BoardData.dataKeyOf(state.board),
      jsonEncode(state.data),
    );
    _onSwitchBoard?.call();
  }
}
