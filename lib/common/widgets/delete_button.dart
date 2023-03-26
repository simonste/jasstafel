import 'package:flutter/material.dart';
import 'package:jasstafel/common/dialog/confirm_dialog.dart';
import 'package:jasstafel/common/localization.dart';

class DeleteButton extends IconButton {
  DeleteButton(BuildContext context,
      {required Function deleteFunction,
      Function? deleteAllFunction,
      String resetHint = ''})
      : super(
            key: const Key('delete'),
            onPressed: () {
              if (resetHint.isEmpty) {
                resetHint = context.l10n.resetConfirm;
              }

              var actions = <DialogAction>[];
              if (deleteAllFunction != null) {
                actions.add(DialogAction(
                    text: context.l10n.resetAll, action: deleteAllFunction));
                actions.add(DialogAction(
                    text: context.l10n.currentRound, action: deleteFunction));
              } else {
                actions.add(DialogAction(
                    text: context.l10n.ok, action: deleteFunction));
              }
              confirmDialog(
                  context: context,
                  title: context.l10n.reset,
                  subtitle: deleteAllFunction != null
                      ? context.l10n.deleteWhat
                      : resetHint,
                  actions: actions);
            },
            icon: const Icon(Icons.delete));
}
