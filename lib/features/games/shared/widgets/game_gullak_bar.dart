import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';

class GameGullakBar extends StatelessWidget {
  final int currentCoins;
  final int maxCoins;
  final VoidCallback? onClaim;

  const GameGullakBar({
    super.key,
    required this.currentCoins,
    required this.maxCoins,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = currentCoins >= maxCoins;
    final progress = (currentCoins / maxCoins).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: isFull ? onClaim : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFull ? Colors.green.withValues(alpha: 0.2) : Colors.black45,
          border: Border.all(
            color: isFull ? Colors.greenAccent : AppColors.primary.withValues(alpha: 0.5),
            width: isFull ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isFull
              ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 10)]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isFull ? Colors.yellow : AppColors.accent),
                    strokeWidth: 3,
                  ),
                ),
                Icon(
                  Icons.savings_rounded,
                  size: 14,
                  color: isFull ? Colors.yellow : Colors.white70,
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              '$currentCoins/$maxCoins',
              style: GoogleFonts.orbitron(
                color: isFull ? Colors.yellow : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (isFull) ...[
              const SizedBox(width: 6),
              const Icon(Icons.touch_app, size: 16, color: Colors.yellow),
            ]
          ],
        ),
      ),
    );
  }
}
