import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      clipBehavior: Clip.none,
      children: [
        // Glowing Background Aura
        Container(
          width: 310,
          height: 310,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.25),
                blurRadius: 40,
                spreadRadius: 10,
              )
            ],
          ),
        ),

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

        // The top indicator pointer (Teardrop Marker)
        Positioned(
          top: -24,
          child: SizedBox(
            width: 32,
            height: 44,
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
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSpinning
                  ? const LinearGradient(
                      colors: [Color(0xFF9CA3AF), Color(0xFF4B5563)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              boxShadow: [
                BoxShadow(
                  color: isSpinning
                      ? Colors.transparent
                      : const Color(0xFF7C3AED).withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 3,
                )
              ],
              border: Border.all(
                color: const Color(0xFFC084FC).withOpacity(0.6),
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SPIN',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 1.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Tap to spin',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 8,
                      height: 1.0,
                    ),
                  ),
                ],
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

    // Draw segment slices
    for (int i = 0; i < slots.length; i++) {
      final startAngle = i * sweepAngle;

      final segmentPaint = Paint()..style = PaintingStyle.fill;
      
      // 1. Alternating mockup colors:
      // Index 3: Golden Yellow
      // Index 0, 2, 6: White
      // Index 1, 4, 5, 7: Purple
      if (i == 3) {
        segmentPaint.color = const Color(0xFFFFD54F); // Gold/Yellow
      } else if (i == 0 || i == 2 || i == 6) {
        segmentPaint.color = const Color(0xFFFCF8F2); // White/Cream
      } else {
        segmentPaint.color = const Color(0xFF7C3AED); // Royal Purple
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        segmentPaint,
      );

      // Separator lines between slices
      final linePaint = Paint()
        ..color = const Color(0xFF5B21B6).withOpacity(0.25)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        ),
        linePaint,
      );
    }

    // Render text and coin icons inside segments
    for (int i = 0; i < slots.length; i++) {
      final startAngle = i * sweepAngle;

      canvas.save();
      // Rotate canvas to center of this segment
      final segmentCenterAngle = startAngle + (sweepAngle / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(segmentCenterAngle);
      
      // Translate along radial axis and rotate text perpendicular (arc-aligned)
      canvas.translate(radius * 0.58, 0);
      canvas.rotate(pi / 2);

      final label = slots[i].label; // e.g. "2\nSPINS"
      final parts = label.split('\n');
      final valText = parts[0];
      final unitText = parts.length > 1 ? parts[1] : '';

      final isPurple = (i == 1 || i == 4 || i == 5 || i == 7);

      // 1. Draw Coins Stack or Single Coin Icon
      if (unitText.contains('SPIN')) {
        _drawCoin(canvas, const Offset(0, -32), 9);
      } else {
        _drawCoinsStack(canvas, const Offset(0, -32), 20, 13);
      }

      // 2. Draw Winnings value text
      final numColor = isPurple ? Colors.white : const Color(0xFF1E1B4B);
      final textPainterNum = TextPainter(
        text: TextSpan(
          text: valText,
          style: GoogleFonts.outfit(
            color: numColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainterNum.layout();
      textPainterNum.paint(
        canvas,
        Offset(-textPainterNum.width / 2, -14),
      );

      // 3. Draw Unit label text (SIKKA / SPINS)
      final unitColor = isPurple ? Colors.white.withOpacity(0.85) : const Color(0xFF6D28D9);
      final textPainterUnit = TextPainter(
        text: TextSpan(
          text: unitText,
          style: GoogleFonts.outfit(
            color: unitColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainterUnit.layout();
      textPainterUnit.paint(
        canvas,
        Offset(-textPainterUnit.width / 2, 10),
      );

      canvas.restore();
    }

    // Outer Purple Ring Border
    final outerRingPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 4, outerRingPaint);

    final innerRingPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 8, innerRingPaint);

    // Draw 16 Glowing LED Lights around the border
    const int lightsCount = 16;
    for (int i = 0; i < lightsCount; i++) {
      final double angle = i * (2 * pi) / lightsCount;
      final double lightRadius = radius - 4;
      final double lx = center.dx + lightRadius * cos(angle);
      final double ly = center.dy + lightRadius * sin(angle);

      // LED Outer Glow
      final glowPaint = Paint()
        ..color = const Color(0xFFF5F3FF).withOpacity(0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lx, ly), 4.5, glowPaint);

      // LED Center Light
      final bulbPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lx, ly), 2.5, bulbPaint);
    }
  }

  // Draw single vector coin
  void _drawCoin(Canvas canvas, Offset offset, double r) {
    final coinPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: offset, radius: r));
    
    canvas.drawCircle(offset, r, coinPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(offset, r, borderPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '\$',
        style: TextStyle(
          color: Color(0xFF78350F),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2 - 0.5),
    );
  }

  // Draw stacked vector coins
  void _drawCoinsStack(Canvas canvas, Offset offset, double w, double h) {
    final double ellipseHeight = h * 0.45;
    final double step = h * 0.22;

    for (int i = 0; i < 3; i++) {
      final double dy = offset.dy + (i * step) - (h * 0.2);
      final rect = Rect.fromCenter(center: Offset(offset.dx, dy), width: w, height: ellipseHeight);
      
      final stackPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);
      
      canvas.drawOval(rect, stackPaint);

      final borderPaint = Paint()
        ..color = const Color(0xFFFEF3C7)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawOval(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Teardrop path pointing down
    final path = Path();
    path.moveTo(size.width / 2, size.height); // bottom tip
    path.quadraticBezierTo(size.width, size.height * 0.55, size.width, size.height * 0.3);
    path.arcToPoint(
      Offset(0, size.height * 0.3),
      radius: Radius.circular(size.width / 2),
      clockwise: false,
    );
    path.quadraticBezierTo(0, size.height * 0.55, size.width / 2, size.height);
    path.close();

    // Draw soft shadow
    canvas.drawPath(path, Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    canvas.drawPath(path, paint);

    // Inner White Dot details
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.3), 3.5, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
