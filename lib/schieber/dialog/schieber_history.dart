import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/schieber/data/schieber_data.dart';

class SchieberHistoryButton extends IconButton {
  SchieberHistoryButton(
      BuildContext context, SchieberData data, Function undoLast,
      {super.key})
      : super(
            onPressed: () {
              dialogBuilder(context, data, undoLast);
            },
            icon: const Icon(Icons.history));
}

enum RowType { bold, normal }

Future<void> dialogBuilder(
    BuildContext context, SchieberData data, Function undoLast) {
  var rounds = data.getHistory();
  return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            row(String left, String right,
                {RowType rowType = RowType.normal, bool delete = false}) {
              var fontWeight =
                  rowType == RowType.bold ? FontWeight.w400 : FontWeight.w100;
              var space = delete
                  ? SizedBox(
                      width: 50,
                      child: IconButton(
                          onPressed: () => setState(() => undoLast()),
                          icon: const Icon(Icons.delete)),
                    )
                  : const SizedBox(width: 50);

              return Row(children: [
                Expanded(
                  child: Text(
                    left,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: fontWeight),
                  ),
                ),
                space,
                Expanded(
                  child: Text(
                    right,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: fontWeight),
                  ),
                )
              ]);
            }

            List<Widget> children = [];

            children.add(row(data.team[0].name, data.team[1].name,
                rowType: RowType.bold));
            children.add(const Divider());

            for (var round in rounds.reversed) {
              children.add(row("${round.pts[0]}", "${round.pts[1]}",
                  delete: round == rounds.last,
                  rowType: round.isRound(data.settings.match)
                      ? RowType.bold
                      : RowType.normal));
            }

            return AlertDialog(
              title: Text(context.l10n.currentRound),
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
