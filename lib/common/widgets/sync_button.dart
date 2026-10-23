import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/sync/sync_dialog.dart';
import 'package:jasstafel/common/sync/sync_service.dart';

/// App-bar action that opens the screen-sync dialog and reflects the current
/// connection state through its icon.
class SyncButton extends IconButton {
  SyncButton(BuildContext context, {super.key = const Key('sync')})
    : super(
        tooltip: context.l10n.syncTitle,
        onPressed: () => showSyncDialog(context),
        icon: ValueListenableBuilder<SyncStatus>(
          valueListenable: SyncService.instance.status,
          builder: (context, status, _) {
            if (status.connectedPeers > 0) {
              return const Icon(
                Icons.bluetooth_connected,
                color: Colors.lightBlueAccent,
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
