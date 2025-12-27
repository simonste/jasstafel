import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

class MolotowWeis {
  String player;
  int points;

  MolotowWeis(this.player, this.points);
}

Future<MolotowWeis?> molotowWeisDialogBuilder(
  BuildContext context, {
  required List<String> playerNames,
  bool hand = false,
}) {
  return showDialog<MolotowWeis>(
    context: context,
    builder: (BuildContext context) {
      String? player;
      int factor = 1;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          var players = Expanded(
            child: RadioGroup<String>(
              groupValue: player,
              onChanged: (String? v) => setState(() => player = v),
              child: Column(
                children: playerNames
                    .map(
                      (element) =>
                          RadioListTile(title: Text(element), value: element),
                    )
                    .toList(),
              ),
            ),
          );

          var weis = SizedBox(
            child: Column(
              children: [20, 50, 100, 150, 200]
                  .map(
                    (e) => TextButton(
                      child: factor == 2 ? Text('2x $e') : Text('$e'),
                      onPressed: () => {
                        if (player != null)
                          Navigator.of(
                            context,
                          ).pop(MolotowWeis(player!, factor * e)),
                      },
                    ),
                  )
                  .toList(),
            ),
          );

          var title = hand
              ? Text(context.l10n.handWeis)
              : SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Text(context.l10n.tableWeis),
                      const Expanded(child: SizedBox.expand()),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => factor = factor % 2 + 1);
                          },
                          child: Text(
                            "2x",
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
                Row(children: [players, weis]),
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text(context.l10n.cancel),
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
