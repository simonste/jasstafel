import 'package:flutter/material.dart';

class BackgroundZPainter extends CustomPainter {
  final Size widgetSize;
  final Size margin;

  BackgroundZPainter(this.widgetSize, this.margin);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    final left = margin.width;
    final right = widgetSize.width - margin.width;
    final top = margin.height;
    final bottom = widgetSize.height / 2 - margin.height;

    canvas.drawLine(Offset(left, top), Offset(right, top), paint);
    canvas.drawLine(Offset(left, bottom), Offset(right, top), paint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class BackgroundZ extends StatelessWidget {
  final Size margin;

  const BackgroundZ(this.margin, {super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return CustomPaint(painter: BackgroundZPainter(size, margin));
  }
}
