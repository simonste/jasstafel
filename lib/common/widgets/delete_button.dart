import 'package:flutter/material.dart';
import 'package:jasstafel/common/dialog/confirm_dialog.dart';
import 'package:jasstafel/common/localization.dart';

class DeleteButton extends IconButton {
  DeleteButton(BuildContext context, Function deleteFunction,
      {Function? deleteAllFunction})
      : super(
            key: const Key('delete'),
            onPressed: () {
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
                      : context.l10n.resetConfirm,
                  actions: actions);
            },
            icon: const Icon(Icons.delete));
}
