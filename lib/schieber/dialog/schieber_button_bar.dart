import 'package:flutter/material.dart';

class SchieberButtonBar extends StatefulWidget {
  const SchieberButtonBar(this.onChanged, {super.key});

  final ValueChanged<int> onChanged;

  @override
  State<SchieberButtonBar> createState() => _SchieberButtonBarState();
}

class _SchieberButtonBarState extends State<SchieberButtonBar> {
  List<bool> selections = List.generate(7, (i) => i == 0);
  int selected = 0;
  final textScaler = const TextScaler.linear(1.2);

  List<int> factors = List.generate(7, (index) => index + 1);

  void select(int i) {
    if (i == selected) {
      i = 0;
    }
    selections[selected] = false;
    selections[i] = true;
    selected = i;
    widget.onChanged(factors[selected]);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth = MediaQuery.of(context).size.width * 0.08;

    List<Widget> buttons = [];
    for (int i = 1; i <= 7; i++) {
      buttons.add(Text("${i}x", textScaler: textScaler));
    }

    return ToggleButtons(
      isSelected: selections,
      onPressed: ((index) {
        select(index);
        setState(() {});
      }),
      constraints:
          BoxConstraints(minWidth: buttonWidth, minHeight: buttonWidth),
      fillColor: Theme.of(context).colorScheme.surface,
      children: buttons,
    );
  }
}
