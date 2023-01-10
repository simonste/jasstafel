import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/schieber/data/schieber_data.dart';

class Points {
  int points1;
  int points2;

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

Future<Points?> schieberDialogBuilder(
    BuildContext context, int teamId, int ppr, TeamData teamData) {
  int factor = 1;

  return showDialog<Points>(
      context: context,
      builder: (BuildContext context) {
        var ptsController = PointsController();

        pointsTeam() {
          return ptsController.getPoints() * factor;
        }

        pointsOtherTeam() {
          return (ppr - ptsController.getPoints()) * factor;
        }

        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          TableRow createRow(i) {
            Widget cell(n) {
              if (n == 10) {
                return const SizedBox.shrink();
              }

              final String number = (n == 12)
                  ? "←"
                  : (n == 11)
                      ? "0"
                      : "$n";

              return InkWell(
                  onTap: () => setState(() {
                        if (number == "←") {
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
            var list = List<int>.generate(7, (i) => i + 1);
            return DropdownButton<int>(
              key: const Key("dropdownFactor"),
              value: factor,
              onChanged: (value) => setState(() => factor = value!),
              items: list.map((v) {
                return DropdownMenuItem(
                  value: v,
                  child: Text("${v}x"),
                );
              }).toList(),
            );
          }

          Widget getTextField() {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  ptsController.text,
                  textScaleFactor: 2,
                ),
              ),
            );
          }

          Widget getButton(String text, int value) {
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: InkWell(
                onTap: () => setState(() => ptsController.set("$value")),
                child: Text(text),
              ),
            );
          }

          String getSummary() {
            if (pointsOtherTeam() > 0) {
              return context.l10n
                  .totalWithOpponent(pointsTeam(), pointsOtherTeam());
            }
            return context.l10n.totalPoints(pointsTeam());
          }

          TextButton getAction(String text) {
            return TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(text),
              onPressed: () {
                var ptsOther =
                    (text == context.l10n.weis) ? 0 : pointsOtherTeam();
                var pts = Points(pointsTeam(), ptsOther, teamId == 1);
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
                    getTextField(),
                    getButton("∅", 0),
                    getButton(context.l10n.match, ppr),
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
