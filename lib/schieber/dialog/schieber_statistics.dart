import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';

class SchieberStatisticsButton extends IconButton {
  SchieberStatisticsButton(BuildContext context, data)
      : super(
            key: const Key('statistics'),
            onPressed: () {
              dialogBuilder(context, data);
            },
            icon: const Icon(Icons.bar_chart));
}

enum RowType { bold, normal }

Future<void> dialogBuilder(
    BuildContext context, BoardData<SchieberSettings, SchieberScore> data) {
  return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            row(String left, String right, String title,
                {RowType rowType = RowType.normal}) {
              var fontWeight =
                  rowType == RowType.bold ? FontWeight.w400 : FontWeight.w100;

              text(String string, {Key? key}) {
                return Expanded(
                    child: Text(
                  key: key,
                  string,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: fontWeight),
                ));
              }

              return Row(children: [
                text(left, key: Key("${title}_1")),
                text(title),
                text(right, key: Key("${title}_2"))
              ]);
            }

            dataRow(List<int> pts, String title) {
              return row("${pts[0]}", "${pts[1]}", title);
            }

            List<Widget> children = [
              Text(data.common.timestamps.elapsed(context)),
              const Divider()
            ];
            children.add(row(
                data.score.team[0].name, data.score.team[1].name, "",
                rowType: RowType.bold));
            children.add(const Divider());

            var matches = data.score.matches();
            var weis = data.score.weisPoints();
            var total = [data.score.team[0].sum(), data.score.team[1].sum()];
            var tricks = [total[0] - weis[0], total[1] - weis[1]];
            var hill = [
              data.score.team[0].hill == true ? 1 : 0,
              data.score.team[1].hill == true ? 1 : 0
            ];
            var win = [
              data.score.team[0].win == true ? 1 : 0,
              data.score.team[1].win == true ? 1 : 0
            ];
            children.add(dataRow(matches, context.l10n.matches));
            children.add(dataRow(weis, context.l10n.weis));
            children.add(dataRow(tricks, context.l10n.tricks));
            children.add(dataRow(total, context.l10n.total));
            children.add(row(hill[0] == 1 ? "✓" : "", hill[1] == 1 ? "✓" : "",
                context.l10n.hill));
            children.add(row(win[0] == 1 ? "✓" : "", win[1] == 1 ? "✓" : "",
                context.l10n.win));

            children.add(const Divider());
            children.add(Text(context.l10n.total));

            children.add(Text(context.l10n.duration(
                data.score.statistics.duration +
                    (data.common.timestamps.duration() ?? 0))));

            children.add(dataRow([
              data.score.statistics.team[0].matches + matches[0],
              data.score.statistics.team[1].matches + matches[1]
            ], context.l10n.matches));
            children.add(dataRow([
              data.score.statistics.team[0].weis + weis[0],
              data.score.statistics.team[1].weis + weis[1]
            ], context.l10n.weis));
            children.add(dataRow([
              data.score.statistics.team[0].pts +
                  total[0] -
                  data.score.statistics.team[0].weis -
                  weis[0],
              data.score.statistics.team[1].pts +
                  total[1] -
                  data.score.statistics.team[1].weis -
                  weis[1]
            ], context.l10n.tricks));
            children.add(dataRow([
              data.score.statistics.team[0].pts + total[0],
              data.score.statistics.team[1].pts + total[1]
            ], context.l10n.total));
            children.add(dataRow([
              data.score.statistics.team[0].hills + hill[0],
              data.score.statistics.team[1].hills + hill[1]
            ], context.l10n.hill));
            children.add(dataRow([
              data.score.statistics.team[0].wins + win[0],
              data.score.statistics.team[1].wins + win[1]
            ], context.l10n.wins));

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
