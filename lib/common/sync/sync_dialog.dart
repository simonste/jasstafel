import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jasstafel/common/dialog/safe_dialog.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/sync/sync_service.dart';

Future<void> showSyncDialog(BuildContext context) {
  return showSafeDialog<void>(
    context: context,
    builder: (context) => const SyncDialog(),
  );
}

/// Dialog to host or join a Bluetooth screen-sync session.
class SyncDialog extends StatefulWidget {
  const SyncDialog({super.key});

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog> {
  final _sync = SyncService.instance;
  late BluetoothState _bluetoothState = _sync.bluetoothState;
  late final StreamSubscription<BluetoothState> _stateSubscription;
  late final AppLifecycleListener _lifecycleListener;
  bool _permissionDenied = false;
  bool _connectFailed = false;

  /// The host being connected to, until its board is taken.
  String? _connecting;

  /// Connected, the host's board is waiting for the profile to be chosen.
  bool _joining = false;

  /// The profile chosen to show the host's board in.
  String? _profile;

  /// Whether scanning needs the location turned on.
  bool _locationOff = false;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _sync.bluetoothStateChanged.listen(
      (state) => setState(() => _bluetoothState = state),
    );
    // The permission state is not reported as a state change, so re-check
    // when returning from the permission dialog or the app settings.
    _lifecycleListener = AppLifecycleListener(onResume: _refreshState);
    _sync.status.addListener(_onStatus);
    _checkLocation();
  }

  /// The session ended while joining.
  void _onStatus() {
    if (_sync.status.value.role == SyncRole.client || !mounted) return;
    setState(() {
      _connecting = null;
      _joining = false;
    });
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    _lifecycleListener.dispose();
    _sync.status.removeListener(_onStatus);
    // Closed while searching: nothing would show the search going on. Or
    // before the host's board was taken: it would stay waiting.
    final status = _sync.status.value;
    if (status.role == SyncRole.client &&
        (_joining || (status.connectedPeers == 0 && _connecting == null))) {
      _sync.stop();
    }
    super.dispose();
  }

  void _refreshState() {
    if (mounted) setState(() => _bluetoothState = _sync.bluetoothState);
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    final off = await _sync.scanNeedsLocation();
    if (!mounted) return;
    final status = _sync.status.value;
    if (_locationOff &&
        !off &&
        status.role == SyncRole.client &&
        status.connectedPeers == 0) {
      // A scan started without the location finds nothing even after.
      _sync.startClientDiscovery();
    }
    setState(() => _locationOff = off);
  }

  Future<void> _requestPermission() async {
    final granted = await _sync.authorize();
    if (!mounted) return;
    setState(() => _permissionDenied = !granted);
    _refreshState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: _sync.status,
      builder: (context, status, _) {
        return ValueListenableBuilder<ProfileRequest?>(
          valueListenable: _sync.profileRequest,
          builder: (context, request, _) {
            final (content, actions) = switch (status.role) {
              SyncRole.idle => _idle(context),
              SyncRole.host => _host(context, status),
              SyncRole.client when request != null && _joining =>
                _profileChoice(context, status, request),
              SyncRole.client => _client(context, status),
            };
            return AlertDialog(
              title: Text(context.l10n.syncTitle),
              content: content,
              actions: actions,
            );
          },
        );
      },
    );
  }

  (Widget, List<Widget>) _idle(BuildContext context) {
    final state = _bluetoothState;
    if (state == BluetoothState.unsupported) {
      return (
        _message(Icons.bluetooth_disabled, context.l10n.syncUnsupported),
        [_closeButton(context)],
      );
    }
    if (state == BluetoothState.unauthorized) {
      final android = Theme.of(context).platform == TargetPlatform.android;
      return (
        _message(
          Icons.bluetooth_disabled,
          context.l10n.syncPermissionRequired,
          hint: android ? context.l10n.syncLocationHint : null,
        ),
        [
          _closeButton(context, text: context.l10n.cancel),
          _permissionDenied
              ? _textButton(
                  context.l10n.syncOpenSettings,
                  _sync.showAppSettings,
                )
              : _textButton(
                  context.l10n.syncGrantPermission,
                  _requestPermission,
                ),
        ],
      );
    }
    if (state != BluetoothState.on) {
      return (
        _message(Icons.bluetooth_disabled, context.l10n.syncBluetoothOff),
        [_closeButton(context)],
      );
    }
    return (
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.wifi_tethering),
            title: Text(context.l10n.syncHostAction),
            onTap: () => _sync.startHost(),
          ),
          ListTile(
            leading: const Icon(Icons.bluetooth_searching),
            title: Text(context.l10n.syncJoinAction),
            onTap: () => _sync.startClientDiscovery(),
          ),
        ],
      ),
      [_closeButton(context, text: context.l10n.cancel)],
    );
  }

  (Widget, List<Widget>) _host(BuildContext context, SyncStatus status) {
    return (
      _message(
        Icons.wifi_tethering,
        status.connectedPeers > 0
            ? context.l10n.syncConnectedDevices(status.connectedPeers)
            : context.l10n.syncHosting,
        title: status.sessionName,
      ),
      [_stopButton(context), _closeButton(context)],
    );
  }

  (Widget, List<Widget>) _client(BuildContext context, SyncStatus status) {
    if (status.connectedPeers > 0 && !_joining) {
      return (
        _message(
          Icons.bluetooth_connected,
          context.l10n.syncConnectedDevices(status.connectedPeers),
          title: status.sessionName,
        ),
        [_stopButton(context), _closeButton(context)],
      );
    }

    return (
      SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                // Wraps on narrow phones.
                Flexible(
                  child: Text(
                    _connecting == null
                        ? context.l10n.syncScanning
                        : context.l10n.syncConnecting,
                  ),
                ),
              ],
            ),
            if (_locationOff) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.syncLocationOff,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _textButton(
                  context.l10n.syncTurnOnLocation,
                  _sync.openLocationSettings,
                ),
              ),
            ],
            if (_connectFailed) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.syncConnectFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: ValueListenableBuilder<List<SyncHost>>(
                valueListenable: _sync.hosts,
                builder: (context, hosts, _) {
                  if (hosts.isEmpty) {
                    return Text(
                      context.l10n.syncNoHosts(context.l10n.syncHostAction),
                    );
                  }
                  // In the order found, so entries don't move under the
                  // finger as their signal changes.
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: hosts.length,
                    itemBuilder: (context, index) {
                      final host = hosts[index];
                      final connecting = host.id == _connecting;
                      return ListTile(
                        leading: Icon(_signalIcon(host.rssi)),
                        title: Text(
                          host.name.isEmpty
                              ? context.l10n.syncUnnamedDevice
                              : host.name,
                        ),
                        trailing: connecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        enabled: _connecting == null,
                        onTap: () => _connect(host.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      [_stopButton(context)],
    );
  }

  Future<void> _connect(String host) async {
    setState(() {
      _connectFailed = false;
      _connecting = host;
    });
    final connected = await _sync.connectToHost(host);
    if (!mounted) {
      // Closed meanwhile: nothing would ask for the profile.
      _sync.stop();
      return;
    }
    if (connected) {
      // The host's board arrives, for the profile to be chosen.
      setState(() => _joining = true);
    } else {
      setState(() {
        _connectFailed = true;
        _connecting = null;
      });
    }
  }

  /// Asks which profile to show the host's board in: a new one or the one
  /// of the host's name, else one named after the host, or the active one.
  (Widget, List<Widget>) _profileChoice(
    BuildContext context,
    SyncStatus status,
    ProfileRequest request,
  ) {
    final l10n = context.l10n;
    final host = status.sessionName ?? l10n.syncUnnamedDevice;
    final targets = request.names.contains(request.profile)
        ? [request.profile, '$host ${request.profile}']
        : [request.profile, request.active];
    final selected = _profile ?? targets.first;
    Widget option(String target, String other) {
      final exists = request.names.contains(target);
      return RadioListTile<String>(
        value: target,
        contentPadding: EdgeInsets.zero,
        title: Text(
          exists ? l10n.replaceProfile(target) : l10n.importProfile(target),
        ),
        subtitle: Text(
          exists ? l10n.replaceProfileHint : l10n.importProfileHint(other),
        ),
      );
    }

    return (
      RadioGroup<String>(
        groupValue: selected,
        onChanged: (target) => setState(() => _profile = target),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(host, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            option(targets[0], targets[1]),
            option(targets[1], targets[0]),
          ],
        ),
      ),
      [
        // Stops joining, see dispose.
        _closeButton(context, text: l10n.cancel),
        _textButton(l10n.ok, () async {
          _joining = false;
          await _sync.chooseProfile(selected);
          // The board follows the host once the dialog is closed.
          if (context.mounted) Navigator.of(context).pop();
        }),
      ],
    );
  }

  static IconData _signalIcon(int rssi) {
    if (rssi >= -60) return Icons.signal_cellular_alt;
    if (rssi >= -80) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  Widget _message(IconData icon, String text, {String? title, String? hint}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48),
        const SizedBox(height: 16),
        if (title != null)
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        Text(text, textAlign: TextAlign.center),
        if (hint != null) ...[
          const SizedBox(height: 12),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _textButton(String text, VoidCallback onPressed) {
    return TextButton(
      style: TextButton.styleFrom(
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }

  Widget _closeButton(BuildContext context, {String? text}) {
    return _textButton(
      text ?? context.l10n.ok,
      () => Navigator.of(context).pop(),
    );
  }

  Widget _stopButton(BuildContext context) {
    return _textButton(context.l10n.syncStop, () => _sync.stop());
  }
}
