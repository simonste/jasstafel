import 'package:flutter/material.dart';

class CoiffeurType {
  int factor;
  String type;

  CoiffeurType(this.factor, this.type);
}

List<String> proposedTypes = [
  "Eicheln",
  "Schellen",
  "Rosen",
  "Schilten",
  "Schaufel",
  "Kreuz",
  "Ecken",
  "Herz",
  "Obenabe",
  "Ondenufe",
  "Slalom",
  "Gusti",
  "Mery",
  "Misere",
  "Wunsch",
  "Coiffeur"
];

Future<CoiffeurType?> coiffeurTypeDialogBuilder(
    BuildContext context, TextEditingController controller, factor) {
  return showDialog<CoiffeurType>(
    context: context,
    builder: (BuildContext context) {
      void finish() {
        try {
          Navigator.of(context).pop(CoiffeurType(factor, controller.text));
        } on FormatException {
          Navigator.of(context).pop(CoiffeurType(0, ""));
        }
      }

      TableRow createRow(i) {
        Text child(n) {
          return Text(proposedTypes[n]);
        }

        return TableRow(children: [
          child(i * 4),
          child(i * 4 + 1),
          child(i * 4 + 2),
          child(i * 4 + 3)
        ]);
      }

      return AlertDialog(
        title: Text("Typ $factor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                decoration: const InputDecoration(hintText: "Enter Name"),
                autofocus: true,
                keyboardType: TextInputType.text,
                controller: controller,
                onSubmitted: (value) => finish()),
            Table(children: [
              createRow(0),
              createRow(1),
              createRow(2),
              createRow(3),
            ])
          ],
        ),
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
