import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/schlaeger/dialog/schlaeger_button_bar.dart';

Future<List<int?>?> schlaegerDialogBuilder(BuildContext context,
    {required List<String> playerNames,
    required int pointsPerRound,
    List<int?>? previousPts,
    Widget? title}) {
  if (previousPts != null && title == null) {
    title = Text(context.l10n.roundEdit);
  }
  title ??= Text(context.l10n.addRound);

  return showDialog<List<int?>?>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          List<int?> points = List.generate(playerNames.length, (_) => null);

          var columns = <Widget>[];
          for (var i = 0; i < playerNames.length; i++) {
            columns.add(Text(playerNames[i]));
            columns.add(SizedBox(
              child: SchlaegerButtonBar(
                (int? p) => points[i] = p,
                previousPoints: previousPts?[i],
                key: Key("pts_$i"),
              ),
            ));
          }

          return AlertDialog(
            title: title,
            content: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: columns)),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text(context.l10n.cancel),
                onPressed: () => Navigator.of(context).pop(null),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text(context.l10n.ok),
                onPressed: () => {Navigator.of(context).pop(points)},
              ),
            ],
          );
        });
      });
}
