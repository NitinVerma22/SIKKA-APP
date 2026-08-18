import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/bubble_shooter_models.dart';

class BubbleShooterPainter extends CustomPainter {
  final BubbleShooterGameState state;
  final double cannonAngle; // radians
  final bool showAimGuide;
  final Offset? shotBubblePos;
  final int? shotBubbleColor;

  BubbleShooterPainter({
    required this.state,
    required this.cannonAngle,
    this.showAimGuide = true,
    this.shotBubblePos,
    this.shotBubbleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Calculate bubble diameter based on max cols (9)
    final double bubbleRadius = (width / (state.maxCols + 0.5)) / 2.0;
    final double bubbleDiameter = bubbleRadius * 2.0;
    final double rowHeight = bubbleDiameter * 0.866; // hex vertical spacing

    // 1. Draw Staggered Hex Grid Bubbles
    for (int r = 0; r < state.maxRows; r++) {
      final double rowY = r * rowHeight + bubbleRadius + 10;
      final bool isOdd = (r % 2 == 1);
      final double rowOffsetX = isOdd ? bubbleRadius : 0.0;
      final int colCount = isOdd ? state.maxCols - 1 : state.maxCols;

      for (int c = 0; c < colCount; c++) {
        final node = state.grid[r][c];
        if (node != null) {
          final double cx = c * bubbleDiameter + bubbleRadius + rowOffsetX + 4;
          final Offset center = Offset(cx, rowY);
          _drawBubble(canvas, center, bubbleRadius, node);
        }
      }
    }

    // 2. Draw Flying Shot Bubble
    if (shotBubblePos != null && shotBubbleColor != null) {
      _drawBubble(
        canvas,
        shotBubblePos!,
        bubbleRadius,
        BubbleNode(colorId: shotBubbleColor!, row: 0, col: 0),
      );
    }

    // 3. Draw Cannon Base & Aim Trajectory Line
    final Offset cannonCenter = Offset(width * 0.5, height - 70);
    _drawAimTrajectory(canvas, cannonCenter, cannonAngle, width, height - 120, bubbleRadius);
    _drawCannonBase(canvas, cannonCenter, cannonAngle, bubbleRadius);

    // 4. Draw Next 3 Upcoming Bubbles Queue Glass Holder
    _drawUpcomingBubblesQueue(canvas, cannonCenter, bubbleRadius);
  }

  void _drawBubble(Canvas canvas, Offset center, double radius, BubbleNode node) {
    if (node.type == BubbleType.stone) {
      final Paint stonePaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF334155)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius - 1, stonePaint);

      final Paint linePaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(center.dx - radius * 0.4, center.dy - radius * 0.4),
        Offset(center.dx + radius * 0.4, center.dy + radius * 0.4),
        linePaint,
      );
      return;
    }

    final colors = BubbleShooterColors.getPalette(node.colorId);

    // 3D Glossy Sphere Radial Gradient
    final Paint spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          colors.first,
          colors.last,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius - 1, spherePaint);

    // Outer Glow Ring
    final Paint borderPaint = Paint()
      ..color = colors.first.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1, borderPaint);

    // Top-Left Shiny Dot Highlight
    final Paint shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.35),
      radius * 0.22,
      shinePaint,
    );

    // Ice Freeze Overlay
    if (node.isFrozen) {
      final Paint icePaint = Paint()
        ..color = const Color(0xFF93C5FD).withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius - 1, icePaint);

      final Paint iceBorder = Paint()
        ..color = const Color(0xFF60A5FA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius - 1, iceBorder);
    }
  }

  void _drawAimTrajectory(
    Canvas canvas,
    Offset start,
    double angle,
    double screenWidth,
    double maxTargetY,
    double radius,
  ) {
    if (!showAimGuide) return;

    final Paint linePaint = Paint()
      ..color = const Color(0xFFFACC15).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    double dirX = math.sin(angle);
    double dirY = -math.cos(angle);

    Offset current = start;
    double remainingDist = showAimGuide ? 650.0 : 250.0;

    Path dashPath = Path()..moveTo(current.dx, current.dy);

    while (remainingDist > 0 && current.dy > 20) {
      double stepX = dirX * 15;
      double stepY = dirY * 15;

      Offset next = Offset(current.dx + stepX, current.dy + stepY);

      if (next.dx - radius <= 0) {
        dirX = -dirX;
        next = Offset(radius, next.dy);
      } else if (next.dx + radius >= screenWidth) {
        dirX = -dirX;
        next = Offset(screenWidth - radius, next.dy);
      }

      dashPath.lineTo(next.dx, next.dy);
      current = next;
      remainingDist -= 15;
    }

    canvas.drawPath(dashPath, linePaint);
  }

  void _drawCannonBase(Canvas canvas, Offset center, double angle, double radius) {
    // Cannon Base Ring
    final Paint basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF334155), Color(0xFF0F172A)],
      ).createShader(Rect.fromCircle(center: center, radius: 45));

    canvas.drawCircle(center, 38, basePaint);

    final Paint borderPaint = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, 38, borderPaint);

    // Current Shot Bubble inside Cannon
    _drawBubble(
      canvas,
      center,
      radius * 1.05,
      BubbleNode(colorId: state.currentShotColor, row: 0, col: 0),
    );
  }

  void _drawUpcomingBubblesQueue(Canvas canvas, Offset cannonCenter, double radius) {
    // Glassmorphic Holder Box on Left of Cannon
    final Offset holderPos = Offset(cannonCenter.dx - 110, cannonCenter.dy);

    final Paint glassBg = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: holderPos, width: 110, height: 42),
      const Radius.circular(20),
    );

    canvas.drawRRect(rect, glassBg);

    final Paint borderPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rect, borderPaint);

    // Render 3 upcoming bubbles
    for (int i = 0; i < state.upcomingShotColors.length && i < 3; i++) {
      final double bX = holderPos.dx - 32 + (i * 32);
      final double bY = holderPos.dy;
      final int colorId = state.upcomingShotColors[i];

      _drawBubble(
        canvas,
        Offset(bX, bY),
        radius * 0.72,
        BubbleNode(colorId: colorId, row: 0, col: 0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
