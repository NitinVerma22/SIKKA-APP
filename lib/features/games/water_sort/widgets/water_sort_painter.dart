import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/water_sort_models.dart';

class WaterSortTubePainter extends CustomPainter {
  final TubeState tube;
  final int capacity;
  final bool isSelected;
  final bool isCompleted;

  WaterSortTubePainter({
    required this.tube,
    required this.capacity,
    this.isSelected = false,
    this.isCompleted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double borderRadius = width * 0.35;
    final double borderWidth = isSelected ? 3.5 : 2.5;

    final RRect outerRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, width, height),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    );

    // 1. Clip canvas to tube interior
    canvas.save();
    canvas.clipRRect(outerRect);

    // 2. Draw Liquid Units from Bottom (index 0) to Top
    final double unitHeight = (height - 4) / capacity;
    for (int i = 0; i < tube.length; i++) {
      final colorId = tube[i];
      final color = WaterSortColors.getColor(colorId);

      final double topY = height - (i + 1) * unitHeight;
      final Rect unitRect = Rect.fromLTWH(0, topY, width, unitHeight + 0.5);

      final Paint liquidPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.95),
            color,
            color.withValues(alpha: 0.85),
          ],
        ).createShader(unitRect);

      canvas.drawRect(unitRect, liquidPaint);

      // Draw subtle meniscus curve at top of liquid column
      if (i == tube.length - 1) {
        final Path wavePath = Path()
          ..moveTo(0, topY)
          ..quadraticBezierTo(width * 0.5, topY + 3, width, topY)
          ..lineTo(width, topY + unitHeight)
          ..lineTo(0, topY + unitHeight)
          ..close();

        final Paint wavePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawPath(wavePath, wavePaint);
      }
    }

    canvas.restore();

    // 3. Glass Tube Outline & Selection Glow
    final Paint glassOutlinePaint = Paint()
      ..color = isSelected
          ? const Color(0xFFFFD700)
          : isCompleted
              ? const Color(0xFF4ADE80)
              : Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (isSelected) {
      final Paint glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawRRect(outerRect, glowPaint);
    }

    canvas.drawRRect(outerRect, glassOutlinePaint);

    // 4. Glass Tube Top Lip (Rim)
    final Paint rimPaint = Paint()
      ..color = isSelected ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(
      Path()
        ..moveTo(-3, 0)
        ..lineTo(width + 3, 0),
      rimPaint,
    );

    // 5. Glass Tube Reflection Highlight (3D Glass Look)
    final Paint highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width * 0.3, height));

    final RRect highlightRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(3, 4, width * 0.22, height - 10),
      bottomLeft: Radius.circular(borderRadius * 0.4),
      topLeft: const Radius.circular(4),
    );

    canvas.drawRRect(highlightRect, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant WaterSortTubePainter oldDelegate) {
    return oldDelegate.tube != tube ||
        oldDelegate.capacity != capacity ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isCompleted != isCompleted;
  }
}
