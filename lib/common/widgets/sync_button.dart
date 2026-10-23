import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/sync/sync_dialog.dart';
import 'package:jasstafel/common/sync/sync_service.dart';

/// Title bar action that opens the sync dialog, its icon shows the state of
/// the session.
class SyncButton extends IconButton {
  SyncButton(BuildContext context, {super.key = const Key('sync')})
    : super(
        tooltip: context.l10n.syncTitle,
        onPressed: () => showSyncDialog(context),
        icon: ValueListenableBuilder<SyncStatus>(
          valueListenable: SyncService.instance.status,
          builder: (context, status, _) {
            if (status.connectedPeers > 0) {
              // Light blue would hardly show on the blue bar of the light
              // theme, the icon tells it there.
              final dark = Theme.of(context).brightness == Brightness.dark;
              return Icon(
                Icons.bluetooth_connected,
                color: dark ? Colors.lightBlueAccent : null,
              );
            }
            if (status.active) {
              return const Icon(Icons.bluetooth_searching);
            }
            return const Icon(Icons.bluetooth);
          },
        ),
      );
}
