import 'package:flutter/material.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/shared/widgets/premium_button.dart';
import 'package:sikkaplay/shared/widgets/premium_card.dart';

class SocialTask {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final int rewardAmount;
  final bool isCompleted;
  final String platform;
  final String link;

  SocialTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.rewardAmount,
    this.isCompleted = false,
    required this.platform,
    required this.link,
  });

  factory SocialTask.fromJson(Map<String, dynamic> json) {
    final platformStr = json['platform'] as String? ?? 'other';
    final linkStr = json['link'] as String? ?? '';
    
    String subtitleStr = 'Click to follow and earn coins';
    switch (platformStr.toLowerCase()) {
      case 'telegram':
        subtitleStr = 'Join SikkaPlay on Telegram';
        break;
      case 'whatsapp':
        subtitleStr = 'Follow WhatsApp Channel';
        break;
      case 'instagram':
        subtitleStr = 'Follow SikkaPlay on Instagram';
        break;
      case 'facebook':
        subtitleStr = 'Like SikkaPlay page';
        break;
      case 'youtube':
        subtitleStr = 'Subscribe SikkaPlay YouTube';
        break;
    }

    return SocialTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: subtitleStr,
      icon: _getPlatformIcon(platformStr),
      iconColor: _getPlatformColor(platformStr),
      rewardAmount: json['coinsReward'] as int? ?? 50,
      isCompleted: json['isCompleted'] as bool? ?? false,
      platform: platformStr,
      link: linkStr,
    );
  }

  static IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'telegram':
        return Icons.telegram;
      case 'whatsapp':
        return Icons.chat_bubble_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'youtube':
        return Icons.play_circle_fill_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  static Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'telegram':
        return const Color(0xFF0088CC);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'youtube':
        return const Color(0xFFFF0000);
      default:
        return const Color(0xFF863BFF);
    }
  }
}

class SocialJoinTasksWidget extends StatelessWidget {
  final List<SocialTask> tasks;
  final Function(SocialTask) onJoin;

  const SocialJoinTasksWidget({
    super.key,
    required this.tasks,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
          child: Text(
            'Join & Earn',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Column(
          children: tasks.map((task) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                backgroundColor: Colors.white,
                border: Border.all(
                  color: task.iconColor.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: task.iconColor.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [task.iconColor, task.iconColor.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: task.iconColor.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(task.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on,
                                  color: AppColors.yellowGlow, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '+${task.rewardAmount}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber.shade800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        SizedBox(
                          width: 80,
                          height: 32,
                          child: PremiumButton(
                            text: task.isCompleted ? 'Joined' : 'Join',
                            borderRadius: AppSizes.radiusSm,
                            isSecondary: !task.isCompleted,
                            customGradient: task.isCompleted
                                ? const LinearGradient(colors: [
                                    Color(0xFFBDBDBD),
                                    Color(0xFF9E9E9E)
                                  ])
                                : null,
                            onTap: task.isCompleted
                                ? () {}
                                : () => onJoin(task),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
