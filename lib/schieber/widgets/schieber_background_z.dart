import 'package:flutter/material.dart';

class BackgroundZPainter extends CustomPainter {
  final Size team;
  final EdgeInsets margin;

  BackgroundZPainter(this.team, this.margin);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    final left = margin.left;
    final right = team.width - margin.right;
    final top = margin.top;
    final bottom = team.height - margin.bottom;

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
  final Size team;
  final EdgeInsets margin;

  const BackgroundZ(this.team, this.margin, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: BackgroundZPainter(team, margin));
  }
}
