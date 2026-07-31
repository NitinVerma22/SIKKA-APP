import 'package:flutter/material.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';

class StreakIndicator extends StatelessWidget {
  final int currentStreak;
  final int maxStreak;
  final double size;

  const StreakIndicator({
    super.key,
    required this.currentStreak,
    this.maxStreak = 7,
    this.size = 90.0,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStreak / maxStreak;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Track
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.borderLight,
              ),
            ),
          ),
          // Progress Track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          // Inner Circle & Text
          Container(
            width: size - 16,
            height: size - 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: AppColors.accent,
                  size: 20,
                ),
                Text(
                  '$currentStreak/$maxStreak',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: AppSizes.getResponsiveFontSize(context, 12),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
