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

  List<int?> points = [null, -1, 0, 1, 2, 3];
  List<Widget> buttons = [
    const Text("x"),
    const Text("-1"),
    const Text("0"),
    const Text("1"),
    const Text("2"),
    const Text("3")
  ];

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

    return ToggleButtons(
      isSelected: selections,
      onPressed: ((index) {
        select(index);
        setState(() {});
      }),
      constraints:
          BoxConstraints(minWidth: buttonWidth, minHeight: buttonWidth),
      fillColor: Colors.blue,
      children: buttons,
    );
  }
}
