import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';

class MolotowStatisticsButton extends IconButton {
  MolotowStatisticsButton(BuildContext context, data)
      : super(
            key: const Key('statistics'),
            onPressed: () {
              dialogBuilder(context, data);
            },
            icon: const Icon(Icons.bar_chart));
}

enum RowType { bold, normal }

Future<void> dialogBuilder(
    BuildContext context, BoardData<MolotowSettings, MolotowScore> data) {
  return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            row(List<String> strings, {RowType rowType = RowType.normal}) {
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

              return Row(
                  children: strings
                      .mapIndexed((i, e) => text(e, key: Key("${i}_1")))
                      .toList());
            }

            List<Widget> children = [
              Text(data.common.timestamps.elapsed(context)),
              const Divider()
            ];
            children.add(row([
              "",
              context.l10n.handWeis,
              context.l10n.tableWeis,
              context.l10n.tricks
            ]));

            for (var p = 0; p < data.settings.players; p++) {
              final hw = data.score.handWeis(p);
              final tw = data.score.tableWeis(p);
              final tricks = data.score.total(p) - hw - tw;
              children.add(
                  row([data.score.playerName[p], '$hw', '$tw', '$tricks']));
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
