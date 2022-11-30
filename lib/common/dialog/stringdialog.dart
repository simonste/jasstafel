import 'package:flutter/material.dart';

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
        title: const Text('Team name'),
        content: TextField(
            decoration: const InputDecoration(hintText: "Enter Name"),
            autofocus: true,
            keyboardType: TextInputType.text,
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
