import 'package:flutter/material.dart';

List<Widget> rowContainer(String name) {
  return [SizedBox(width: 20, child: Text(name, textAlign: TextAlign.right))];
}

Text defaultCell(String data, {double textScaleFactor = 2, Key? key}) {
  return Text(
    data,
    key: key,
    textAlign: TextAlign.center,
    textScaler: TextScaler.linear(textScaleFactor),
  );
}

BoxDecoration rowDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.tertiary,
    border: Border(
      bottom: BorderSide(color: Theme.of(context).colorScheme.onPrimary),
    ),
  );
}

rowHeader({
  required List<String> playerNames,
  required int players,
  required Function headerFunction,
  required BuildContext context,
  bool hideRoundColumn = false,
}) {
  List<String> list = [''];
  playerNames.sublist(0, players).forEach((e) {
    list.add(e);
  });

  List<Widget> children = rowContainer(list[0]);
  if (hideRoundColumn) {
    children.clear();
  }
  for (var i = 1; i < list.length; i++) {
    children.add(
      Expanded(
        child: InkWell(
          onTap: () => headerFunction(i - 1),
          child: defaultCell(list[i], textScaleFactor: 1),
        ),
      ),
    );
  }
  return Container(
    height: 30,
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary),
    child: Row(children: children),
  );
}

rowFooter(List<String> data, {required BuildContext context}) {
  List<Widget> children = rowContainer(data[0]);
  for (var i = 1; i < data.length; i++) {
    children.add(
      Expanded(
        child: InkWell(child: defaultCell(data[i], key: Key('sum_${i - 1}'))),
      ),
    );
  }
  return Container(
    height: 40,
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary),
    child: Row(children: children),
  );
}

defaultRow(
  List<String> data, {
  int? rowNo,
  isRound = true,
  required BuildContext context,
  required Function pointsFunction,
}) {
  List<Widget> children = rowContainer(data[0]);

  for (var i = 1; i < data.length; i++) {
    children.add(
      Expanded(
        child: InkWell(
          onLongPress: () => pointsFunction(editRowNo: rowNo!),
          child: defaultCell(data[i]),
        ),
      ),
    );
  }
  var decoration = isRound ? rowDecoration(context) : null;
  return Container(
    decoration: decoration,
    child: Row(children: children),
  );
}
