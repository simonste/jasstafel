import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeurtypeimage.dart';
import 'package:jasstafel/common/localization.dart';

class CoiffeurType {
  int factor;
  String type;

  CoiffeurType(this.factor, this.type);
}

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

      String proposedType(n) {
        switch (n) {
          case 0:
            return context.l10n.eicheln;
          case 1:
            return context.l10n.schellen;
          case 2:
            return context.l10n.schilten;
          case 3:
            return context.l10n.rosen;
          case 4:
            return context.l10n.schaufel;
          case 5:
            return context.l10n.kreuz;
          case 6:
            return context.l10n.ecken;
          case 7:
            return context.l10n.herz;
          case 8:
            return context.l10n.obenabe;
          case 9:
            return context.l10n.ondenufe;
          case 10:
            return context.l10n.slalom;
          case 11:
            return context.l10n.gusti;
          case 12:
            return context.l10n.mery;
          case 13:
            return context.l10n.misere;
          case 14:
            return context.l10n.wunsch;
          case 15:
            return context.l10n.coiffeur;
        }
        return context.l10n.wunsch;
      }

      TableRow createRow(i) {
        Widget child(n) {
          return InkWell(
            onTap: () => controller.text = proposedType(n),
            child: Column(children: [
              CoiffeurTypeImage(context, proposedType(n), width: 30),
              Text(
                proposedType(n),
                textScaleFactor: 0.7,
              )
            ]),
          );
        }

        return TableRow(children: [
          child(i * 4),
          child(i * 4 + 1),
          child(i * 4 + 2),
          child(i * 4 + 3)
        ]);
      }

      return AlertDialog(
        title: Text(context.l10n.xTimes(factor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                decoration:
                    InputDecoration(hintText: context.l10n.xTimes(factor)),
                keyboardType: TextInputType.text,
                controller: controller,
                onSubmitted: (value) => finish()),
            Container(height: 20),
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
