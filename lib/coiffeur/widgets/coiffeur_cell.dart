import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';

class CoiffeurCell extends StatelessWidget {
  final String text;
  final GestureTapCallback? onTap;
  final int maxLines;
  final bool leftBorder;
  final bool scratch;
  final bool highlight;
  final Alignment alignment;
  final AutoSizeGroup? group;

  const CoiffeurCell(
    this.text, {
    super.key,
    this.onTap,
    this.maxLines = 1,
    this.leftBorder = true,
    this.scratch = false,
    this.highlight = false,
    this.alignment = Alignment.center,
    this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: _createChild(
      text,
      onTap,
      maxLines,
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
    int maxLines,
    bool leftBorder,
    bool scratch,
    bool highlight,
    Alignment alignment,
    AutoSizeGroup? group,
  ) {
    final container = Container(
        alignment: alignment,
        decoration: decoration(leftBorder, highlight, scratch),
        padding: const EdgeInsets.all(10),
        child: AutoSizeText(
          name,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 1000),
          textAlign: TextAlign.center,
          group: group,
        ));

    if (onTap != null) {
      return InkWell(onTap: onTap, child: container);
    } else {
      return container;
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
      {super.key, super.onTap, super.leftBorder, AutoSizeGroup? group})
      : super(_getString(pts), scratch: pts.scratched, group: group);

  CoiffeurPointsCell.number(int? pts,
      {super.key,
      super.onTap,
      super.leftBorder,
      super.highlight,
      super.alignment,
      super.group})
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
