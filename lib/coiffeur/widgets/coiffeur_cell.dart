import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';

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
  CoiffeurPointsCell(CoiffeurPoints pts,
      {super.key, super.onTap, super.textScaleFactor, super.leftBorder})
      : super(_getString(pts), scratch: pts.scratched);

  CoiffeurPointsCell.number(int? pts,
      {super.key, super.onTap, super.textScaleFactor, super.leftBorder})
      : super(_getNumberString(pts));

  static String _getNumberString(int? pts) {
    if (pts != null) {
      return pts.toString();
    }
    return "";
  }

  static String _getString(CoiffeurPoints pts) {
    if (pts.scratched) {
      return "";
    }
    if (pts.match) {
      return "MATCH";
    }
    return _getNumberString(pts.pts);
  }
}
