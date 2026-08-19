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

    // 1. Draw Subtle Grid Pattern & Border
    _drawGridBackground(canvas, size, gridSize, cellSize);

    // 2. Draw Arrows
    for (final arrow in arrows) {
      if (arrow.pathPoints.isEmpty) continue;

      canvas.save();

      // Apply shake offset if blocked
      if (arrow.isBlockedShaking) {
        final shakeDx = sin(arrow.shakeProgress * pi * 4) * (cellSize * 0.12);
        canvas.translate(shakeDx, 0);
      }

      final isHinted = arrow.id == highlightedArrowId;
      _drawSingleArrow(canvas, arrow, cellSize, gridSize, size, isHinted);

      canvas.restore();
    }

    // 3. Draw Particles
    _drawParticles(canvas);
  }

  void _drawGridBackground(Canvas canvas, Size size, int gridSize, double cellSize) {
    final bgPaint = Paint()..color = const Color(0xFF14161B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF2A2D34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)),
      borderPaint,
    );

    // Subtle grid dots
    final dotPaint = Paint()..color = const Color(0xFF2B2E38);
    for (int r = 0; r <= gridSize; r++) {
      for (int c = 0; c <= gridSize; c++) {
        canvas.drawCircle(Offset(c * cellSize, r * cellSize), 1.5, dotPaint);
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

    // Map grid points to pixel centers
    List<Offset> pxPoints = pathPts.map((pt) {
      return Offset((pt.x + 0.5) * cellSize, (pt.y + 0.5) * cellSize);
    }).toList();

    // If escaping, translate points along escape direction
    if (arrow.isEscaping) {
      final dir = arrow.escapeDirection;
      double offsetDist = arrow.escapeProgress * (size.width * 1.5);
      Offset slideVector = Offset.zero;

      switch (dir) {
        case ArrowDirection.up:
          slideVector = Offset(0, -offsetDist);
          break;
        case ArrowDirection.down:
          slideVector = Offset(0, offsetDist);
          break;
        case ArrowDirection.left:
          slideVector = Offset(-offsetDist, 0);
          break;
        case ArrowDirection.right:
          slideVector = Offset(offsetDist, 0);
          break;
      }

      pxPoints = pxPoints.map((pt) => pt + slideVector).toList();
    }

    final mainColor = isHinted ? const Color(0xFFFFEA00) : arrow.color;
    final strokeW = cellSize * 0.42;

    // Draw Hint Glow
    if (isHinted) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFEA00).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW + 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8);

      final glowPath = Path()..moveTo(pxPoints.first.dx, pxPoints.first.dy);
      for (int i = 1; i < pxPoints.length; i++) {
        glowPath.lineTo(pxPoints[i].dx, pxPoints[i].dy);
      }
      canvas.drawPath(glowPath, glowPaint);
    }

    // Draw Arrow Body Polyline
    final bodyPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bodyPath = Path()..moveTo(pxPoints.first.dx, pxPoints.first.dy);
    for (int i = 1; i < pxPoints.length; i++) {
      bodyPath.lineTo(pxPoints[i].dx, pxPoints[i].dy);
    }
    canvas.drawPath(bodyPath, bodyPaint);

    // Inner highlight core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 0.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, corePaint);

    // Draw Sharp Caret Arrow Head at index 0 (Head)
    final head = pxPoints.first;
    final dir = arrow.escapeDirection;

    double angle = 0.0;
    switch (dir) {
      case ArrowDirection.up:
        angle = -pi / 2;
        break;
      case ArrowDirection.down:
        angle = pi / 2;
        break;
      case ArrowDirection.left:
        angle = pi;
        break;
      case ArrowDirection.right:
        angle = 0;
        break;
    }

    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(angle);

    final headSize = cellSize * 0.48;
    final headPath = Path()
      ..moveTo(headSize * 0.6, 0)
      ..lineTo(-headSize * 0.4, -headSize * 0.5)
      ..lineTo(-headSize * 0.1, 0)
      ..lineTo(-headSize * 0.4, headSize * 0.5)
      ..close();

    final headPaint = Paint()..color = mainColor;
    canvas.drawPath(headPath, headPaint);

    final headCorePaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawPath(
      Path()
        ..moveTo(headSize * 0.4, 0)
        ..lineTo(-headSize * 0.2, -headSize * 0.25)
        ..lineTo(0, 0)
        ..lineTo(-headSize * 0.2, headSize * 0.25)
        ..close(),
      headCorePaint,
    );

    canvas.restore();
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
