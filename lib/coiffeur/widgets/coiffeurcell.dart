import 'package:flutter/material.dart';

class CoiffeurCell extends Expanded {
  final GestureTapCallback? onTap;

  CoiffeurCell(
    String text, {
    super.key,
    this.onTap,
    textScaleFactor = 2.0,
    leftBorder = true,
  }) : super(child: _createChild(text, onTap, textScaleFactor, leftBorder));

  static BoxDecoration border(leftBorder) {
    if (leftBorder) {
      return const BoxDecoration(
          border: Border(
        left: BorderSide(
          color: Colors.white,
        ),
      ));
    }
    return const BoxDecoration();
  }

  static Widget _createChild(String name, onTap, textScaleFactor, leftBorder) {
    if (onTap != null) {
      return InkWell(
          onTap: onTap,
          child: Container(
              alignment: Alignment.center,
              decoration: border(leftBorder),
              child: Text(
                name,
                textScaleFactor: textScaleFactor,
              )));
    } else {
      return Container(
          alignment: Alignment.center,
          decoration: border(leftBorder),
          child: Text(
            name,
            textScaleFactor: textScaleFactor,
          ));
    }
  }
}

class CoiffeurPointsCell extends CoiffeurCell {
  CoiffeurPointsCell(int? pts,
      {bool match = false,
      super.key,
      super.onTap,
      super.textScaleFactor,
      super.leftBorder})
      : super(_getString(pts, match));

  static String _getString(int? pts, bool match) {
    if (match) {
      return "MATCH";
    }
    if (pts != null) {
      return pts.toString();
    }
    return "";
  }
}
