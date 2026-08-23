import 'package:flutter/material.dart';

// Wrapper for a row with optional top border

class CoiffeurRow extends StatelessWidget {
  final List<Widget> cells;
  final bool topBorder;

  const CoiffeurRow(this.cells, {super.key, this.topBorder = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.onSurface;

    if (topBorder) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: _row(cells),
        ),
      );
    } else {
      return Expanded(child: _row(cells));
    }
  }

  static Widget _row(cells) {
    return Row(
      children: cells,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    );
  }
}
