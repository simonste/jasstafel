import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

class DeleteButton extends IconButton {
  DeleteButton(BuildContext context, Function deleteFunction,
      {Function? deleteAllFunction, super.key})
      : super(
            onPressed: () {
              dialogBuilder(context, deleteFunction, deleteAllFunction);
            },
            icon: const Icon(Icons.delete));
}

Future<void> dialogBuilder(BuildContext context, Function deleteFunction,
    Function? deleteAllFunction) {
  return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            textButton(String text, Function function) {
              return TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: Text(text),
                  onPressed: () {
                    function();
                    Navigator.of(context).pop();
                  });
            }

            var actions = [textButton(context.l10n.cancel, () {})];
            if (deleteAllFunction != null) {
              actions.add(textButton(context.l10n.resetAll, deleteAllFunction));
              actions
                  .add(textButton(context.l10n.currentRound, deleteFunction));
            } else {
              actions.add(textButton(context.l10n.ok, deleteFunction));
            }

            return AlertDialog(
              title: Text(context.l10n.reset),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deleteAllFunction != null
                        ? context.l10n.deleteWhat
                        : context.l10n.resetConfirm,
                    style: const TextStyle(fontWeight: FontWeight.w100),
                    textScaleFactor: 0.8,
                  )
                ],
              ),
              actions: actions,
            );
          },
        );
      });
}
