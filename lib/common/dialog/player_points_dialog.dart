import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';

Future<List<int?>?> playerPointsDialogBuilder(BuildContext context,
    {required List<String> playerNames,
    required int pointsPerRound,
    bool rounded = false,
    List<int?>? previousPts,
    Widget? title}) {
  if (previousPts != null && title == null) {
    title = Text(context.l10n.roundEdit);
  }
  title ??= Text(context.l10n.addRound);

  List<TextEditingController> controllers = [];
  List<FocusNode> focusNodes = [];
  for (var i = 0; i < playerNames.length; i++) {
    controllers.add(TextEditingController());
    focusNodes.add(FocusNode());
  }

  int previousTotal = pointsPerRound;
  if (previousPts != null) {
    previousTotal = 0;
    for (var i = 0; i < controllers.length; i++) {
      if (previousPts[i] != null) {
        controllers[i].text = "${previousPts[i]}";
        previousTotal += previousPts[i]!;
      }
    }
  }

  return showDialog<List<int?>?>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          int total = 0;
          List<int?> points = [];
          int noOfEmpty = 0;
          for (var i = 0; i < controllers.length; i++) {
            try {
              final pt = int.parse(controllers[i].text);
              total += pt;
              points.add(pt);
            } on FormatException {
              noOfEmpty++;
              points.add(null);
            }
          }
          var remainingPts = pointsPerRound - total;

          fillRemaining() {
            for (var i = 0; i < controllers.length; i++) {
              if (points[i] == null) {
                points[i] = remainingPts;
                controllers[i].text = "$remainingPts";
              }
            }
            total = pointsPerRound;
            noOfEmpty = 0;
            remainingPts = 0;
          }

          if (remainingPts == 0) {
            fillRemaining();
          }

          var columns = <Widget>[];
          for (var i = 0; i < playerNames.length; i++) {
            var elements = <Widget>[
              Expanded(child: Text(playerNames[i])),
              SizedBox(
                  width: 60,
                  child: Focus(
                    child: TextField(
                      key: Key("pts_$i"),
                      decoration:
                          InputDecoration(hintText: context.l10n.points),
                      autofocus: true,
                      focusNode: focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      controller: controllers[i],
                      onChanged: (value) => setState(() {}),
                      onSubmitted: (v) => FocusScope.of(context).requestFocus(
                          focusNodes[(i + 1) % playerNames.length]),
                    ),
                    onFocusChange: (value) => {
                      if (value && noOfEmpty == 1)
                        setState(() {
                          fillRemaining();
                        })
                    },
                  ))
            ];
            if (rounded) {
              elements.add(SizedBox(
                width: 20,
                child: Text(
                  "${roundedInt(points[i] ?? 0, rounded)}",
                  textAlign: TextAlign.right,
                ),
              ));
            }
            columns.add(SizedBox(child: Row(children: elements)));
          }

          if (previousTotal == pointsPerRound) {
            columns.add(const Divider());
            columns.add(SizedBox(
                key: const Key('remainingPoints'),
                child:
                    Text(context.l10n.remainingPoints(total, remainingPts))));
          }
          return AlertDialog(
            title: title,
            content: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: columns),
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
                onPressed: () => {
                  if (noOfEmpty == 0 || previousPts != null)
                    {Navigator.of(context).pop(points)}
                },
              ),
            ],
          );
        });
      });
}
