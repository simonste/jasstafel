import 'package:flutter/material.dart';

// Wrapper for a row with optional top border

class CoiffeurRow extends Expanded {
  CoiffeurRow(cells, {super.key, topBorder = false})
      : super(child: _create(cells, topBorder));

  static _create(cells, topBorder) {
    if (topBorder) {
      return Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white))),
        child: _row(cells),
      );
    } else {
      return _row(cells);
    }
  }

  static _row(cells) {
    return Row(
      children: cells,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    );
  }
}
