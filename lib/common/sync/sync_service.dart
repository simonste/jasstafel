import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/sync/ble_sync_transport.dart';
import 'package:jasstafel/common/sync/sync_session.dart';
import 'package:jasstafel/common/sync/sync_transport.dart';
import 'package:jasstafel/settings/board_settings.dart';

export 'package:jasstafel/common/sync/sync_session.dart'
    show SyncRole, SyncEvent, SyncStatus;
export 'package:jasstafel/common/sync/sync_transport.dart'
    show BluetoothState, SyncHost;

/// The host's board arrived on joining: the profile to show it in here is
/// up to the player.
class ProfileRequest {
  final Board board;

  /// The host's profile.
  final String profile;

  /// The active profile of [board] here.
  final String active;

  /// The profiles of [board] here.
  final List<String> names;

  const ProfileRequest(this.board, this.profile, this.active, this.names);
}

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
    _session.status.addListener(_onStatus);
  }

  static final SyncService instance = SyncService._();

  late final SyncSession _session;

  static const _platform = MethodChannel('jasstafel/platform');
  bool _wasActive = false;

  // Bound board.
  BoardData<BoardSettings, Score>? _boundData;
  VoidCallback? _onRemoteUpdate;
  VoidCallback? _onSwitchBoard;

  /// Asks which profile to show the joined host's board in, until chosen.
  final profileRequest = ValueNotifier<ProfileRequest?>(null);
  bool _profileChosen = false;

  /// The latest state of the host, while the profile isn't chosen yet.
  BoardState? _waiting;

  /// The profile here a board of the joined host is shown in, by the board
  /// and the host's profile.
  final _localProfiles = <(Board, String), String>{};

  /// The host's profile each board is shown from, by which this device
  /// tells its changes.
  final _hostProfiles = <Board, String>{};

  /// The state of the board another device switched to, until it opened.
  BoardState? _switching;

  /// States are shown one after the other, as switching the profile takes
  /// a while.
  Future<void> _showing = Future.value();

  ValueListenable<SyncStatus> get status => _session.status;
  Stream<SyncEvent> get events => _session.events;
  ValueListenable<List<SyncHost>> get hosts => _session.hosts;
  bool get isActive => _session.isActive;

  /// The board to switch to, as another device did. Not before a joining
  /// device chose the profile to show it in: cancelling the choice leaves
  /// the board as it was.
  Board? get switchingTo =>
      _isClient && !_profileChosen ? null : _session.switchingTo;

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

  bool get _isClient => _session.status.value.role == SyncRole.client;

  void _onStatus() {
    final active = _session.status.value.active;
    if (active == _wasActive) return;
    _wasActive = active;
    if (!active) {
      profileRequest.value = null;
      _profileChosen = false;
      _waiting = null;
      _localProfiles.clear();
      _hostProfiles.clear();
      _switching = null;
    }
  }

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
    BoardData.onLoaded = (data) async {
      if (!identical(data, _boundData)) return;
      final state = _switching;
      _switching = null;
      if (state != null && state.board == data.boardType) {
        await _enqueue(() => _applyTo(data, state));
      }
      _session.boardLoaded(_stateOf(data));
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

  BoardState _stateOf(BoardData<BoardSettings, Score> data, [String? json]) =>
      BoardState(
        data.boardType,
        jsonDecode(json ?? data.currentJson()) as Map<String, dynamic>,
        data.sharedSettings(),
        profile:
            (_isClient ? _hostProfiles[data.boardType] : null) ??
            data.profiles.active,
      );

  @override
  BoardState? get current {
    final data = _boundData;
    return data == null ? null : _stateOf(data);
  }

  @override
  Future<void> show(BoardState state) async {
    if (_isClient && !_profileChosen) {
      final asking = _waiting != null;
      _waiting = state;
      if (asking) return;
      final request = await _profileRequest(state);
      if (_waiting != null) profileRequest.value = request;
      return;
    }
    await _enqueue(() => _show(state));
  }

  Future<ProfileRequest> _profileRequest(BoardState state) async {
    final data = _boundData;
    final (active, names) = data != null && data.boardType == state.board
        ? (data.profiles.active, data.profileMap().keys.toList())
        : await BoardData.storedProfiles(state.board);
    return ProfileRequest(state.board, state.profile, active, [
      ...names,
      if (!names.contains(active)) active,
    ]);
  }

  /// Shows the joined host's board in profile [name] here, as the player
  /// chose, created if there is none of that name.
  Future<void> chooseProfile(String name) async {
    final request = profileRequest.value;
    final state = _waiting;
    if (request == null || state == null) return;
    _localProfiles[(request.board, request.profile)] = name;
    _profileChosen = true;
    _waiting = null;
    profileRequest.value = null;
    await _enqueue(() => _show(state));
  }

  Future<void> _enqueue(Future<void> Function() action) =>
      _showing = _showing.then((_) => action()).catchError((_) {});

  Future<void> _show(BoardState state) async {
    final data = _boundData;
    if (data != null && data.boardType == state.board) {
      await _applyTo(data, state);
      _onRemoteUpdate?.call();
      return;
    }

    // Another device switched the board: keep its state for the board to
    // take once open, then open it.
    _switching = state;
    _onSwitchBoard?.call();
  }

  /// Applies [state] to [data], in the profile it is shown in here.
  Future<void> _applyTo(
    BoardData<BoardSettings, Score> data,
    BoardState state,
  ) async {
    if (_isClient && state.profile.isNotEmpty) {
      // The one chosen on joining, else the one of the host's name.
      final local = _localProfiles.putIfAbsent((
        data.boardType,
        state.profile,
      ), () => state.profile);
      await data.switchProfile(local);
      _hostProfiles[data.boardType] = state.profile;
    }
    data.applyRemote(jsonEncode(state.data), state.settings);
  }
}
