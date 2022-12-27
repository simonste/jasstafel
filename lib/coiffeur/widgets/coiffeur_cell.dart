import 'package:flutter/material.dart';

class CoiffeurCell extends Expanded {
  final GestureTapCallback? onTap;

  CoiffeurCell(
    String text, {
    super.key,
    this.onTap,
    textScaleFactor = 2.0,
    leftBorder = true,
    scratch = false,
  }) : super(
            child: _createChild(
                text, onTap, textScaleFactor, leftBorder, scratch));

  static BoxDecoration border(leftBorder, scratch) {
    if (leftBorder) {
      var border = const Border(
          left: BorderSide(
        color: Colors.white,
      ));

      if (scratch) {
        return BoxDecoration(
          image: const DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage("assets/images/scratch.png"),
          ),
          border: border,
        );
      }

      return BoxDecoration(
        border: border,
      );
    }
    return const BoxDecoration();
  }

  static Widget _createChild(
      String name, onTap, textScaleFactor, leftBorder, scratch) {
    if (onTap != null) {
      return InkWell(
          onTap: onTap,
          child: Container(
              alignment: Alignment.center,
              decoration: border(leftBorder, scratch),
              child: Text(
                name,
                textScaleFactor: textScaleFactor,
              )));
    } else {
      return Container(
          alignment: Alignment.center,
          decoration: border(leftBorder, scratch),
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
      bool scratch = false,
      super.key,
      super.onTap,
      super.textScaleFactor,
      super.leftBorder})
      : super(_getString(pts, match, scratch), scratch: scratch);

  static String _getString(int? pts, bool match, bool scratch) {
    if (scratch) {
      return "";
    }
    if (match) {
      return "MATCH";
    }
    if (pts != null) {
      return pts.toString();
    }
    return "";
  }
}
