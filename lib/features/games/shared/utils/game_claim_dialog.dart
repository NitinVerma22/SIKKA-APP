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
        }
        if (onCancel != null) onCancel();
      }
    };

    if (adType == 'none') {
      showDirectClaimLoaderAndClaim();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.yellow,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  context.tr('claim_gullak', selectedLanguage),
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  adType == 'interstitial'
                      ? (selectedLanguage == 'Hindi'
                          ? 'दावा करने के लिए छोटा विज्ञापन देखें:'
                          : 'Watch short ad to claim:')
                      : context.tr('claim_session_desc', selectedLanguage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Option: Watch Video
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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF8F00FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.yellowAccent,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                adType == 'interstitial'
                                    ? context.tr('watch_short_ad', selectedLanguage)
                                    : context.tr('watch_video_ad', selectedLanguage),
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedLanguage == 'Hindi'
                                    ? 'दावा करने के लिए वीडियो देखें, आपको 30 सिक्का बोनस मिलेगा, कुल ${coinsEarned + 30} सिक्का!'
                                    : 'Watch video to claim, you will get 30 coins bonus, total ${coinsEarned + 30} coins!',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 14),

                // Option: Spend 30 Coins to Bypass Video
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
                          _showPostClaimDialog(context, coinsWon - 25, onContinue, onExit, selectedLanguage); // Net coins won is coinsWon - 25
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
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E3E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('spend_sikka_title', selectedLanguage),
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('spend_sikka_desc', selectedLanguage),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Maybe Later / Continue playing
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close choice dialog
                  },
                  child: Text(
                    context.tr('maybe_later', selectedLanguage),
                    style: GoogleFonts.orbitron(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
