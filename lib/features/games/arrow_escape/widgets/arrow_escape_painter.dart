import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/arrow_escape_models.dart';

class ArrowEscapePainter extends CustomPainter {
  final ArrowEscapeGameState state;
  final String? hintArrowId;

  ArrowEscapePainter({
    required this.state,
    this.hintArrowId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = math.min(size.width, size.height) / state.gridSize;
    final double paddingX = (size.width - (cellSize * state.gridSize)) / 2.0;
    final double paddingY = (size.height - (cellSize * state.gridSize)) / 2.0;

    // 1. Draw Dot Grid Background
    final Paint dotPaint = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (int r = 0; r <= state.gridSize; r++) {
      for (int c = 0; c <= state.gridSize; c++) {
        final double x = paddingX + c * cellSize;
        final double y = paddingY + r * cellSize;
        canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
      }
    }

    // 2. Draw Multi-Segment Winding Snake Arrows
    for (final arrow in state.arrows) {
      if (arrow.isEscaping && arrow.animProgress >= 1.0) continue;

      final isHinted = (arrow.id == hintArrowId);
      _drawSnakeArrow(canvas, paddingX, paddingY, cellSize, arrow, isHinted, size);
    }
  }

  void _drawSnakeArrow(
    Canvas canvas,
    double padX,
    double padY,
    double cellSize,
    ArrowModel arrow,
    bool isHinted,
    Size canvasSize,
  ) {
    if (arrow.path.isEmpty) return;

    // Calculate pixel coordinates for path segments
    final List<Offset> points = arrow.path.map((pt) {
      final double cx = padX + pt[1] * cellSize + cellSize / 2.0;
      final double cy = padY + pt[0] * cellSize + cellSize / 2.0;
      return Offset(cx, cy);
    }).toList();

    // Apply animation displacement along direction
    Offset animOffset = Offset.zero;
    if (arrow.isEscaping) {
      final double escapeDist = math.max(canvasSize.width, canvasSize.height) * 1.2;
      final vec = arrow.direction.delta;
      animOffset = Offset(vec.dy * escapeDist * arrow.animProgress, vec.dx * escapeDist * arrow.animProgress);
    } else if (arrow.isColliding) {
      final vec = arrow.direction.delta;
      final double bump = math.sin(arrow.animProgress * math.pi) * 20.0;
      animOffset = Offset(vec.dy * bump, vec.dx * bump);
    }

    final List<Offset> animPoints = points.map((p) => p + animOffset).toList();

    // Hint Glow
    if (isHinted) {
      final Paint glowPaint = Paint()
        ..color = const Color(0xFFFACC15).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final Path glowPath = Path();
      glowPath.moveTo(animPoints.first.dx, animPoints.first.dy);
      for (int i = 1; i < animPoints.length; i++) {
        glowPath.lineTo(animPoints[i].dx, animPoints[i].dy);
      }
      canvas.drawPath(glowPath, glowPaint);
    }

    // Polyline Shaft Body
    final Paint linePaint = Paint()
      ..color = arrow.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path bodyPath = Path();
    bodyPath.moveTo(animPoints.first.dx, animPoints.first.dy);
    for (int i = 1; i < animPoints.length; i++) {
      bodyPath.lineTo(animPoints[i].dx, animPoints[i].dy);
    }
    canvas.drawPath(bodyPath, linePaint);

    // Arrow Caret Head at path.first (Head)
    final Offset headPoint = animPoints.first;
    _drawCaretHead(canvas, headPoint, cellSize * 0.35, arrow.direction, arrow.color);
  }

  void _drawCaretHead(
    Canvas canvas,
    Offset center,
    double size,
    ArrowDirection dir,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(dir.rotationRadians);

    final Paint headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    path.moveTo(-size * 0.6, -size * 0.7);
    path.lineTo(size * 0.6, 0);
    path.lineTo(-size * 0.6, size * 0.7);

    canvas.drawPath(path, headPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
