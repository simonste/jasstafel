import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/differenzler/data/differenzler_score.dart';
import 'package:jasstafel/settings/differenzler_settings.g.dart';

class DifferenzlerStatisticsButton extends IconButton {
  DifferenzlerStatisticsButton(BuildContext context, data)
      : super(
            key: const Key('statistics'),
            onPressed: () {
              dialogBuilder(context, data);
            },
            icon: const Icon(Icons.bar_chart));
}

enum RowType { bold, normal }

Future<void> dialogBuilder(BuildContext context,
    BoardData<DifferenzlerSettings, DifferenzlerScore> data) {
  return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            var nameGroup = AutoSizeGroup();

            row(List<String> strings, {RowType rowType = RowType.normal}) {
              var group = AutoSizeGroup();
              text(String string, {Key? key, required bool first}) {
                return Expanded(
                    child: SizedBox(
                        width: 1000,
                        height: 30,
                        child: AutoSizeText(
                          key: key,
                          string,
                          maxLines: 1,
                          textAlign: first ? TextAlign.left : TextAlign.center,
                          group: first ? nameGroup : group,
                        )));
              }

              return Row(
                  children: strings
                      .mapIndexed((i, e) => text(
                            e,
                            key: Key("${i}_1"),
                            first: (i == 0),
                          ))
                      .toList());
            }

            List<Widget> children = [
              Text(data.common.timestamps.elapsed(context)),
              const Divider()
            ];
            children.add(row([
              "",
              context.l10n.avgGuess,
              context.l10n.zeroGuess,
              context.l10n.zeroDiff,
              context.l10n.avgPoints,
            ]));

            var avgGuess = 0.0;
            for (var p = 0; p < data.settings.players; p++) {
              final gu = data.score.avgGuessed(p);
              var zeroGuessed = 0;
              var zeroDiff = 0;
              for (final row in data.score.rows) {
                if (row.isPlayed()) {
                  zeroGuessed += (row.guesses[p] == 0) ? 1 : 0;
                  zeroDiff += (row.diff(p) == 0) ? 1 : 0;
                }
              }

              final pts = data.score.avgPoints(p);
              children.add(row([
                data.score.playerName[p],
                '$gu',
                '$zeroGuessed',
                '$zeroDiff',
                '$pts'
              ]));
              avgGuess += gu;
            }

            if (data.score.rows.first.isPlayed()) {
              children.add(const Divider());
              children
                  .add(Text(context.l10n.avgRoundGuess((avgGuess).round())));
            }

            return AlertDialog(
              title: Text(context.l10n.stats),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: Text(context.l10n.ok),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      });
}
