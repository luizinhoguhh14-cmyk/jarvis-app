import 'package:flutter/material.dart';
import 'dart:math' as math;

class GloboTerrestre3DPainter extends CustomPainter {
  final double progressRotacao;
  final double zoomScale;
  final Color cor;
  final bool comTravaAlvo;

  GloboTerrestre3DPainter({
    required this.progressRotacao,
    required this.zoomScale,
    required this.cor,
    required this.comTravaAlvo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2.8) * zoomScale;

    final paintGloboLinha = Paint()
      ..color = cor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintAtmosfera = Paint()
      ..color = cor.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Atmosfera do Globo
    canvas.drawCircle(center, radius + 8, paintAtmosfera);
    canvas.drawCircle(center, radius, Paint()..color = cor.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Desenha paralelos e meridianos (Projeção 3D)
    final mathRot = progressRotacao * 2 * math.pi;

    for (int i = -3; i <= 3; i++) {
      double lat = (i * 25) * math.pi / 180;
      double rLat = radius * math.cos(lat);
      double yLat = center.dy + radius * math.sin(lat);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, yLat), width: rLat * 2, height: rLat * 0.4),
        paintGloboLinha,
      );
    }

    // Desenha Meridianos Rotacionando
    for (int i = 0; i < 8; i++) {
      double lon = (i * 45) * math.pi / 180 + mathRot;
      double xOffset = math.sin(lon) * radius;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, center.dy), width: xOffset.abs() * 2, height: radius * 2),
        paintGloboLinha,
      );
    }

    // Pontos Holográficos Continentais
    final paintPontos = Paint()..color = cor;
    for (int i = 0; i < 40; i++) {
      double pAngle = i * 9.0 + (mathRot * 15);
      double px = center.dx + (radius * 0.7 * math.cos(pAngle));
      double py = center.dy + (radius * 0.7 * math.sin(pAngle * 0.5));
      canvas.drawCircle(Offset(px, py), 1.8, paintPontos);
    }

    // Retículo de Mira / Trava de Alvo (Target Lock)
    if (comTravaAlvo) {
      final paintMira = Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, 30, paintMira);
      canvas.drawLine(Offset(center.dx - 45, center.dy), Offset(center.dx + 45, center.dy), paintMira);
      canvas.drawLine(Offset(center.dx, center.dy - 45), Offset(center.dx, center.dy + 45), paintMira);

      // Texto de TARGET LOCKED
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'TARGET LOCKED',
          style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(center.dx - (textPainter.width / 2), center.dy + 38));
    }
  }

  @override
  bool shouldRepaint(covariant GloboTerrestre3DPainter oldDelegate) {
    return oldDelegate.progressRotacao != progressRotacao ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.comTravaAlvo != comTravaAlvo;
  }
}
