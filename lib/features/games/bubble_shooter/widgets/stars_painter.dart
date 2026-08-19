import 'package:flutter/material.dart';

class StarsPainter extends CustomPainter {
  final List<Offset> stars;
  final List<double> opacities;

  StarsPainter(this.stars, this.opacities);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < stars.length; i++) {
      final p = Paint()
        ..color = Colors.white.withValues(alpha: opacities[i])
        ..style = PaintingStyle.fill;
      final radius = (i % 3 == 0) ? 1.8 : 1.0;
      canvas.drawCircle(stars[i], radius, p);
    }
  }

  @override
  bool shouldRepaint(StarsPainter old) => true;
}
