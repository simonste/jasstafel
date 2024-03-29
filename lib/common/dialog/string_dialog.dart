import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

Future<String?> stringDialogBuilder(
    BuildContext context, TextEditingController controller,
    {String? title}) {
  var titleWidget = Text(title ?? context.l10n.teamName);
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      void finish() {
        if (controller.text.isEmpty) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pop(controller.text);
        }
      }

      return AlertDialog(
        title: titleWidget,
        content: TextField(
            decoration:
                InputDecoration(hintText: title ?? context.l10n.teamName),
            autofocus: true,
            keyboardType: TextInputType.text,
            controller: controller,
            onSubmitted: (value) => finish()),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: Text(context.l10n.ok),
            onPressed: () {
              finish();
            },
          ),
        ],
      );
    },
  );
}
