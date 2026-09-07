import 'package:flutter/material.dart';

class GradeEspacialPainter extends CustomPainter {
  final Color cor;
  GradeEspacialPainter(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor.withOpacity(0.05)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
    canvas.drawRect(Rect.fromLTWH(15, 15, size.width - 30, size.height - 30), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
