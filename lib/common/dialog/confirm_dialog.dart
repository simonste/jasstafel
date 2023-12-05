import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

class DialogAction {
  final String text;
  final Function? action;

  DialogAction({required this.text, this.action});
}

Future<void> confirmDialog(
    {required BuildContext context,
    required String title,
    required String subtitle,
    required List<DialogAction> actions}) {
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

            final defaultButtonText =
                actions.isEmpty ? context.l10n.ok : context.l10n.cancel;
            var actionButtons = [textButton(defaultButtonText, () {})];
            for (final action in actions) {
              if (action.action != null) {
                actionButtons.add(textButton(action.text, action.action!));
              } else {
                actionButtons.add(textButton(action.text, () {}));
              }
            }

            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: const TextStyle(fontWeight: FontWeight.w100),
                    textScaler: const TextScaler.linear(0.8),
                  )
                ],
              ),
              actions: actionButtons,
            );
          },
        );
      });
}
