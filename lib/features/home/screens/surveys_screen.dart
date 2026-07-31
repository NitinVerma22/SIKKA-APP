import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:url_launcher/url_launcher.dart';
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

            // YouTube Tutorials Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.xs),
              child: Text(
                'YouTube Tutorials',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.xs),
              child: Text(
                'Learn how to complete surveys easily & qualify for maximum coins.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildYoutubeTutorialsList(context),
            const SizedBox(height: AppSizes.xl),

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

  Widget _buildYoutubeTutorialsList(BuildContext context) {
    final List<Map<String, String>> tutorials = [
      {
        'title': 'How to Complete Surveys Easily',
        'duration': '4:20 Mins',
        'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'thumbnailColor1': '0xFF6E5DE7',
        'thumbnailColor2': '0xFF8F00FF',
      },
      {
        'title': 'Earn 1000+ Coins Daily Guide',
        'duration': '5:45 Mins',
        'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'thumbnailColor1': '0xFFFF9E00',
        'thumbnailColor2': '0xFFFFD600',
      },
      {
        'title': 'Avoid Rejections & Screenouts',
        'duration': '3:10 Mins',
        'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'thumbnailColor1': '0xFF00B4D8',
        'thumbnailColor2': '0xFF00E5FF',
      },
    ];

    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tutorials.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = tutorials[index];
          return Container(
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final url = Uri.parse(item['url']!);
                try {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not launch tutorial video.')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch tutorial video.')),
                    );
                  }
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Color(int.parse(item['thumbnailColor1']!)),
                              Color(int.parse(item['thumbnailColor2']!)),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['duration']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item['title']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
