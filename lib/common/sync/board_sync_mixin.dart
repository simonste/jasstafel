import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/sync/sync_service.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';
import 'package:jasstafel/settings/board_settings.dart';
import 'package:jasstafel/settings/common_settings.g.dart';

/// Lets boards notice when the screens and dialogs above them are closed.
final syncRouteObserver = RouteObserver<ModalRoute<void>>();

/// Back on the board while a session runs on Android: the app moves to the
/// background like Android 12+ does, rather than finishing. A finished app
/// would leave the session's Bluetooth link open without the app to serve
/// it. Handled here, as Android 16 doesn't ask the app before finishing it.
class _MoveToBackground extends PopEntry<Object?> {
  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier(true);

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop) SyncService.instance.moveToBackground();
  }
}

/// Wires a board screen into [SyncService] for its whole lifetime: local
/// changes are broadcast to synced devices and remote updates rebuild the
/// board. Boards mix this in and expose their [BoardData] via [syncData].
///
/// When another device switches the board, the switch waits until the
/// screens and dialogs above the board are closed, to not lose any input.
/// Once a screen above the board is closed, the changes made there, such as
/// in the settings, are shared.
mixin BoardSyncMixin<T extends StatefulWidget> on State<T>
    implements RouteAware {
  BoardData<BoardSettings, Score> get syncData;

  late final StreamSubscription<SyncEvent> _events;
  late bool _syncActive = SyncService.instance.status.value.active;
  final _back = _MoveToBackground();
  ModalRoute<void>? _route;

  @override
  void initState() {
    super.initState();
    _events = SyncService.instance.events.listen(_showEvent);
    SyncService.instance.status.addListener(_onStatus);
    SyncService.instance.bind(
      data: syncData,
      onRemoteUpdate: () {
        if (mounted) setState(() {});
      },
      onSwitchBoard: _switchBoard,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) syncRouteObserver.subscribe(this, route);
    if (route != _route) {
      _route?.unregisterPopEntry(_back);
      _route = route;
      route?.registerPopEntry(_back);
    }
    _updateBack();
  }

  void _updateBack() {
    _back.canPopNotifier.value =
        defaultTargetPlatform != TargetPlatform.android ||
        !_syncActive ||
        !(_route?.isFirst ?? false);
  }

  @override
  void dispose() {
    _events.cancel();
    SyncService.instance.status.removeListener(_onStatus);
    syncRouteObserver.unsubscribe(this);
    _route?.unregisterPopEntry(_back);
    _back.canPopNotifier.dispose();
    SyncService.instance.unbind(syncData);
    super.dispose();
  }

  void _switchBoard() {
    final board = SyncService.instance.switchingTo;
    if (board == null || board == syncData.boardType || !mounted) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final preferences = SettingsProvider.of(context);
    preferences.setInt(CommonSettings.keys.lastBoard, board.index);
    // Removes all routes, as a closing dialog may still be on top of the
    // board, which would get stuck there when only replacing the board.
    Navigator.of(
      context,
    ).restorablePushNamedAndRemoveUntil(board.name, (route) => false);
  }

  /// The sync button moves between the menu and the bar when a session
  /// starts or ends.
  void _onStatus() {
    final active = SyncService.instance.status.value.active;
    if (active == _syncActive || !mounted) return;
    setState(() => _syncActive = active);
    _updateBack();
  }

  void _showEvent(SyncEvent event) {
    if (!mounted) return;
    final text = switch (event) {
      SyncEvent.ended => context.l10n.syncEnded,
      SyncEvent.connectionLost => context.l10n.syncConnectionLost,
      SyncEvent.deviceLeft => context.l10n.syncDeviceLeft,
      SyncEvent.versionMismatch => context.l10n.syncVersionMismatch,
      SyncEvent.reconnecting => context.l10n.syncReconnecting,
      SyncEvent.reconnected => context.l10n.syncReconnected,
      SyncEvent.bluetoothOff => context.l10n.syncBluetoothTurnedOff,
      SyncEvent.full => context.l10n.syncFull(SyncService.maxClients),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Called while the navigator pops, so switch once it is done.
  @override
  void didPopNext() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    SyncService.instance.shareChanges();
    _switchBoard();
  });

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}
}
