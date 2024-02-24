import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';

class Points {
  int points1;
  int points2;
  bool weis = false;

  Points(this.points1, this.points2, swap) {
    if (swap) {
      final tmp = points1;
      points1 = points2;
      points2 = tmp;
    }
  }
}

class PointsController extends TextEditingController {
  PointsController() {
    text = "0";
  }

  void set(String s) {
    text = s;
  }

  void add(String s) {
    if (text == "0") {
      text = s;
    } else {
      text += s;
    }
  }

  void delete() {
    text = text.substring(0, text.length - 1);
    if (text.isEmpty) {
      text = "0";
    }
  }

  int getPoints() {
    try {
      return int.parse(text);
    } on FormatException {
      return 0;
    }
  }
}

Future<Points?> schieberDialogBuilder(BuildContext context, int teamId,
    int matchPts, int roundPts, TeamData teamData) {
  int factor = 1;
  int sign = 1;

  return showDialog<Points>(
      context: context,
      builder: (BuildContext context) {
        var ptsController = PointsController();

        pointsTeam() {
          return ptsController.getPoints() * factor * sign;
        }

        pointsOtherTeam() {
          if (ptsController.getPoints() == matchPts || sign == -1) {
            return 0;
          }
          return (roundPts - ptsController.getPoints()) * factor;
        }

        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          TableRow createRow(i) {
            Widget cell(n) {
              if (n == 10) {
                return const SizedBox.shrink();
              }

              final String number = (n == 12)
                  ? "⌫"
                  : (n == 11)
                      ? "0"
                      : "$n";

              return InkWell(
                  key: Key("key_$number"),
                  onTap: () => setState(() {
                        if (number == "⌫") {
                          ptsController.delete();
                        } else {
                          ptsController.add(number);
                        }
                      }),
                  child: Column(
                    children: [
                      SizedBox(height: 50, child: Center(child: Text(number)))
                    ],
                  ));
            }

            return TableRow(
                children: [cell(i * 3 + 1), cell(i * 3 + 2), cell(i * 3 + 3)]);
          }

          Widget getFactorWidget() {
            var list = teamData.flip
                ? List<int>.generate(7, (i) => 7 - i)
                : List<int>.generate(7, (i) => i + 1);

            var items = list.map((v) {
              final text = Text("${v}x");
              return DropdownMenuItem(
                  value: v,
                  child: teamData.flip
                      ? RotatedBox(quarterTurns: 2, child: text)
                      : text);
            }).toList();

            final button = DropdownButton<int>(
              key: const Key("dropdownFactor"),
              value: factor,
              onChanged: (value) => setState(() => factor = value!),
              items: items,
            );

            if (teamData.flip) {
              return RotatedBox(quarterTurns: 2, child: button);
            } else {
              return button;
            }
          }

          Widget getPlusMinusButton() {
            return Expanded(
                flex: 1,
                child: InkWell(
                  key: const Key("key_+/-"),
                  child: Container(
                      alignment: Alignment.centerRight,
                      child: Text(sign == 1 ? "+" : "-")),
                  onTap: () => setState(() => sign *= -1),
                ));
          }

          Widget getTextField() {
            return Expanded(
              flex: 3,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  ptsController.text,
                  textScaler: const TextScaler.linear(2),
                ),
              ),
            );
          }

          Widget getButton(String text, int value) {
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: InkWell(
                key: Key("key_$text"),
                onTap: () => setState(() => ptsController.set("$value")),
                child: Text(text),
              ),
            );
          }

          String getSummary() {
            return context.l10n.totalWithOpponent(
              pointsTeam(),
              pointsOtherTeam(),
            );
          }

          TextButton getAction(String text) {
            return TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(text),
              onPressed: () {
                final weis = (text == context.l10n.weis);
                var ptsOther = (weis) ? 0 : pointsOtherTeam();
                var pts = Points(pointsTeam(), ptsOther, teamId == 1);
                pts.weis = weis;
                Navigator.of(context).pop(pts);
              },
            );
          }

          Widget dialog() {
            return AlertDialog(
              title: Row(children: [
                Text(context.l10n.pointsOf(teamData.name)),
                Expanded(
                    child: InkWell(
                        key: const Key("flip"),
                        onTap: () =>
                            setState(() => teamData.flip = !teamData.flip),
                        child: const Icon(Icons.screen_rotation_outlined)))
              ]),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    getFactorWidget(),
                    getPlusMinusButton(),
                    getTextField(),
                    getButton("∅", 0),
                    getButton(context.l10n.match, matchPts),
                  ]),
                  Text(getSummary()),
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
                getAction(context.l10n.weis),
                getAction(context.l10n.ok),
              ],
            );
          }

          if (teamData.flip) {
            return RotatedBox(quarterTurns: 2, child: dialog());
          } else {
            return dialog();
          }
        });
      });
}
