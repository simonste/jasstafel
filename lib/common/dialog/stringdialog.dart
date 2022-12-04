import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

Future<String?> stringDialogBuilder(
    BuildContext context, TextEditingController controller) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      void finish() {
        try {
          Navigator.of(context).pop(controller.text);
        } on FormatException {
          Navigator.of(context).pop();
        }
      }

      return AlertDialog(
        title: Text(context.l10n.teamName),
        content: TextField(
            decoration: InputDecoration(hintText: context.l10n.teamName),
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
