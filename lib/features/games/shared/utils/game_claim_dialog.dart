import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/ads/ad_service.dart';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:sikkaplay/features/games/spin_earn/widgets/fake_ad_dialog.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/core/sync/sync_coordinator.dart';

class GameClaimDialog {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required String? sessionId,
    required String gameName,
    required int coinsEarned,
    required VoidCallback onClaimCompleted,
    required VoidCallback onContinue,
    required VoidCallback onExit,
    VoidCallback? onCancel,
  }) {
    final selectedLanguage = ref.read(languageProvider);

    // Read config sequence
    final configState = ref.read(appConfigProvider);
    final String sequenceStr = configState.config?['gullakAdSequence'] ?? 'interstitial,rewarded,none';
    final List<String> sequence = sequenceStr.split(',').map((e) => e.trim().toLowerCase()).toList();
    if (sequence.isEmpty) {
      sequence.add('rewarded');
    }

    final int claimsToday = ref.read(userProvider).userData?['gullakClaimsToday'] ?? 0;
    final String adType = sequence[claimsToday % sequence.length];

    final onCompleteClaim = () async {
      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('game_session_not_found_err', selectedLanguage))),
        );
        if (onCancel != null) onCancel();
        return;
      }

      final result = await ref.read(userServiceProvider).endGameSession(sessionId, coinsEarned: coinsEarned + 30);
      if (result != null && result['success'] == true) {
        final int coinsWon = result['coinsEarned'] ?? 0;
        ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
        onClaimCompleted();
        if (context.mounted) {
          _showPostClaimDialog(context, coinsWon, onContinue, onExit, selectedLanguage);
        }
      } else {
        if (context.mounted) {
          String err = selectedLanguage == 'Hindi' 
              ? 'पुरस्कार क्लेम करने में विफल। सत्र बहुत छोटा है?' 
              : 'Failed to claim reward. Session too short?';
          if (result != null && result['error'] != null) {
            err = result['error'];
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
        if (onCancel != null) onCancel();
      }
    };

    final showDirectClaimLoaderAndClaim = () async {
      if (sessionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('game_session_not_found_err', selectedLanguage))),
        );
        if (onCancel != null) onCancel();
        return;
      }

      // Show progress loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => Center(
          child: Card(
            color: const Color(0xFF1E1E2E),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('closing_session_wait', selectedLanguage),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final result = await ref.read(userServiceProvider).endGameSession(sessionId, coinsEarned: coinsEarned);
        
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        if (result != null && result['success'] == true) {
          final int coinsWon = result['coinsEarned'] ?? 0;
          ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
          onClaimCompleted();
          if (context.mounted) {
            _showPostClaimDialog(context, coinsWon, onContinue, onExit, selectedLanguage);
          }
        } else {
          if (context.mounted) {
            String err = selectedLanguage == 'Hindi' 
                ? 'पुरस्कार क्लेम करने में विफल। सत्र बहुत छोटा है?' 
                : 'Failed to claim reward. Session too short?';
            if (result != null && result['error'] != null) {
              err = result['error'];
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err)),
            );
          }
          if (onCancel != null) onCancel();
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Piggy Bank Image with Coins
                      Container(
                        height: 150,
                        width: 150,
                        child: Image.asset(
                          'assets/images/claim_gullak.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF5FF),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE9D5FF), width: 2),
                              ),
                              child: const Icon(
                                Icons.monetization_on_rounded,
                                color: Colors.amber,
                                size: 80,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title: Claim Your Gullak!
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '✨ ',
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            selectedLanguage == 'Hindi' ? 'गुल्लक क्लेम करें!' : 'Claim Your Gullak!',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1E1B4B),
                              fontSize: 26,
                              fontWeight: FontWeight.extrabold,
                            ),
                          ),
                          const Text(
                            ' ✨',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        selectedLanguage == 'Hindi'
                            ? 'शानदार काम! आपके सिक्का पुरस्कार आपका इंतजार कर रहे हैं।'
                            : 'Nice work! Your Sikka rewards are waiting for you.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // "Why claim now?" section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF3E8FF), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              selectedLanguage == 'Hindi' ? 'अभी क्लेम क्यों करें?' : 'Why claim now?',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF7C3AED),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Col 1: Earn 30 Coins
                                Expanded(
                                  child: _buildBenefitColumn(
                                    icon: Icons.monetization_on,
                                    iconColor: Colors.amber,
                                    iconBgColor: const Color(0xFFFEF3C7),
                                    title: selectedLanguage == 'Hindi' ? '30 सिक्के कमाएं' : 'Earn 30 Coins',
                                    desc: selectedLanguage == 'Hindi'
                                        ? 'वॉलेट में तुरंत'
                                        : 'Instant wallet reward',
                                  ),
                                ),
                                Container(height: 35, width: 1, color: const Color(0xFFE9D5FF)),
                                // Col 2: Extra Bonus
                                Expanded(
                                  child: _buildBenefitColumn(
                                    icon: Icons.play_circle_fill_rounded,
                                    iconColor: const Color(0xFF6366F1),
                                    iconBgColor: const Color(0xFFEEF2FF),
                                    title: selectedLanguage == 'Hindi' ? 'एक्स्ट्रा बोनस' : 'Extra Bonus',
                                    desc: selectedLanguage == 'Hindi'
                                        ? 'देखें और +30 पाएं'
                                        : 'Watch & get +30',
                                  ),
                                ),
                                Container(height: 35, width: 1, color: const Color(0xFFE9D5FF)),
                                // Col 3: Grow Faster
                                Expanded(
                                  child: _buildBenefitColumn(
                                    icon: Icons.bolt_rounded,
                                    iconColor: const Color(0xFF10B981),
                                    iconBgColor: const Color(0xFFECFDF5),
                                    title: selectedLanguage == 'Hindi' ? 'तेजी से बढ़ें' : 'Grow Faster',
                                    desc: selectedLanguage == 'Hindi'
                                        ? 'खेलें और जीतें'
                                        : 'Play & win big',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Option 1: Watch Short Ad (Highlighted)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(dialogContext).pop(); // Close choice dialog
                              
                              if (sessionId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(context.tr('game_session_not_found_err', selectedLanguage))),
                                );
                                if (onCancel != null) onCancel();
                                return;
                              }
           
                              final userId = ref.read(userProvider).userData?['id'] as String? ?? '';

                              if (adType == 'interstitial') {
                                AdService.instance.showInterstitialAd(
                                  onAdDismissed: onCompleteClaim,
                                );
                              } else {
                                // rewarded
                                final showRewardedOrSimulation = () {
                                  if (!AdService.instance.isRewardedAdLoaded() || userId.isEmpty) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => FakeAdDialog(
                                        title: context.tr('claiming_sikka_ad', selectedLanguage),
                                        message: context.tr('watch_video_claim_reward', selectedLanguage),
                                        onComplete: onCompleteClaim,
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
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(context.tr('ad_closed_early_warn', selectedLanguage))),
                                        );
                                        if (onCancel != null) onCancel();
                                      },
                                      onUserEarnedReward: (reward) {
                                        onCompleteClaim();
                                      },
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
                                        selectedLanguage: selectedLanguage,
                                        onAdLoaded: () {
                                          Navigator.of(spinnerContext).pop(); // dismiss spinner
                                          AdService.instance.showRewardedAd(
                                            context: context,
                                            userId: userId,
                                            onAdDismissed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(context.tr('ad_closed_early_warn', selectedLanguage))),
                                              );
                                              if (onCancel != null) onCancel();
                                            },
                                            onUserEarnedReward: (reward) {
                                              onCompleteClaim();
                                            },
                                          );
                                        },
                                        onTimeout: () {
                                          Navigator.of(spinnerContext).pop(); // dismiss spinner
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) => FakeAdDialog(
                                              title: context.tr('claiming_sikka_ad', selectedLanguage),
                                              message: context.tr('watch_video_claim_reward', selectedLanguage),
                                              onComplete: onCompleteClaim,
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
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Play icon in white circle
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Color(0xFF8B5CF6),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              selectedLanguage == 'Hindi' ? 'छोटा विज्ञापन देखें' : 'Watch Short Ad',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Yellow Badge: +30
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '+30 Bonus',
                                                style: GoogleFonts.outfit(
                                                  color: const Color(0xFFD97706),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.extrabold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          selectedLanguage == 'Hindi'
                                              ? 'छोटा वीडियो देखें और 30 सिक्के + 30 बोनस सिक्के पाएं!'
                                              : 'Watch a short video and get 30 coins + 30 bonus coins!',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFE0E7FF),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Watch Now Button
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      selectedLanguage == 'Hindi' ? 'देखें' : 'Watch Now',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF7C3AED),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Green "Best Value" Badge
                          Positioned(
                            top: -10,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                selectedLanguage == 'Hindi' ? 'सर्वोत्तम मूल्य' : 'Best Value',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Option 2: Spend 25 Sikka (Bypass)
                      InkWell(
                        onTap: () async {
                          Navigator.of(dialogContext).pop(); // Close choice dialog
                          
                          if (sessionId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('game_session_not_found_err', selectedLanguage))),
                            );
                            if (onCancel != null) onCancel();
                            return;
                          }

                          // Show progress loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (loadingContext) => Center(
                              child: Card(
                                color: const Color(0xFF1E1E2E),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(color: AppColors.primary),
                                      const SizedBox(height: 16),
                                      Text(
                                        context.tr('deducting_coins_claiming', selectedLanguage).replaceAll('{coins}', '25'),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          try {
                            final result = await ref.read(userServiceProvider).endGameSession(
                              sessionId,
                              coinsEarned: coinsEarned,
                              bypassFee: 25,
                            );
                            
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close loading dialog
                            }

                            if (result != null && result['success'] == true) {
                              final int coinsWon = result['coinsEarned'] ?? 0;
                              ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
                              onClaimCompleted();
                              if (context.mounted) {
                                _showPostClaimDialog(context, coinsWon - 25, onContinue, onExit, selectedLanguage);
                              }
                            } else {
                              if (context.mounted) {
                                String err = selectedLanguage == 'Hindi' 
                                    ? 'पुरस्कार क्लेम करने में विफल। सत्र बहुत छोटा है या अपर्याप्त बैलेंस है?' 
                                    : 'Failed to claim reward. Session too short or insufficient balance?';
                                if (result != null && result['error'] != null) {
                                  err = result['error'];
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(err)),
                                );
                              }
                              if (onCancel != null) onCancel();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close loading dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                            if (onCancel != null) onCancel();
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFEF3C7), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              // Thunderbolt circular container
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: Color(0xFFD97706),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedLanguage == 'Hindi' ? '25 सिक्का खर्च करें' : 'Spend 25 Sikka',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF78350F),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selectedLanguage == 'Hindi'
                                          ? 'विज्ञापन छोड़ें और तुरंत अपने 30 सिक्के क्लेम करें।'
                                          : 'Skip the ad and claim your 30 coins instantly.',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF92400E),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Spend Now Button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  selectedLanguage == 'Hindi' ? 'खर्च करें' : 'Spend Now',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Safe & Secure footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.gpp_good_rounded,
                            color: Color(0xFF6366F1),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            selectedLanguage == 'Hindi' ? 'सुरक्षित और विश्वसनीय • ' : 'Safe & Secure • ',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF4F46E5),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            selectedLanguage == 'Hindi'
                                ? 'हम आपके समय का सम्मान करते हैं।'
                                : 'We respect your time and privacy.',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Top Right Close Button
              Positioned(
                top: -12,
                right: -12,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    if (onCancel != null) onCancel();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF7C3AED),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildBenefitColumn({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String desc,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E1B4B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF6B7280),
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  static void _showPostClaimDialog(
    BuildContext context,
    int coins,
    VoidCallback onContinue,
    VoidCallback onExit,
    String selectedLanguage,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.success, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.3),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const Icon(Icons.monetization_on, color: Colors.yellow, size: 80),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('success_title', selectedLanguage),
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('gullak_claimed_desc', selectedLanguage).replaceAll('{coins}', '$coins'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(dialogContext); // close post claim dialog
                      AdService.instance.showInterstitialAd(
                        onAdDismissed: () {
                          onExit();
                        },
                      );
                    },
                    child: Text(context.tr('exit_btn', selectedLanguage), style: const TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () {
                      Navigator.pop(dialogContext); // close dialog
                      onContinue();
                    },
                    child: Text(context.tr('continue_btn', selectedLanguage), style: const TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
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
