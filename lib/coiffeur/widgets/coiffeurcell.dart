import 'package:flutter/material.dart';

class CoiffeurCell extends Container {
  CoiffeurCell(
    String text, {
    super.key,
    textScaleFactor = 2.0,
    super.alignment = Alignment.center,
    super.decoration = const BoxDecoration(
      border: Border(
        left: BorderSide(
          color: Colors.white,
        ),
      ),
    ),
  }) : super(child: _createChild(text, textScaleFactor));

  static Widget _createChild(String name, double textScaleFactor) {
    return Text(
      name,
      textScaleFactor: textScaleFactor,
    );
  }
}

class CoiffeurPointsCell extends CoiffeurCell {
  CoiffeurPointsCell(int? pts, {super.key}) : super(_getString(pts));

  static String _getString(int? pts) {
    if (pts != null) {
      return pts.toString();
    }
    return "";
  }
}
