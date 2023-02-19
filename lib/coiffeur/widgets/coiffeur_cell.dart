import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';

class CoiffeurCell extends Expanded {
  final GestureTapCallback? onTap;

  CoiffeurCell(
    String text, {
    super.key,
    this.onTap,
    textScaleFactor = 1.8,
    leftBorder = true,
    scratch = false,
    highlight = false,
    alignment = Alignment.center,
    AutoSizeGroup? group,
  }) : super(
            child: _createChild(
          text,
          onTap,
          textScaleFactor,
          leftBorder,
          scratch,
          highlight,
          alignment,
          group,
        ));

  static BoxDecoration decoration(
    bool leftBorder,
    bool highlight,
    bool scratch,
  ) {
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
          color: highlight ? Colors.blue.shade600 : null,
        );
      }

      return BoxDecoration(
        border: border,
        color: highlight ? Colors.blue.shade600 : null,
      );
    }
    return const BoxDecoration();
  }

  static Widget _createChild(
    String name,
    onTap,
    textScaleFactor,
    bool leftBorder,
    bool scratch,
    bool highlight,
    Alignment alignment,
    AutoSizeGroup? group,
  ) {
    if (onTap != null) {
      return InkWell(
          onTap: onTap,
          child: Container(
              alignment: alignment,
              decoration: decoration(leftBorder, highlight, scratch),
              child: AutoSizeText(name,
                  maxLines: 2,
                  textScaleFactor: textScaleFactor,
                  group: group)));
    } else {
      return Container(
          alignment: alignment,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: decoration(leftBorder, highlight, scratch),
          child: AutoSizeText(
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
      {super.key,
      super.onTap,
      super.textScaleFactor,
      super.leftBorder,
      super.highlight,
      super.alignment})
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
