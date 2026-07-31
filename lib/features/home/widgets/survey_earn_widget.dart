import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/shared/widgets/premium_card.dart';

class SurveyItem {
  final String id;
  final String title;
  final String description;
  final String estimatedTime;
  final int rewardAmount;
  final IconData icon;
  final Color iconColor;

  SurveyItem({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedTime,
    required this.rewardAmount,
    required this.icon,
    required this.iconColor,
  });
}

class SurveyEarnWidget extends ConsumerStatefulWidget {
  final Function(String title, int amount) onClaim;

  const SurveyEarnWidget({
    super.key,
    required this.onClaim,
  });

  @override
  ConsumerState<SurveyEarnWidget> createState() => _SurveyEarnWidgetState();
}

class _SurveyEarnWidgetState extends ConsumerState<SurveyEarnWidget> {
  String? _loadingSurveyId;
  final Set<String> _completedSurveys = {};

  final List<SurveyItem> _surveys = [
    SurveyItem(
      id: 's1',
      title: 'Lifestyle & Tech Survey',
      description: 'Answer questions about your daily tech usage.',
      estimatedTime: '10 Mins',
      rewardAmount: 500,
      icon: Icons.computer_rounded,
      iconColor: Colors.blue,
    ),
    SurveyItem(
      id: 's2',
      title: 'Shopping Preferences',
      description: 'Share your online shopping habits.',
      estimatedTime: '5 Mins',
      rewardAmount: 250,
      icon: Icons.shopping_bag_rounded,
      iconColor: Colors.purple,
    ),
    SurveyItem(
      id: 's3',
      title: 'Finance & Banking',
      description: 'Quick survey about banking apps.',
      estimatedTime: '15 Mins',
      rewardAmount: 800,
      icon: Icons.account_balance_rounded,
      iconColor: Colors.green,
    ),
  ];

  void _startSurvey(SurveyItem survey) async {
    if (_completedSurveys.contains(survey.id) || _loadingSurveyId != null) return;

    setState(() {
      _loadingSurveyId = survey.id;
    });

    // Simulate survey opening/completion process
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _loadingSurveyId = null;
        _completedSurveys.add(survey.id);
      });
      widget.onClaim(survey.title, survey.rewardAmount);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Survey Complete! You earned ${survey.rewardAmount} coins.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'High Yield Surveys',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'HOT',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        ..._surveys.map((survey) => _buildSurveyCard(survey)),
      ],
    );
  }

  Widget _buildSurveyCard(SurveyItem survey) {
    final isCompleted = _completedSurveys.contains(survey.id);
    final isLoading = _loadingSurveyId == survey.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.grey.withValues(alpha: 0.1) : survey.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(
                survey.icon,
                color: isCompleted ? Colors.grey : survey.iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    survey.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${survey.estimatedTime} • ${survey.description}',
                    style: TextStyle(
                      color: isCompleted ? AppColors.textLight : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            GestureDetector(
              onTap: () => _startSurvey(survey),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isCompleted ? null : AppColors.primaryGradient,
                  color: isCompleted ? Colors.grey.shade300 : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompleted) ...[
                            Text(
                              '+${survey.rewardAmount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 14),
                          ] else
                            const Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
