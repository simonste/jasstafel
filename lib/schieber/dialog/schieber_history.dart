import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/schieber/data/schieber_data.dart';

class SchieberHistoryButton extends IconButton {
  SchieberHistoryButton(BuildContext context, SchieberData data, {super.key})
      : super(
            onPressed: () {
              dialogBuilder(context, data);
            },
            icon: const Icon(Icons.history));
}

Future<void> dialogBuilder(BuildContext context, SchieberData data) {
  var rounds = data.getHistory();
  return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<Widget> children = [
              //  Text(context.l10n.noOfRounds(rounds.length))
            ];

            children.add(Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                  child: Text(
                data.team[0].name,
              )),
              Expanded(child: Text(data.team[1].name)),
            ]));

            for (var round in rounds) {
              children.add(Text("${round.pts[0]}  ${round.pts[1]}"));
            }

            return AlertDialog(
              title: Text(context.l10n.schieber),
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
