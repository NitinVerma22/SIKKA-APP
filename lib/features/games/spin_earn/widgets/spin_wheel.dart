import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/games/spin_earn/utils/reward_logic.dart';

class SpinWheelWidget extends StatelessWidget {
  final double rotationAngle;
  final VoidCallback onSpin;
  final bool isSpinning;

  const SpinWheelWidget({
    super.key,
    required this.rotationAngle,
    required this.onSpin,
    required this.isSpinning,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The spinning wheel
        Transform.rotate(
          angle: rotationAngle,
          child: RepaintBoundary(
            child: CustomPaint(
              size: const Size(300, 300),
              painter: _WheelPainter(RewardLogic.wheelSlots),
            ),
          ),
        ),
        // The top indicator pointer
        Positioned(
          top: -15,
          child: Container(
            width: 30,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent,
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: CustomPaint(
              painter: _PointerPainter(),
            ),
          ),
        ),
        // Center cap / Spin button
        GestureDetector(
          onTap: isSpinning ? null : onSpin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSpinning
                  ? const LinearGradient(
                      colors: [Colors.grey, Colors.blueGrey])
                  : AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: isSpinning
                      ? Colors.transparent
                      : AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                'SPIN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2,
                  shadows: isSpinning
                      ? []
                      : [
                          const Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<RewardItem> slots;
  _WheelPainter(this.slots);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / slots.length;

    // Background base
    final basePaint = Paint()
      ..color = const Color(0xFF1A1A24)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < slots.length; i++) {
      final startAngle = i * sweepAngle;

      // Draw segment background (alternating colors or specific rarity colors)
      final segmentPaint = Paint()
        ..style = PaintingStyle.fill;
      
      final coins = slots[i].coins;
      if (coins == 30) {
        segmentPaint.color = const Color(0xFFFFD700).withValues(alpha: 0.3); // Gold for ultra rare
      } else if (coins >= 15) {
        segmentPaint.color = const Color(0xFF8F00FF).withValues(alpha: 0.2); // Purple for rare
      } else if (i % 2 == 0) {
        segmentPaint.color = Colors.white.withValues(alpha: 0.05);
      } else {
        segmentPaint.color = Colors.white.withValues(alpha: 0.02);
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        segmentPaint,
      );

      // Draw separator line
      final linePaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        ),
        linePaint,
      );

      // Draw text
      canvas.save();
      // Rotate canvas to center of this segment
      final segmentCenterAngle = startAngle + (sweepAngle / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(segmentCenterAngle);
      
      // We want text to read upright when segment is at the top.
      // Top is -pi/2. When segment is at top, its angle is -pi/2.
      // We just draw it along the radius.
      canvas.translate(radius * 0.7, 0);
      canvas.rotate(pi / 2);

      textPainter.text = TextSpan(
        text: slots[i].label,
        style: TextStyle(
          color: coins >= 15 ? const Color(0xFFFFD700) : Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 4),
          ],
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Outer border glowing
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
    canvas.drawCircle(center, radius, borderPaint);

    final innerBorder = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, innerBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.lineTo(size.width / 2, size.height); // Bottom center
    path.close();

    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
