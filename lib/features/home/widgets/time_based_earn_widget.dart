import 'package:flutter/material.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/shared/widgets/premium_button.dart';
import 'package:sikkaplay/shared/widgets/premium_card.dart';

class TimeMilestone {
  final int minutesRequired;
  final int rewardAmount;
  final bool isClaimed;

  TimeMilestone({
    required this.minutesRequired,
    required this.rewardAmount,
    this.isClaimed = false,
  });
}

class TimeBasedEarnWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final int currentMinutes;
  final List<TimeMilestone> milestones;
  final Function(int) onClaim;

  const TimeBasedEarnWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.currentMinutes,
    required this.milestones,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxMinutes = milestones.last.minutesRequired;
    final progress = (currentMinutes / maxMinutes).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: AppSizes.sm),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$currentMinutes mins',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        PremiumCard(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            children: [
              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              // Milestones
              Column(
                children: milestones.map((milestone) {
                  final canClaim = currentMinutes >= milestone.minutesRequired && !milestone.isClaimed;
                  final isCompleted = milestone.isClaimed;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isCompleted ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCompleted ? Icons.check : Icons.timer,
                                size: 16,
                                color: isCompleted ? AppColors.success : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              '${milestone.minutesRequired} mins',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '+${milestone.rewardAmount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            SizedBox(
                              width: 80,
                              height: 32,
                              child: PremiumButton(
                                text: isCompleted ? 'Claimed' : 'Claim',
                                borderRadius: AppSizes.radiusSm,
                                customGradient: isCompleted 
                                    ? const LinearGradient(colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)])
                                    : (canClaim ? AppColors.goldGradient : const LinearGradient(colors: [AppColors.borderLight, AppColors.borderLight])),
                                onTap: canClaim ? () => onClaim(milestone.minutesRequired) : () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
