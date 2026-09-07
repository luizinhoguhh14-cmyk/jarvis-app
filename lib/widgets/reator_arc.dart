import 'package:flutter/material.dart';
import 'dart:math' as math;

class ReatorArc3DPainter extends CustomPainter {
  final double progress;
  final Color cor;

  ReatorArc3DPainter(this.progress, this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double angulo = progress * 2 * math.pi;

    final paintAnel1 = Paint()
      ..color = cor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angulo);

    final rect1 = Rect.fromCenter(center: Offset.zero, width: 250, height: 125);
    canvas.drawArc(rect1, 0, math.pi * 1.5, false, paintAnel1);

    final double x1 = 125 * math.cos(angulo * 2);
    final double y1 = 62 * math.sin(angulo * 2);
    canvas.drawCircle(Offset(x1, y1), 4, Paint()..color = Colors.white);

    canvas.restore();

    final paintAnel2 = Paint()
      ..color = cor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-angulo * 1.5);

    final rect2 = Rect.fromCenter(center: Offset.zero, width: 170, height: 170);
    canvas.drawArc(rect2, math.pi / 4, math.pi, false, paintAnel2);
    canvas.drawArc(rect2, math.pi * 1.2, math.pi / 2, false, paintAnel2..strokeWidth = 5);

    canvas.restore();

    final paintAnel3 = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angulo * 2.0);

    for (int i = 0; i < 12; i++) {
      double a = (i * 30) * math.pi / 180;
      canvas.drawLine(
        Offset(70 * math.cos(a), 70 * math.sin(a)),
        Offset(85 * math.cos(a), 85 * math.sin(a)),
        paintAnel3,
      );
    }

    canvas.restore();

    final paintNucleoGlow = Paint()
      ..color = cor.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    canvas.drawCircle(center, 40, paintNucleoGlow);

    final paintNucleo = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 18, paintNucleo);
    canvas.drawCircle(center, 25, Paint()..color = cor..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant ReatorArc3DPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
