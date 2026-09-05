import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/games/shared/audio/game_audio.dart';
import 'package:sikkaplay/features/games/shared/widgets/double_back_exit.dart';
import 'package:sikkaplay/features/games/spin_earn/utils/reward_logic.dart';
import 'package:sikkaplay/features/games/spin_earn/widgets/fake_ad_dialog.dart';
import 'package:sikkaplay/features/games/spin_earn/widgets/spin_wheel.dart';
import 'package:sikkaplay/features/games/shared/widgets/game_banner_ad.dart';
import 'package:sikkaplay/core/ads/ad_service.dart';
import 'package:sikkaplay/features/games/shared/widgets/game_exit_button.dart';
import 'package:sikkaplay/features/games/shared/widgets/game_audio_toggle.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';

class SpinScreen extends ConsumerStatefulWidget {
  const SpinScreen({super.key});

  @override
  ConsumerState<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends ConsumerState<SpinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  
  String? _sessionId;
  bool _isSessionLoading = true;
  int _spinsLeft = 3;
  bool _isSpinning = false;
  double _currentAngle = 0;
  int _lastTickIndex = -1;
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  int? _lastWonBalance;

  @override
  void initState() {
    super.initState();
    GameAudio.init();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _spinAnimation = ConstantTween<double>(0.0).animate(_spinController);

    _spinController.addListener(_onSpinUpdate);
    _spinController.addStatusListener(_onSpinStatus);

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _elapsedSeconds++;
      if (_elapsedSeconds > 0 && _elapsedSeconds % 60 == 0) {
        ref.read(homeProvider.notifier).incrementGamesTime();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final response = await ref.read(userServiceProvider).startSpinSession();
      if (response != null && response['success'] == true) {
        if (mounted) {
          setState(() {
            _sessionId = response['sessionId'] as String?;
            _spinsLeft = response['spinsLeft'] as int? ?? 3;
            _isSessionLoading = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start game session. Exiting...')),
          );
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _onSpinUpdate() {
    _currentAngle = _spinAnimation.value;
  }

  void _onSpinStatus(AnimationStatus status) async {
    if (status == AnimationStatus.completed) {
      if (mounted) {
        setState(() {
          _isSpinning = false;
        });
        
        GameAudio.playSpinStop();
        
        // Add a tiny delay so the wheel appears to fully stop before the balance updates
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _handleWin();
        }
      }
    }
  }

  int? _lastWonReward;

  void _stopSpinOnError() {
    if (!mounted) return;
    _spinController.stop();
    setState(() {
      _isSpinning = false;
      _spinsLeft++; // Refund spin
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to spin. Please try again.')),
    );
  }

  void _startSpin() {
    if (_isSpinning) return;
    
    if (_spinsLeft <= 0) {
      _showNoSpinsPopup();
      return;
    }

    if (_sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game session not ready. Please wait.')),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _spinsLeft--;
    });

    GameAudio.playSpinStart();

    // Record starting time to enforce minimum spin duration
    final startTime = DateTime.now();

    // Start with smooth acceleration curve
    _spinAnimation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle + 30 * 2 * pi, // 30 rotations over 10s
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: const SpinStartCurve(),
    ));

    _spinController.duration = const Duration(seconds: 10);
    _lastTickIndex = -1;
    _spinController.forward(from: 0);

    // Call API in background
    ref.read(userProvider.notifier).spinWheel(_sessionId!, delayBalanceUpdate: true).then((response) async {
      if (response == null) {
        _stopSpinOnError();
        return;
      }

      final reward = response['reward'] as int;
      _lastWonReward = reward;
      _lastWonBalance = response['balance'] as int?;

      // Sync remaining spins immediately
      if (mounted) {
        setState(() {
          _spinsLeft = response['spinsLeft'] as int? ?? _spinsLeft;
        });
      }

      // Enforce minimum spin duration of 1.5 seconds for smooth acceleration
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      const minSpinMs = 1500;
      if (elapsed < minSpinMs) {
        await Future.delayed(Duration(milliseconds: minSpinMs - elapsed));
      }

      if (!mounted) return;

      // Find the slot index on the wheel for this reward
      final rewardIndex = RewardLogic.wheelSlots.indexWhere((item) => item.coins == reward);
      final targetIndex = rewardIndex >= 0 ? rewardIndex : 0;

      final sweepAngle = (2 * pi) / RewardLogic.wheelSlots.length;
      final segmentCenter = targetIndex * sweepAngle + (sweepAngle / 2);
      final targetBaseAngle = - (pi / 2) - segmentCenter;
      
      final currentAngle = _spinAnimation.value;
      final currentNormalized = currentAngle % (2 * pi);
      
      double distance = targetBaseAngle - currentNormalized;
      while (distance < 0) {
        distance += 2 * pi;
      }

      // Add at least 2 full rotations for a smooth decelerating ease-out effect
      final targetAngle = currentAngle + distance + (2 * 2 * pi);

      // Stop pre-spin
      _spinController.stop();

      // Start smooth slowdown animation to the target reward
      if (mounted) {
        setState(() {
          _spinAnimation = Tween<double>(
            begin: currentAngle,
            end: targetAngle,
          ).animate(CurvedAnimation(
            parent: _spinController,
            curve: Curves.easeOutCirc,
          ));
        });
      }

      _spinController.duration = const Duration(seconds: 3);
      _lastTickIndex = -1;
      _spinController.forward(from: 0);
    }).catchError((e) {
      _stopSpinOnError();
    });
  }

  void _handleWin() {
    GameAudio.playWin();
    if (_lastWonReward != null) {
      GameNotifications.showCoinUpdate(context, '+$_lastWonReward Sikka!');
    }
    if (_lastWonBalance != null) {
      ref.read(userProvider.notifier).updateLocalBalance(_lastWonBalance!);
    }
  }

  void _showGetSpinsAd() {
    final userState = ref.read(userProvider);
    final userId = userState.userData?['id'] ?? '';

    if (!AdService.instance.isInterstitialAdLoaded() || userId.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => FakeAdDialog(
          title: 'Playing Video Ad...',
          message: 'Watch video to get 3 Free Spins',
          onComplete: () async {
            if (_sessionId != null) {
              final response = await ref.read(userServiceProvider).recordSpinAd(_sessionId!);
              if (response != null && response['success'] == true) {
                if (mounted) {
                  setState(() {
                    _spinsLeft = response['spinsLeft'] as int? ?? 3;
                  });
                }
              }
            }
          },
        ),
      );
      if (userId.isNotEmpty) {
        AdService.instance.loadInterstitialAd();
      }
      return;
    }

    AdService.instance.showInterstitialAd(
      onAdDismissed: () async {
        if (_sessionId != null) {
          final response = await ref.read(userServiceProvider).recordSpinAd(_sessionId!);
          if (response != null && response['success'] == true) {
            if (mounted) {
              setState(() {
                _spinsLeft = response['spinsLeft'] as int? ?? 3;
              });
              GameNotifications.showCoinUpdate(context, '3 Spins Added!');
            }
          }
        }
      },
    );
  }

  void _showNoSpinsPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Get More Spins', style: TextStyle(color: Colors.white)),
        content: const Text('Spins are exhausted. Watch video to get more?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No Need', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showGetSpinsAd();
            },
            child: const Text('Watch Video', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    GameAudio.stopAll();
    _gameTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _exitGame() async {
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dContext) {
        dialogContext = dContext;
        return Dialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  'Thank you for playing!',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We are closing your session, please wait...',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      if (_sessionId != null) {
        await ref.read(userServiceProvider).endGameSession(_sessionId!);
      }
    } catch (e) {
      // ignore
    } finally {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBackExit(
      onExitConfirmed: () async {
        _exitGame();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1E113A), Colors.black],
              center: Alignment.center,
              radius: 1.0,
            ),
          ),
          child: SafeArea(
            child: _isSessionLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : Column(
                    children: [
                      const GameBannerAd(),
                      const SizedBox(height: 8),
                      // Top Header Section (Wallet & Spins)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const GameAudioToggle(),
                            // Spins Left Display
                            if (_spinsLeft > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$_spinsLeft Spins',
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: _showGetSpinsAd,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.primary),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.play_circle_outline, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Get Spins',
                                        style: GoogleFonts.orbitron(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Spin Wheel
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _spinAnimation,
                            builder: (context, child) {
                              return SpinWheelWidget(
                                rotationAngle: _spinAnimation.value,
                                isSpinning: _isSpinning,
                                onSpin: _startSpin,
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const GameExitButton(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class SpinStartCurve extends Curve {
  const SpinStartCurve();

  @override
  double transformInternal(double t) {
    // Accelerate smoothly for the first 1.5 seconds out of 10 seconds (t from 0 to 0.15)
    // and then go linear.
    const double accelEnd = 0.15;
    if (t < accelEnd) {
      // Quadratic acceleration: f(t) = a * t^2
      const double a = 1.0 / (accelEnd * (2.0 - accelEnd));
      return a * t * t;
    } else {
      const double a = 1.0 / (accelEnd * (2.0 - accelEnd));
      const double m = 2.0 * a * accelEnd;
      return m * (t - 1.0) + 1.0;
    }
  }
}
