import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_score.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_values.dart';
import 'package:numberpicker/numberpicker.dart';

class GuggitalerRound {
  String player = "";
  List<int?> points = List.filled(GuggitalerValues.length, null);

  GuggitalerRound();

  int sum() {
    int sum = 0;
    for (var i = 0; i < GuggitalerValues.length; i++) {
      sum += (points[i] ?? 0) * GuggitalerValues.points(i);
    }
    return sum;
  }
}

Future<GuggitalerRound?> guggitalerDialogBuilder(
  BuildContext context, {
  required List<String> playerNames,
  required GuggitalerRow? row,
}) {
  return showDialog<GuggitalerRound>(
    context: context,
    builder: (BuildContext context) {
      int factor = 1;

      var round = GuggitalerRound();

      loadPlayer(int i) {
        round.player = playerNames[i];
        if (row != null) {
          for (var r = 0; r < row.pts[i].length; r++) {
            if (row.pts[i][r] != null) {
              round.points[r] = row.pts[i][r]!.abs();
              if (row.pts[i][r]! < 0) {
                factor = -1;
              }
            } else {
              round.points[r] = null;
            }
          }
        }
      }

      if (row != null) {
        for (var i = 0; i < playerNames.length; i++) {
          if (row.sum(i) != 0) {
            loadPlayer(i);
            break;
          }
        }
      }

      final autoSizeGroupPlayer = AutoSizeGroup();
      final autoSizeGroupCategory = AutoSizeGroup();
      final screenSize = MediaQuery.of(context).size;
      final landscape = screenSize.width > screenSize.height;
      final playersPerRow = landscape ? 4 : 2;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          List<Widget> rows = [];

          appendPlayer(String player) {
            if (rows.isEmpty ||
                (rows.last as Row).children.length == playersPerRow) {
              // ignore: prefer_const_constructors, prefer_const_literals_to_create_immutables
              rows.add(Row(children: []));
            }

            var lr = (rows.last as Row);
            lr.children.add(
              Expanded(
                child: RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  title: SizedBox(
                    width: 500,
                    height: 50,
                    child: AutoSizeText(
                      player,
                      textAlign: TextAlign.left,
                      group: autoSizeGroupPlayer,
                    ),
                  ),
                  value: player,
                  groupValue: round.player,
                  onChanged: (String? v) =>
                      setState(() => loadPlayer(playerNames.indexOf(player))),
                ),
              ),
            );
          }

          for (var player in playerNames) {
            appendPlayer(player);
          }

          var players = SizedBox(child: Column(children: rows));

          final cols = Row(
            children: List.generate(GuggitalerValues.length, (i) => i)
                .map(
                  (e) => Expanded(
                    child: SizedBox(
                      width: 1000,
                      height: 30,
                      child: AutoSizeText(
                        GuggitalerValues.type(e, context),
                        maxLines: 2,
                        wrapWords: false,
                        group: autoSizeGroupCategory,
                      ),
                    ),
                  ),
                )
                .toList(),
          );

          slot(int i) {
            return Expanded(
              child: NumberPicker(
                key: Key("picker_$i"),
                value: round.points[i] ?? 0,
                minValue: 0,
                maxValue: GuggitalerValues.maxPerRound(i),
                itemHeight: 30,
                onChanged: (v) => setState(() => round.points[i] = v),
              ),
            );
          }

          List<Widget> slots = [];
          for (var i = 0; i < GuggitalerValues.length; i++) {
            slots.add(slot(i));
          }

          var title = SizedBox(
            height: 32,
            child: Row(
              children: [
                Text(context.l10n.addRound),
                const Expanded(child: SizedBox.expand()),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => factor *= -1);
                    },
                    child: Text(
                      "+/-",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: factor == 1
                            ? null
                            : Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          return AlertDialog(
            title: title,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                players,
                const Divider(),
                cols,
                SizedBox(child: Row(children: slots)),
                const Divider(),
                SizedBox(
                  key: const Key('summary'),
                  child: Text(context.l10n.totalPoints(factor * round.sum())),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text(context.l10n.cancel),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text(context.l10n.ok),
                onPressed: () {
                  if (round.player.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.selectPlayer)),
                    );
                  } else {
                    round.points = round.points.map((e) {
                      return e != null ? factor * e : e;
                    }).toList();
                    Navigator.of(context).pop(round);
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}
