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
    final double width = size.width;
    final double height = size.height;

    final double cellWidth = width / state.cols;
    final double cellHeight = height / state.rows;
    final double cellSize = math.min(cellWidth, cellHeight);
    final double paddingX = (width - (cellSize * state.cols)) / 2.0;
    final double paddingY = (height - (cellSize * state.rows)) / 2.0;

    // 1. Draw Grid Cells Background Tiles
    for (int r = 0; r < state.rows; r++) {
      for (int c = 0; c < state.cols; c++) {
        final double left = paddingX + c * cellSize;
        final double top = paddingY + r * cellSize;
        final Rect cellRect = Rect.fromLTWH(left + 3, top + 3, cellSize - 6, cellSize - 6);

        final Paint tilePaint = Paint()
          ..color = const Color(0xFF1E293B).withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(cellRect, const Radius.circular(16)),
          tilePaint,
        );

        final Paint borderPaint = Paint()
          ..color = const Color(0xFF334155).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

        canvas.drawRRect(
          RRect.fromRectAndRadius(cellRect, const Radius.circular(16)),
          borderPaint,
        );
      }
    }

    // 2. Draw Arrow Nodes & Flying Flight Trails
    for (int r = 0; r < state.rows; r++) {
      for (int c = 0; c < state.cols; c++) {
        final node = state.grid[r][c];
        if (node != null) {
          final double baseCx = paddingX + c * cellSize + cellSize / 2.0;
          final double baseCy = paddingY + r * cellSize + cellSize / 2.0;

          // Apply animated flight offset
          final double cx = baseCx + node.flightOffset.dx;
          final double cy = baseCy + node.flightOffset.dy;

          final isHinted = (node.id == hintArrowId);
          _drawArrow(canvas, Offset(cx, cy), cellSize * 0.4, node, isHinted);
        }
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset center, double radius, ArrowNode node, bool isHinted) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(node.dir.angleRadians);

    // Hint Glow Ring
    if (isHinted) {
      final Paint glowPaint = Paint()
        ..color = const Color(0xFFFACC15).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, radius * 1.3, glowPaint);
    }

    // 3D Arrow Shaft & Head Gradient Paint
    final Paint arrowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white,
          node.color,
          Color.lerp(node.color, Colors.black, 0.35)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    final Path path = Path();
    final double headLen = radius * 0.7;
    final double headWidth = radius * 0.75;
    final double shaftWidth = radius * 0.35;
    final double shaftLen = radius * 0.7;

    // Pointing Right by default at angle 0.0
    path.moveTo(headLen, 0); // Arrow Tip
    path.lineTo(0, -headWidth); // Upper Head Wing
    path.lineTo(0, -shaftWidth); // Upper Shaft Join
    path.lineTo(-shaftLen, -shaftWidth); // Upper Shaft End
    path.lineTo(-shaftLen, shaftWidth); // Lower Shaft End
    path.lineTo(0, shaftWidth); // Lower Shaft Join
    path.lineTo(0, headWidth); // Lower Head Wing
    path.close();

    canvas.drawPath(path, arrowPaint);

    // Outline Border
    final Paint outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, outline);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
