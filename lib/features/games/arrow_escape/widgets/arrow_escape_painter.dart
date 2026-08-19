import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_escape_models.dart';

class ParticleModel {
  Offset position;
  Offset velocity;
  Color color;
  double alpha;
  double radius;

  ParticleModel({
    required this.position,
    required this.velocity,
    required this.color,
    this.alpha = 1.0,
    required this.radius,
  });
}

class ArrowEscapePainter extends CustomPainter {
  final ArrowLevelModel level;
  final List<ArrowSnakeModel> arrows;
  final String? highlightedArrowId;
  final List<ParticleModel> particles;

  ArrowEscapePainter({
    required this.level,
    required this.arrows,
    this.highlightedArrowId,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridSize = level.gridSize;
    final cellSize = size.width / gridSize;

    // 1. Draw Dot Matrix Grid & Border
    _drawGridBackground(canvas, size, gridSize, cellSize);

    // 2. Draw Winding Arrows
    for (final arrow in arrows) {
      if (arrow.pathPoints.isEmpty) continue;

      canvas.save();

      // Apply shake offset if blocked
      if (arrow.isBlockedShaking) {
        final shakeDx = sin(arrow.shakeProgress * pi * 4) * (cellSize * 0.15);
        canvas.translate(shakeDx, 0);
      }

      final isHinted = arrow.id == highlightedArrowId;
      _drawSingleArrow(canvas, arrow, cellSize, gridSize, size, isHinted);

      canvas.restore();
    }

    // 3. Draw Particle Burst Effects
    _drawParticles(canvas);
  }

  void _drawGridBackground(Canvas canvas, Size size, int gridSize, double cellSize) {
    final bgPaint = Paint()..color = const Color(0xFF14161C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20)),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF2E323D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20)),
      borderPaint,
    );

    // Dot matrix grid
    final dotPaint = Paint()..color = const Color(0xFF282C38);
    for (int r = 0; r <= gridSize; r++) {
      for (int c = 0; c <= gridSize; c++) {
        canvas.drawCircle(Offset(c * cellSize, r * cellSize), 1.8, dotPaint);
      }
    }
  }

  void _drawSingleArrow(
    Canvas canvas,
    ArrowSnakeModel arrow,
    double cellSize,
    int gridSize,
    Size size,
    bool isHinted,
  ) {
    final pathPts = arrow.pathPoints;
    if (pathPts.isEmpty) return;

    List<Offset> pxPoints = pathPts.map((pt) {
      return Offset((pt.x + 0.5) * cellSize, (pt.y + 0.5) * cellSize);
    }).toList();

    // If escaping, slide along exit vector
    if (arrow.isEscaping) {
      final dir = arrow.escapeDirection;
      final slideDist = arrow.escapeProgress * (size.width * 1.6);
      final slideOffset = Offset(dir.dx * slideDist, dir.dy * slideDist);
      pxPoints = pxPoints.map((pt) => pt + slideOffset).toList();
    }

    final mainColor = isHinted ? const Color(0xFFFFEA00) : arrow.color;
    final sw = cellSize * 0.14;

    final bodyPath = Path()..moveTo(pxPoints.first.dx, pxPoints.first.dy);
    for (int i = 1; i < pxPoints.length; i++) {
      bodyPath.lineTo(pxPoints[i].dx, pxPoints[i].dy);
    }

    // 1. Radial Glow
    if (isHinted) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFEA00).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawPath(bodyPath, glowPaint);
    } else {
      final glowPaint = Paint()
        ..color = mainColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(bodyPath, glowPaint);
    }

    // 2. Motion Trail when escaping
    if (arrow.isEscaping) {
      final trailPaint = Paint()
        ..color = mainColor.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(bodyPath, trailPaint);
    }

    // 3. Arrow Body Polyline
    final bodyPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, bodyPaint);

    // 4. Caret Arrow Head at Head Point (pxPoints.first)
    _drawCaretHead(canvas, pxPoints, arrow.escapeDirection, mainColor, cellSize, sw);
  }

  void _drawCaretHead(
    Canvas canvas,
    List<Offset> pxPoints,
    ArrowDirection dir,
    Color mainColor,
    double cellSize,
    double sw,
  ) {
    final head = pxPoints.first;
    final prev = pxPoints.length > 1 ? pxPoints[1] : head;
    final dv = head - prev;
    final len = dv.distance;

    final dx = len > 0.01 ? dv.dx / len : dir.dx.toDouble();
    final dy = len > 0.01 ? dv.dy / len : dir.dy.toDouble();

    final tip = head + Offset(dx * cellSize * 0.3, dy * cellSize * 0.3);
    final hd = cellSize * 0.26;
    final hw = cellSize * 0.18;

    final base = tip - Offset(dx * hd, dy * hd);
    final px = -dy;
    final py = dx;

    final caretPath = Path()
      ..moveTo(base.dx + px * hw, base.dy + py * hw)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(base.dx - px * hw, base.dy - py * hw);

    final caretPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(caretPath, caretPaint);
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.radius, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ArrowEscapePainter oldDelegate) => true;
}
