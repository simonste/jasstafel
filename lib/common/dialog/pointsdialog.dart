import 'package:flutter/material.dart';

class IntValue {
  int? value;

  IntValue(this.value);
}

Future<IntValue?> pointsDialogBuilder(
    BuildContext context, TextEditingController controller) {
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
        title: const Text('Points'),
        content: TextField(
            decoration: const InputDecoration(hintText: "Enter Points"),
            autofocus: true,
            keyboardType: TextInputType.number,
            controller: controller,
            onSubmitted: (value) => finish()),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Enter'),
            onPressed: () {
              finish();
            },
          ),
        ],
      );
    },
  );
}
