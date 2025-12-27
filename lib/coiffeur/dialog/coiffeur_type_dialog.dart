import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_type_image.dart';
import 'package:jasstafel/common/localization.dart';

class CoiffeurType {
  int factor;
  String type;

  CoiffeurType(this.factor, this.type);
}

String proposedType(BuildContext context, n) {
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

Future<CoiffeurType?> coiffeurTypeDialogBuilder(
  BuildContext context, {
  required String title,
  required TextEditingController controller,
  required int factor,
  required bool customFactor,
}) {
  return showDialog<CoiffeurType>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          void finish() {
            try {
              Navigator.of(context).pop(CoiffeurType(factor, controller.text));
            } on FormatException {
              Navigator.of(context).pop(CoiffeurType(0, ""));
            }
          }

          TableRow createRow(i) {
            Widget cell(n) {
              var type = proposedType(context, n);
              return InkWell(
                onTap: () => controller.text = type,
                child: Column(
                  children: [
                    CoiffeurTypeImage(context, type, width: 30),
                    Text(type, textScaler: const TextScaler.linear(0.7)),
                  ],
                ),
              );
            }

            return TableRow(
              children: [
                cell(i * 4),
                cell(i * 4 + 1),
                cell(i * 4 + 2),
                cell(i * 4 + 3),
              ],
            );
          }

          Widget getFactorWidget() {
            if (!customFactor) {
              return Container();
            }

            var list = List<int>.generate(13, (i) => i + 1);
            return DropdownButton<int>(
              key: const Key("dropdownFactor"),
              value: factor,
              onChanged: (val) {
                setState(() {
                  factor = val!;
                });
              },
              items: list.map((v) {
                return DropdownMenuItem(value: v, child: Text(v.toString()));
              }).toList(),
            );
          }

          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(right: 20),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: context.l10n.xTimes(factor),
                            ),
                            keyboardType: TextInputType.text,
                            controller: controller,
                            onSubmitted: (value) => finish(),
                          ),
                        ),
                      ),
                      getFactorWidget(),
                    ],
                  ),
                  Container(height: 20),
                  Table(
                    children: [
                      createRow(0),
                      createRow(1),
                      createRow(2),
                      createRow(3),
                    ],
                  ),
                ],
              ),
            ),
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
    },
  );
}
