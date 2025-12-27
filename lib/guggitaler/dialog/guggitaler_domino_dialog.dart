import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

Future<List<int?>?> guggitalerDominoDialogBuilder(
  BuildContext context, {
  required List<String> playerNames,
  List<int?>? previousPts,
  required String dominoPoints,
  Widget? title,
}) {
  if (previousPts != null && title == null) {
    title = Text(context.l10n.roundEdit);
  }
  title ??= Text(context.l10n.addDominoRound);

  List<TextEditingController> controllers = [];
  List<FocusNode> focusNodes = [];
  for (var i = 0; i < playerNames.length; i++) {
    controllers.add(TextEditingController());
    focusNodes.add(FocusNode());
  }

  if (previousPts != null) {
    for (var i = 0; i < controllers.length; i++) {
      if (previousPts[i] != null) {
        controllers[i].text = "${previousPts[i]}";
      }
    }
  }

  int rankPoints(int rank) {
    final points = dominoPoints
        .split(",")
        .map((e) => int.parse(e.trim()))
        .toList();
    if (rank > 0 && rank <= points.length) {
      return -points[rank - 1];
    }
    return 0;
  }

  return showDialog<List<int?>?>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          List<int?> points = [];
          int noOfEmpty = 0;
          for (var i = 0; i < controllers.length; i++) {
            try {
              final pt = int.parse(controllers[i].text);
              points.add(pt);
            } on FormatException {
              noOfEmpty++;
              points.add(null);
            }
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
                    decoration: InputDecoration(hintText: context.l10n.points),
                    autofocus: false,
                    focusNode: focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    controller: controllers[i],
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (v) => FocusScope.of(
                      context,
                    ).requestFocus(focusNodes[(i + 1) % playerNames.length]),
                  ),
                  onFocusChange: (value) => {
                    if (value)
                      setState(() {
                        if (points[i] == null) {
                          noOfEmpty--;
                          points[i] = rankPoints(
                            playerNames.length - noOfEmpty,
                          );
                          controllers[i].text = "${points[i]}";
                        }
                      }),
                  },
                ),
              ),
            ];
            columns.add(SizedBox(child: Row(children: elements)));
          }

          return AlertDialog(
            title: title,
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: columns,
              ),
            ),
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
                    {Navigator.of(context).pop(points)},
                },
              ),
            ],
          );
        },
      );
    },
  );
}
