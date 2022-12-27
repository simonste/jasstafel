import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

class IntValue {
  int? value;
  bool scratch;

  IntValue(this.value, {this.scratch = false});
}

Future<IntValue?> pointsDialogBuilder(
    BuildContext context, TextEditingController controller,
    {Widget? title}) {
  title ??= Text(context.l10n.points);

  return showDialog<IntValue>(
    context: context,
    builder: (BuildContext context) {
      void finish() {
        try {
          Navigator.of(context).pop(IntValue(int.parse(controller.text)));
        } on FormatException {
          Navigator.of(context).pop(IntValue(null));
        }
      }

      return AlertDialog(
        title: title,
        content: TextField(
            decoration: InputDecoration(hintText: context.l10n.points),
            autofocus: true,
            keyboardType: TextInputType.number,
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
