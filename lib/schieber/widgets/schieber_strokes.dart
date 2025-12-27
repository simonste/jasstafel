import 'package:flutter/material.dart';

enum StrokeType { I, X, V }

class SchieberStrokes extends StatelessWidget {
  final StrokeType type;
  final int strokes;
  final bool shaded;
  final double widthFactor;

  const SchieberStrokes(
    this.type,
    this.strokes, {
    this.shaded = false,
    this.widthFactor = 0.01,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strokeWidth = MediaQuery.of(context).size.width * widthFactor;
    final paint = Paint()
      ..color = shaded ? Colors.grey.shade700 : Colors.white
      ..strokeWidth = strokeWidth;

    switch (type) {
      case StrokeType.I:
        return CustomPaint(painter: StrokePainterI(strokes, paint));
      case StrokeType.X:
        return CustomPaint(painter: StrokePainterX(strokes, paint));
      case StrokeType.V:
        return CustomPaint(painter: StrokePainterV(strokes, paint));
    }
  }
}

abstract class StrokePainter extends CustomPainter {
  final int strokes;
  final Paint _paint;
  final double _dx;

  double y0 = 15.0;
  late double y1;

  StrokePainter(this.strokes, this._paint) : _dx = _paint.strokeWidth * 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    y1 = size.height - y0;

    for (var i = 0; i < strokes; i++) {
      var pts = points(i);
      for (var j = 1; j < pts.length; j++) {
        canvas.drawLine(pts[j - 1], pts[j], _paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  List<Offset> points(int i);
}

class StrokePainterI extends StrokePainter {
  StrokePainterI(super.strokes, super.strokeWidth);

  @override
  List<Offset> points(int i) {
    var x = i * _dx;
    if ((i + 1) % 5 == 0) {
      return [Offset(x, y0), Offset(x - 5 * _dx, y1)];
    } else {
      return [Offset(x, y0), Offset(x, y1)];
    }
  }
}

class StrokePainterX extends StrokePainter {
  StrokePainterX(super.strokes, super.strokeWidth);

  @override
  List<Offset> points(int i) {
    var x0 = (i ~/ 2) * 3 * _dx;
    var x1 = x0 + 2 * _dx;
    if (i % 2 == 0) {
      return [Offset(x0, y0), Offset(x1, y1)];
    } else {
      return [Offset(x0, y1), Offset(x1, y0)];
    }
  }
}

class StrokePainterV extends StrokePainter {
  StrokePainterV(super.strokes, super.strokeWidth);

  @override
  List<Offset> points(int i) {
    var x = i * 3 * _dx;
    return [Offset(x, y0), Offset(x + _dx, y1), Offset(x + 2 * _dx, y0)];
  }
}
