import 'package:flutter/material.dart';

class SchlaegerButtonBar extends StatefulWidget {
  const SchlaegerButtonBar(this.onChanged, {this.previousPoints, super.key});

  final ValueChanged<int?> onChanged;
  final int? previousPoints;

  @override
  State<SchlaegerButtonBar> createState() => _SchlaegerButtonBarState();
}

class _SchlaegerButtonBarState extends State<SchlaegerButtonBar> {
  List<bool> selections = List.generate(6, (i) => i == 0);
  int selected = 0;
  final textScaler = const TextScaler.linear(1.5);

  List<int?> points = [null, -1, 0, 1, 2, 3];

  void select(int i) {
    if (i == selected) {
      i = 0;
    }
    selections[selected] = false;
    selections[i] = true;
    selected = i;
    widget.onChanged(points[selected]);
  }

  @override
  void initState() {
    super.initState();
    if (widget.previousPoints != null) {
      select(points.indexOf(widget.previousPoints));
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth = MediaQuery.of(context).size.width * 0.1;

    List<Widget> buttons = [
      Text("x", textScaler: textScaler),
      Text("-1", textScaler: textScaler),
      Text("0", textScaler: textScaler),
      Text("1", textScaler: textScaler),
      Text("2", textScaler: textScaler),
      Text("3", textScaler: textScaler),
    ];

    return ToggleButtons(
      isSelected: selections,
      onPressed: ((index) {
        select(index);
        setState(() {});
      }),
      constraints: BoxConstraints(
        minWidth: buttonWidth,
        minHeight: buttonWidth,
      ),
      fillColor: Theme.of(context).colorScheme.primary,
      selectedColor: Theme.of(context).colorScheme.onPrimary,
      children: buttons,
    );
  }
}
