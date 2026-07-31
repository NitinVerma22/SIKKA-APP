import 'package:flutter/material.dart';
import 'package:sikkaplay/core/animations/custom_animations.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/shared/widgets/premium_button.dart';

class RewardClaimDialog extends StatelessWidget {
  final int amount;
  final String title;

  const RewardClaimDialog({
    super.key,
    required this.amount,
    this.title = 'Reward Claimed!',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: FadeInSlideWidget(
        slideOffset: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(
              color: AppColors.yellowGlow.withValues(alpha: 0.5),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Header Icon
              PulseWidget(
                duration: const Duration(milliseconds: 1200),
                scaleFactor: 0.12,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      fontSize: AppSizes.getResponsiveFontSize(context, 22),
                    ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'You have successfully added coins to your wallet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.getResponsiveFontSize(context, 13),
                    ),
              ),
              const SizedBox(height: AppSizes.lg),
              // Sikka Amount Counter Capsule
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusCircular),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: AppColors.accent,
                      size: 24,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      '+$amount Sikka',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontSize:
                                AppSizes.getResponsiveFontSize(context, 18),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              PremiumButton(
                text: 'Awesome!',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
