import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';

class CoiffeurCell extends StatelessWidget {
  final String text;
  final GestureTapCallback? onTap;
  final double textScaleFactor;
  final bool leftBorder;
  final bool scratch;
  final bool highlight;
  final Alignment alignment;
  final AutoSizeGroup? group;

  const CoiffeurCell(
    this.text, {
    super.key,
    this.onTap,
    this.textScaleFactor = 1.8,
    this.leftBorder = true,
    this.scratch = false,
    this.highlight = false,
    this.alignment = Alignment.center,
    this.group,
  });

  @override
  Widget build(BuildContext context) {
    double scaleFactor = 1.0;
    if (context.findRenderObject() != null) {
      final cellSize = (context.findRenderObject() as RenderBox).size;
      scaleFactor = max(cellSize.height / 50, cellSize.width / 100);
    }

    return Expanded(
        child: _createChild(
      text,
      onTap,
      textScaleFactor * scaleFactor,
      leftBorder,
      scratch,
      highlight,
      alignment,
      group,
    ));
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
                  textAlign: TextAlign.center,
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
