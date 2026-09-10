import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/shared/widgets/ad_banner_widget.dart';

class SurveysScreen extends ConsumerWidget {
  const SurveysScreen({super.key});

  void _claimSurveyReward(BuildContext context, WidgetRef ref, String title, int amount) async {
    ref.read(homeProvider.notifier).claimSurvey(title, amount);
    await ref.read(userProvider.notifier).claimReward(amount, 'survey', title);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Survey Complete! Claimed $amount coins.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _startThirdPartySurvey(BuildContext context, WidgetRef ref, String provider, int amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int currentQuestion = 1;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.quiz, color: AppColors.secondary, size: 24),
                  const SizedBox(width: 8),
                  Text('$provider Survey', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: currentQuestion / 3,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Question $currentQuestion of 3',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentQuestion == 1
                        ? 'Which online games do you play the most?'
                        : currentQuestion == 2
                            ? 'How often do you watch short video reels?'
                            : 'Would you recommend SikkaPlay to your friends?',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._getAnswersForQuestion(currentQuestion).map((ans) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            if (currentQuestion < 3) {
                              setStateDialog(() {
                                currentQuestion++;
                              });
                            } else {
                              Navigator.of(context).pop(true);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Text(ans, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                        ),
                      )),
                ],
              ),
            );
          },
        );
      },
    ).then((completed) {
      if (completed == true && context.mounted) {
        _claimSurveyReward(context, ref, '$provider Premium Survey', amount);
      }
    });
  }

  List<String> _getAnswersForQuestion(int q) {
    if (q == 1) return ['Action / Shooting', 'Puzzles / Strategy', 'Casual / Board games', 'None of these'];
    if (q == 2) return ['Every hour', 'Few times a day', 'Rarely', 'Never'];
    return ['Definitely Yes!', 'Maybe', 'No', 'Not sure'];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Complete Surveys',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CPX and Pollfish Premium Partners
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.xs),
              child: Text(
                'Premium Survey Partners',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPartnerCard(
                    context,
                    ref,
                    title: 'CPX Research',
                    subtitle: 'Offers up to 5000+ Coins',
                    icon: Icons.analytics_rounded,
                    color: Colors.orange.shade800,
                    coins: 5000,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPartnerCard(
                    context,
                    ref,
                    title: 'Pollfish',
                    subtitle: 'Coming soon',
                    icon: Icons.poll_rounded,
                    color: Colors.indigo.shade800,
                    coins: 0,
                    isLocked: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPartnerCard(
                    context,
                    ref,
                    title: 'BitLabs',
                    subtitle: 'Coming soon',
                    icon: Icons.science_rounded,
                    color: Colors.blue.shade800,
                    coins: 0,
                    isLocked: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPartnerCard(
                    context,
                    ref,
                    title: 'TheoremReach',
                    subtitle: 'Coming soon',
                    icon: Icons.insights_rounded,
                    color: Colors.teal.shade800,
                    coins: 0,
                    isLocked: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),



            // Bottom Banner Ad
            const AdBannerWidget(placementName: 'surveys'),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int coins,
    bool isLocked = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title integration is coming soon! Stay tuned.'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (title == 'CPX Research') {
            final userState = ref.read(userProvider);
            final userData = userState.userData ?? {};
            final userId = userData['id'] ?? 'guest';
            final email = userData['email'] ?? '';
            final name = userData['name'] ?? '';
            
            final url = "https://offers.cpx-research.com/index.php"
                "?app_id=33354"
                "&ext_user_id=$userId"
                "&username=${Uri.encodeComponent(name)}"
                "&email=${Uri.encodeComponent(email)}";

            context.push('/webview', extra: {
              'url': url,
              'title': 'CPX Research Surveys',
            });
          } else {
            _startThirdPartySurvey(context, ref, title, coins);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLocked ? Colors.grey.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isLocked ? Colors.grey : color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLocked ? 'LOCKED' : (title == 'CPX Research' ? '5000+' : '+$coins'),
                      style: TextStyle(
                        color: isLocked ? Colors.grey : AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    if (!isLocked) ...[
                      const SizedBox(width: 2),
                      const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
