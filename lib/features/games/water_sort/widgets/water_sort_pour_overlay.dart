import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/water_sort_models.dart';

class WaterSortPourOverlay extends StatelessWidget {
  final Offset srcPos;
  final Offset dstPos;
  final int liquidColorId;
  final TubeState srcTube;
  final TubeState dstTube;
  final int capacity;
  final double progress; // 0.0 to 1.0
  final double bottleWidth;
  final double bottleHeight;

  const WaterSortPourOverlay({
    super.key,
    required this.srcPos,
    required this.dstPos,
    required this.liquidColorId,
    required this.srcTube,
    required this.dstTube,
    required this.capacity,
    required this.progress,
    this.bottleWidth = 60.0,
    this.bottleHeight = 170.0,
  });

  @override
  Widget build(BuildContext context) {
    // 3-Phase Animation Interpolation (1000ms Total Duration):
    // Phase 1 (0.0 -> 0.25, 0-250ms): Lift and translate from srcPos to target mouth
    // Phase 2 (0.25 -> 0.80, 250-800ms): Liquid stream active, pour audio playing
    // Phase 3 (0.80 -> 1.0, 800-1000ms): Un-tilt and translate back to srcPos

    double currentX;
    double currentY;
    double rotationAngle; // radians
    double streamAlpha;

    final Offset targetMouthPos = Offset(dstPos.dx + bottleWidth * 0.45, dstPos.dy - bottleHeight * 0.25);

    if (progress <= 0.25) {
      final t = progress / 0.25;
      final curvedT = Curves.easeInOutCubic.transform(t);
      currentX = Offset.lerp(srcPos, targetMouthPos, curvedT)!.dx;
      currentY = Offset.lerp(srcPos, targetMouthPos, curvedT)!.dy;
      rotationAngle = math.pi * 0.42 * curvedT;
      streamAlpha = 0.0;
    } else if (progress <= 0.80) {
      currentX = targetMouthPos.dx;
      currentY = targetMouthPos.dy;
      rotationAngle = math.pi * 0.42; // ~75 degrees
      streamAlpha = 1.0;
    } else {
      final t = (progress - 0.80) / 0.20;
      final curvedT = Curves.easeInOutCubic.transform(t);
      currentX = Offset.lerp(targetMouthPos, srcPos, curvedT)!.dx;
      currentY = Offset.lerp(targetMouthPos, srcPos, curvedT)!.dy;
      rotationAngle = math.pi * 0.42 * (1.0 - curvedT);
      streamAlpha = 0.0;
    }

    final Color liquidColor = WaterSortColors.getColor(liquidColorId);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // 1. Liquid Stream Flowing into Destination Bottle
            if (streamAlpha > 0)
              CustomPaint(
                size: Size.infinite,
                painter: _WaterSortStreamPainter(
                  streamStart: Offset(currentX + 10, currentY + 15),
                  streamEnd: Offset(dstPos.dx + bottleWidth * 0.5, dstPos.dy + 25),
                  color: liquidColor,
                  progress: (progress - 0.25) / 0.55,
                ),
              ),

            // 2. Floating Tilted Source Bottle
            Positioned(
              left: currentX,
              top: currentY,
              child: Transform.rotate(
                angle: rotationAngle,
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: bottleWidth,
                  height: bottleHeight,
                  child: CustomPaint(
                    painter: _FloatingBottlePainter(
                      tube: srcTube,
                      capacity: capacity,
                      colorId: liquidColorId,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBottlePainter extends CustomPainter {
  final TubeState tube;
  final int capacity;
  final int colorId;

  _FloatingBottlePainter({
    required this.tube,
    required this.capacity,
    required this.colorId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double borderRadius = width * 0.35;

    final RRect outerRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, width, height),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    );

    canvas.save();
    canvas.clipRRect(outerRect);

    // Draw Liquid Units
    final double unitHeight = (height - 4) / capacity;
    for (int i = 0; i < tube.length; i++) {
      final color = WaterSortColors.getColor(tube[i]);
      final double topY = height - (i + 1) * unitHeight;
      final Rect unitRect = Rect.fromLTWH(0, topY, width, unitHeight + 0.5);

      final Paint liquidPaint = Paint()..color = color;
      canvas.drawRect(unitRect, liquidPaint);
    }

    canvas.restore();

    // Glass Tube Outline
    final Paint outlinePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(outerRect, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WaterSortStreamPainter extends CustomPainter {
  final Offset streamStart;
  final Offset streamEnd;
  final Color color;
  final double progress;

  _WaterSortStreamPainter({
    required this.streamStart,
    required this.streamEnd,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path streamPath = Path()
      ..moveTo(streamStart.dx, streamStart.dy)
      ..quadraticBezierTo(
        (streamStart.dx + streamEnd.dx) * 0.5,
        streamStart.dy + 20,
        streamEnd.dx,
        streamEnd.dy,
      );

    final Paint streamPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0;

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawPath(streamPath, glowPaint);
    canvas.drawPath(streamPath, streamPaint);

    // Splash Particles at Landing Point
    final math.Random rng = math.Random(12345);
    final Paint particlePaint = Paint()..color = color.withValues(alpha: 0.85);

    for (int i = 0; i < 6; i++) {
      final double pAngle = (i * 60 + progress * 360) * math.pi / 180;
      final double dist = 6 + rng.nextDouble() * 10;
      final Offset pOffset = Offset(
        streamEnd.dx + math.cos(pAngle) * dist,
        streamEnd.dy + math.sin(pAngle) * dist,
      );
      canvas.drawCircle(pOffset, 2.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
