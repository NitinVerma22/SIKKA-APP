import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/shared/widgets/premium_button.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/ads/ad_service.dart';
import 'package:sikkaplay/features/games/spin_earn/widgets/fake_ad_dialog.dart';

class DailyStreakWidget extends ConsumerStatefulWidget {
  const DailyStreakWidget({super.key});

  @override
  ConsumerState<DailyStreakWidget> createState() => _DailyStreakWidgetState();
}

class _DailyStreakWidgetState extends ConsumerState<DailyStreakWidget> with SingleTickerProviderStateMixin {
  bool _isClaiming = false;
  late AnimationController _pulseController;
  late ScrollController _scrollController;
  bool _hasScrolledToActive = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int getCoinsForDay(int day) {
    if (day == 7) return 100;
    if (day == 14) return 150;
    if (day == 21) return 200;
    if (day == 28) return 500;
    if (day >= 29) return 150;
    return 10 + (day - 1) * 5;
  }

  void _claimStreak(int coins, int day) async {
    if (_isClaiming) return;

    final selectedLang = ref.read(languageProvider);
    final userState = ref.read(userProvider);
    final userId = userState.userData?['id'] ?? '';

    final executeClaim = () async {
      setState(() {
        _isClaiming = true;
      });

      final success = await ref.read(homeProvider.notifier).claimDailyStreak(coins, day);

      setState(() {
        _isClaiming = false;
      });

      if (success) {
        if (mounted) {
          _showSuccessDialog(context, coins, day, selectedLang);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('failed_claim_streak_retry', selectedLang)),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    };

    // Interstitial Ad ONLY on Day 29+ claim
    if (day >= 29) {
      if (!AdService.instance.isInterstitialAdLoaded()) {
        AdService.instance.loadInterstitialAd();
      }
      AdService.instance.showInterstitialAd(
        onAdDismissed: executeClaim,
      );
      return;
    }

    final isAdDay = (day == 7 || day == 14 || day == 21 || day == 28);

    if (!isAdDay) {
      executeClaim();
      return;
    }

    final showRewardedOrSimulation = () {
      if (!AdService.instance.isRewardedAdLoaded() || userId.isEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => FakeAdDialog(
            title: context.tr('daily_streak_rewards', selectedLang),
            message: context.tr('watch_video_claim_reward', selectedLang).replaceAll('{coins}', '$coins'),
            onComplete: executeClaim,
          ),
        );
        if (userId.isNotEmpty) {
          AdService.instance.loadRewardedAd();
        }
      } else {
        AdService.instance.showRewardedAd(
          context: context,
          userId: userId,
          onAdDismissed: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('ad_closed_early_warn', selectedLang))),
              );
            }
          },
          onUserEarnedReward: (reward) => executeClaim(),
        );
      }
    };

    if (!AdService.instance.isRewardedAdLoaded() && userId.isNotEmpty) {
      AdService.instance.loadRewardedAd();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (spinnerContext) {
          return _AdSpinnerDialog(
            selectedLanguage: selectedLang,
            onAdLoaded: () {
              Navigator.of(spinnerContext).pop();
              AdService.instance.showRewardedAd(
                context: context,
                userId: userId,
                onAdDismissed: () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('ad_closed_early_warn', selectedLang))),
                    );
                  }
                },
                onUserEarnedReward: (reward) => executeClaim(),
              );
            },
            onTimeout: () {
              Navigator.of(spinnerContext).pop();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => FakeAdDialog(
                  title: context.tr('daily_streak_rewards', selectedLang),
                  message: context.tr('watch_video_claim_reward', selectedLang).replaceAll('{coins}', '$coins'),
                  onComplete: executeClaim,
                ),
              );
            },
          );
        },
      );
    } else {
      showRewardedOrSimulation();
    }
  }

  void _showSuccessDialog(BuildContext context, int coins, int day, String selectedLanguage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DailyStreakSuccessDialog(coins: coins, day: day, selectedLanguage: selectedLanguage),
    );
  }

  void _showResumeDialog(BuildContext context, int cost, int skippedDays, int streakBefore, String selectedLang) {
    final isHindi = selectedLang == 'Hindi';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.history_toggle_off_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            Text(
              isHindi ? 'स्ट्रीक टूटने से बचाएं!' : 'Save Your Streak!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isHindi
              ? 'आपने $skippedDays दिन मिस कर दिए हैं। (Missed $skippedDays days. OK)\nक्या आप $cost सिक्के देकर अपनी $streakBefore दिनों की पुरानी स्ट्रीक जारी रखना चाहते हैं?\n\n(यदि नहीं, तो स्ट्रीक दिन 1 से रीसेट हो जाएगी)।'
              : 'Missed $skippedDays days. OK\n\nWould you like to resume your $streakBefore days streak for $cost coins?\n\n(If not, your streak will reset to Day 1).',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Reset to Day 1 by claiming normally
              final activeDay = 1;
              final activeCoins = getCoinsForDay(activeDay);
              _claimStreak(activeCoins, activeDay);
            },
            child: Text(
              isHindi ? 'रीसेट करें' : 'Reset to Day 1',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              setState(() {
                _isClaiming = true;
              });
              final success = await ref.read(homeProvider.notifier).resumeDailyStreak();
              setState(() {
                _isClaiming = false;
              });

              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isHindi
                          ? 'आपकी स्ट्रीक सफलतापूर्वक बहाल हो गई है! Missed $skippedDays days. OK'
                          : 'Streak resumed successfully! Missed $skippedDays days. OK'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isHindi ? 'स्ट्रीक बहाल करने में विफल। सिक्के जांचें!' : 'Failed to resume streak. Check your balance!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: Text(
              isHindi ? 'जारी रखें (-$cost)' : 'Resume (-$cost)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final userState = ref.watch(userProvider);
    final selectedLanguage = ref.watch(languageProvider);
    final streakCount = homeState.streakCount;
    final hasClaimedToday = homeState.hasClaimedToday;

    final isDataLoading = homeState.isLoading || userState.isLoading || userState.userData == null;

    // Server-authoritative day calculation:
    // If not claimed today, the active day user can claim is streakCount + 1
    // If claimed today, the active day user just claimed is streakCount.
    final int activeDay = hasClaimedToday ? streakCount : streakCount + 1;
    final int activeCoins = getCoinsForDay(activeDay);

    // Auto-scroll to active day once data finishes loading
    if (!isDataLoading && !_hasScrolledToActive) {
      _hasScrolledToActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final screenWidth = MediaQuery.of(context).size.width;
          final targetIndex = activeDay > 28 ? 29 : activeDay;
          final targetOffset = ((targetIndex - 1) * 64.0) - (screenWidth / 2) + 32.0;
          final maxScroll = _scrollController.position.maxScrollExtent;
          _scrollController.animateTo(
            targetOffset.clamp(0.0, maxScroll),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // Calculate current week (1 to 4)
    final int currentWeek = ((activeDay - 1) / 7).floor() + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.softCardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('daily_streak_rewards', selectedLanguage),
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('week_progress_label', selectedLanguage)
                        .replaceAll('{week}', '$currentWeek')
                        .replaceAll('{day}', '$streakCount'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: AppColors.primary, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      context.tr('days_label', selectedLanguage).replaceAll('{count}', '$streakCount'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Hero Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              children: [
                // Day reward text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDataLoading
                            ? context.tr('loading_reward', selectedLanguage)
                            : activeDay > 28
                                ? (selectedLanguage == 'Hindi' ? 'डेली बोनस रिवॉर्ड' : 'Daily Bonus Reward')
                                : context.tr('day_reward_title', selectedLanguage).replaceAll('{day}', '$activeDay'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isDataLoading ? '+--' : '+$activeCoins',
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 24),
                        ],
                      ),
                    ],
                  ),
                ),
                // Claim Button
                _isClaiming
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        ),
                      )
                    : hasClaimedToday
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('claimed_label', selectedLanguage),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isDataLoading ? 1.0 : (1.0 + (_pulseController.value * 0.05)),
                                child: child,
                              );
                            },
                            child: ElevatedButton(
                              onPressed: isDataLoading
                                  ? null
                                  : () {
                                      if (homeState.canStreakResume) {
                                        _showResumeDialog(
                                          context,
                                          homeState.streakResumeCost,
                                          homeState.skippedDaysCount,
                                          homeState.streakBeforeSkip,
                                          selectedLanguage,
                                        );
                                      } else {
                                        _claimStreak(activeCoins, activeDay);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDataLoading ? Colors.white24 : Colors.white,
                                foregroundColor: isDataLoading ? Colors.white38 : AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                elevation: isDataLoading ? 0 : 4,
                              ),
                              child: Text(
                                isDataLoading
                                    ? context.tr('loading_btn', selectedLanguage)
                                    : homeState.canStreakResume
                                        ? (selectedLanguage == 'Hindi' ? 'स्ट्रीक बहाल करें' : 'Resume Streak')
                                        : context.tr('claim_now', selectedLanguage),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                          ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal 28-day track (Scrollable)
          SizedBox(
            height: 90,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(activeDay > 28 ? 29 : 28, (index) {
                  final day = (index == 28) ? activeDay : index + 1;
                  final coins = getCoinsForDay(day);
                  
                  // Determine item status
                  final isClaimed = day < activeDay || (day == activeDay && hasClaimedToday);
                  final isActive = day == activeDay && !hasClaimedToday;
                  final isMilestone = day % 7 == 0 && index < 28;

                  return Container(
                    width: 56, // Bounded width for horizontal scrolling
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.06)
                          : isClaimed
                              ? const Color(0xFFE8F5E9)
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : isClaimed
                                ? Colors.green.shade200
                                : AppColors.borderLight,
                        width: isActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          index == 28 ? (selectedLanguage == 'Hindi' ? 'डेली' : 'Daily') : 'D$day',
                          style: TextStyle(
                            color: isActive
                                ? AppColors.primary
                                : isClaimed
                                    ? Colors.green.shade700
                                    : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          isClaimed
                              ? Icons.check_circle_rounded
                              : isMilestone
                                  ? Icons.redeem_rounded
                                  : Icons.monetization_on,
                          color: isClaimed
                              ? Colors.green.shade600
                              : isMilestone
                                  ? AppColors.accent
                                  : AppColors.yellowGlow,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+$coins',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Particle System Dialog for Premium Claims
class _DailyStreakSuccessDialog extends StatefulWidget {
  final int coins;
  final int day;
  final String selectedLanguage;

  const _DailyStreakSuccessDialog({required this.coins, required this.day, required this.selectedLanguage});

  @override
  State<_DailyStreakSuccessDialog> createState() => _DailyStreakSuccessDialogState();
}

class _DailyStreakSuccessDialogState extends State<_DailyStreakSuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final List<_CoinParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.update();
          }
        });
      });

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    );

    // Create 35 coin burst particles
    for (int i = 0; i < 35; i++) {
      _particles.add(
        _CoinParticle(
          x: 0,
          y: 0,
          vx: (_random.nextDouble() - 0.5) * 15,
          vy: (_random.nextDouble() - 0.6) * 18 - 4,
          gravity: 0.5,
        ),
      );
    }

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Particle layer
            CustomPaint(
              painter: _ParticlePainter(particles: _particles),
              size: const Size(300, 300),
            ),
            // Dialog Box
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E), // Dark gaming themed dialog
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Reward Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('claimed_success_burst', widget.selectedLanguage).replaceAll('{day}', '${widget.day}'),
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('claimed_success_desc', widget.selectedLanguage),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+' + context.tr('coins_suffix', widget.selectedLanguage).replaceAll('{coins}', '${widget.coins}'),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.monetization_on, color: AppColors.yellowGlow, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PremiumButton(
                      text: context.tr('awesome_btn', widget.selectedLanguage).toUpperCase(),
                      onTap: () => Navigator.of(context).pop(),
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

class _CoinParticle {
  double x;
  double y;
  double vx;
  double vy;
  double gravity;
  double opacity = 1.0;

  _CoinParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.gravity,
  });

  void update() {
    x += vx;
    y += vy;
    vy += gravity;
    opacity = max(0.0, opacity - 0.025);
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_CoinParticle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    for (var p in particles) {
      if (p.opacity <= 0) continue;
      
      // Draw golden circular coin
      paint.color = Colors.amber.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), 6, paint);
      
      // Draw inner core for detail
      paint.color = Colors.yellow.shade200.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), 3, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AdSpinnerDialog extends StatefulWidget {
  final String selectedLanguage;
  final VoidCallback onAdLoaded;
  final VoidCallback onTimeout;

  const _AdSpinnerDialog({
    required this.selectedLanguage,
    required this.onAdLoaded,
    required this.onTimeout,
  });

  @override
  State<_AdSpinnerDialog> createState() => _AdSpinnerDialogState();
}

class _AdSpinnerDialogState extends State<_AdSpinnerDialog> {
  Timer? _timer;
  int _elapsedMs = 0;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || _resolved) {
        timer.cancel();
        return;
      }
      _elapsedMs += 200;
      if (AdService.instance.isRewardedAdLoaded()) {
        _resolved = true;
        timer.cancel();
        widget.onAdLoaded();
      } else if (_elapsedMs >= 3000) {
        _resolved = true;
        timer.cancel();
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                widget.selectedLanguage == 'Hindi'
                    ? 'वीडियो विज्ञापन लोड हो रहा है...'
                    : 'Loading Video Ad...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
