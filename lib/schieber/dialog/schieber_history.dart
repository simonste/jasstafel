import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';

class SchieberHistoryButton extends IconButton {
  SchieberHistoryButton(BuildContext context, data, Function undoLast)
    : super(
        key: const Key('history'),
        onPressed: () {
          dialogBuilder(context, data, undoLast);
        },
        icon: const Icon(Icons.history),
      );
}

enum RowType { bold, normal }

Future<void> dialogBuilder(
  BuildContext context,
  BoardData<SchieberSettings, SchieberScore> data,
  Function undoLast,
) {
  var rounds = data.score.getHistory();
  return showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          row(
            String left,
            String right, {
            RowType rowType = RowType.normal,
            bool delete = false,
          }) {
            var fontWeight = rowType == RowType.bold
                ? FontWeight.w400
                : FontWeight.w100;
            var space = delete
                ? SizedBox(
                    width: 50,
                    child: IconButton(
                      onPressed: () => setState(() => undoLast()),
                      icon: const Icon(Icons.delete),
                    ),
                  )
                : const SizedBox(width: 50);
            text(String string) {
              return Expanded(
                child: Text(
                  string,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: fontWeight),
                ),
              );
            }

            return Row(children: [text(left), space, text(right)]);
          }

          List<Widget> children = [
            Text(data.common.timestamps.elapsed(context)),
            const Divider(),
          ];
          children.add(
            row(
              data.score.team[0].name,
              data.score.team[1].name,
              rowType: RowType.bold,
            ),
          );
          children.add(const Divider());

          var rows = <Widget>[];
          for (var round in rounds.reversed) {
            rows.add(
              row(
                "${round.pts[0]}",
                "${round.pts[1]}",
                delete: round == rounds.last,
                rowType:
                    round.isRound(
                      data.settings.match,
                      data.settings.pointsPerRound,
                    )
                    ? RowType.bold
                    : RowType.normal,
              ),
            );
          }
          children.add(
            Expanded(
              child: SingleChildScrollView(child: Column(children: rows)),
            ),
          );

          return AlertDialog(
            title: Text(context.l10n.currentRound),
            content: Column(mainAxisSize: MainAxisSize.min, children: children),
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
    },
  );
}
