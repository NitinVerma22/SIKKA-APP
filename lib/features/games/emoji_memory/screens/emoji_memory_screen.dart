import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/games/shared/audio/game_audio.dart';
import 'package:sikkaplay/features/games/shared/widgets/double_back_exit.dart';
import 'package:sikkaplay/features/games/shared/widgets/game_banner_ad.dart';
import 'package:sikkaplay/features/games/shared/widgets/game_exit_button.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:sikkaplay/features/games/shared/widgets/game_gullak_bar.dart';
import 'package:sikkaplay/features/games/shared/utils/game_claim_dialog.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';

class EmojiMemoryScreen extends ConsumerStatefulWidget {
  const EmojiMemoryScreen({super.key});

  @override
  ConsumerState<EmojiMemoryScreen> createState() => _EmojiMemoryScreenState();
}

class _EmojiMemoryScreenState extends ConsumerState<EmojiMemoryScreen> with TickerProviderStateMixin {
  final List<String> _allEmojis = [
    '🍎', '🍌', '🍇', '🍉', '🍓', '🍒', '🍑', '🥭', '🍍',
    '🥥', '🥝', '🍅', '🍆', '🥑', '🥦', '🥕', '🌽', '🌶️',
    '🍔', '🍟', '🍕', '🌭', '🥪', '🌮', '🌯', '🥗', '🍿',
  ];

  List<String> _grid = [];
  String _targetEmoji = '';
  
  final Set<int> _revealedIndices = {};
  final Set<int> _clickedWrongIndices = {};
  bool _isPreviewActive = false;
  
  String? _sessionId;
  int _wrongAttempts = 0;
  int _sessionCoins = 0;
  int _previewSecondsLeft = 5;
  bool _showSuccessTick = false;
  Timer? _previewTimer;
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  bool _isSessionLoading = true;
  bool _isPaused = false;
  
  bool _isRoundEnding = false;
  bool _isTransitioning = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    GameAudio.init();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_shakeController);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final savedSession = prefs.getString('saved_session_emoji_memory');
      final savedCoins = prefs.getInt('saved_coins_emoji_memory') ?? 0;

      if (savedSession != null && savedSession.isNotEmpty && savedCoins > 0) {
        if (mounted) {
          setState(() {
            _sessionId = savedSession;
            _sessionCoins = savedCoins;
            _isSessionLoading = false;
          });
          _startGame();
        }
      } else {
        final session = await ref.read(userServiceProvider).startGameSession('emoji_memory');
        if (session != null) {
          if (mounted) {
            setState(() {
              _sessionId = session;
              _isSessionLoading = false;
            });
            _startGame();
          }
          await prefs.setString('saved_session_emoji_memory', session);
          await prefs.setInt('saved_coins_emoji_memory', 0);
        } else {
          if (mounted) {
            final selectedLanguage = ref.read(languageProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('failed_start_session', selectedLanguage))),
            );
            Navigator.of(context).pop();
          }
        }
      }
    });
  }

  void _startGame() {
    _elapsedSeconds = 0;
    _startNewRound();

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) return;
      _elapsedSeconds++;
      if (_elapsedSeconds > 0 && _elapsedSeconds % 60 == 0) {
        ref.read(homeProvider.notifier).incrementGamesTime();
      }
    });
  }

  void _resumeGame() {
    if (_isPreviewActive && _previewSecondsLeft > 0) {
      _previewTimer?.cancel();
      _previewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _isPaused) return;
        setState(() {
          _previewSecondsLeft--;
          if (_previewSecondsLeft <= 0) {
            timer.cancel();
            _hideBoardSequentially();
          }
        });
      });
    }

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) return;
      _elapsedSeconds++;
      if (_elapsedSeconds > 0 && _elapsedSeconds % 60 == 0) {
        ref.read(homeProvider.notifier).incrementGamesTime();
      }
    });
  }

  Future<void> _exitGame() async {
    final selectedLanguage = ref.read(languageProvider);
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
                  context.tr('thank_you_playing', selectedLanguage),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('closing_session_wait', selectedLanguage),
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

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3.5,
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('setting_up_env', ref.read(languageProvider)),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('preparing_session', ref.read(languageProvider)),
              style: GoogleFonts.outfit(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewRound() async {
    if (!mounted) return;

    _allEmojis.shuffle();
    _grid = _allEmojis.take(9).toList();
    _targetEmoji = _grid[Random().nextInt(9)];
    
    _countdownTimer?.cancel();
    _previewTimer?.cancel();

    setState(() {
      _revealedIndices.clear();
      _clickedWrongIndices.clear();
      _isPreviewActive = true;
      _previewSecondsLeft = 5;
      _wrongAttempts = 0;
      _isRoundEnding = false;
      _isTransitioning = false;
    });

    // Sequential flip open (Left to Right)
    // Column 0: indices 0, 3, 6
    if (!mounted) return;
    setState(() {
      _revealedIndices.addAll([0, 3, 6]);
    });

    // Wait 150ms
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted || !_isPreviewActive) return;
    setState(() {
      _revealedIndices.addAll([1, 4, 7]);
    });

    // Wait 150ms
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted || !_isPreviewActive) return;
    setState(() {
      _revealedIndices.addAll([2, 5, 8]);
    });

    // Start preview countdown timer
    _previewTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) return;
      setState(() {
        _previewSecondsLeft--;
        if (_previewSecondsLeft <= 0) {
          timer.cancel();
          _hideBoardSequentially();
        }
      });
    });
  }

  Future<void> _hideBoardSequentially() async {
    if (!mounted) return;

    // Sequential flip closed (Right to Left)
    // Column 2: indices 2, 5, 8
    setState(() {
      _revealedIndices.removeAll([2, 5, 8]);
    });

    // Wait 150ms
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() {
      _revealedIndices.removeAll([1, 4, 7]);
    });

    // Wait 150ms
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() {
      _revealedIndices.removeAll([0, 3, 6]);
    });

    if (!mounted) return;
    setState(() {
      _isPreviewActive = false;
    });
  }

  void _onTileTap(int index) {
    if (_isRoundEnding || _isTransitioning || _isPreviewActive || _revealedIndices.contains(index)) {
      return;
    }

    if (_sessionCoins >= 50) {
      final selectedLanguage = ref.read(languageProvider);
      GameNotifications.showCoinUpdate(context, selectedLanguage == 'Hindi' ? 'गुल्लक भर गई! पहले दावा करें' : 'Gullak Full! Claim first', isPenalty: true);
      return;
    }

    final guessedEmoji = _grid[index];
    
    if (guessedEmoji == _targetEmoji) {
      GameAudio.playCorrect();
      
      int reward = 3;

      setState(() {
        _sessionCoins = (_sessionCoins + reward > 50) ? 50 : _sessionCoins + reward;
        _showSuccessTick = true;
        _isRoundEnding = true;
        _revealedIndices.add(index);
      });
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('saved_coins_emoji_memory', _sessionCoins);
      });

      GameNotifications.showCoinUpdate(context, '+$reward Sikka (Gullak)');
      
      if (_sessionCoins >= 50) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _claimGullak();
          }
        });
      } else {
        _revealBoardSequentially();
      }
    } else {
      // Wrong!
      GameAudio.playWrong();
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0.0);

      setState(() {
        _wrongAttempts++;
        _clickedWrongIndices.add(index);
        _revealedIndices.add(index);
      });

      GameNotifications.showCoinUpdate(context, '$_wrongAttempts/3 Strikes', isPenalty: true);
      
      if (_wrongAttempts >= 3) {
        setState(() {
          _isRoundEnding = true;
        });
        _revealBoardSequentially();
      }
    }
  }

  Future<void> _revealBoardSequentially() async {
    // 1. Wait 200ms before starting sequential reveal
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 2. Flip Column 2 (Right side: indices 2, 5, 8)
    setState(() {
      _revealedIndices.addAll([2, 5, 8]);
    });

    // Wait 200ms
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 3. Flip Column 1 (Middle: indices 1, 4, 7)
    setState(() {
      _revealedIndices.addAll([1, 4, 7]);
    });

    // Wait 200ms
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 4. Flip Column 0 (Left side: indices 0, 3, 6)
    setState(() {
      _revealedIndices.addAll([0, 3, 6]);
    });

    // 5. Hold for 500ms
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // 6. Start transition countdown
    setState(() {
      _showSuccessTick = false;
      _isTransitioning = true;
      _countdownSeconds = 3;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdownSeconds--;
        if (_countdownSeconds <= 0) {
          timer.cancel();
          _startNewRound();
        }
      });
    });
  }

  Widget _buildBackFace() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F0C29)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner casino frame border
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.question_mark_rounded,
              color: AppColors.primaryLight,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontFace(int index, String emoji) {
    final isTarget = emoji == _targetEmoji;
    final isWrongClicked = _clickedWrongIndices.contains(index);
    
    Color borderColor = AppColors.primary.withValues(alpha: 0.3);
    Color cardColor = const Color(0xFF1E1E2E); // Sleek dark card background
    List<BoxShadow> shadow = [];

    if (isTarget && _isRoundEnding) {
      // Highlight correct target card at end of round / when found
      borderColor = Colors.greenAccent;
      cardColor = Colors.green.withValues(alpha: 0.15);
      shadow = [
        BoxShadow(
          color: Colors.greenAccent.withValues(alpha: 0.4),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ];
    } else if (isWrongClicked) {
      // Crimson red for incorrect click
      borderColor = Colors.redAccent;
      cardColor = Colors.red.withValues(alpha: 0.15);
      shadow = [
        BoxShadow(
          color: Colors.redAccent.withValues(alpha: 0.4),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ];
    } else {
      // Neutral revealed card (during preview or normal reveal)
      borderColor = AppColors.primary.withValues(alpha: 0.5);
      cardColor = Colors.white.withValues(alpha: 0.05);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: shadow,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 34),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(int index) {
    final emoji = _grid[index];
    final bool showContent = _revealedIndices.contains(index);

    return GestureDetector(
      onTap: () => _onTileTap(index),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: showContent ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final angle = value * pi;
          final isBackFace = angle >= pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isBackFace
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi), // mirror contents
                    child: _buildFrontFace(index, emoji),
                  )
                : _buildBackFace(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _claimGullak() {
    if (_sessionCoins >= 50) {
      setState(() {
        _isPaused = true;
      });
      _previewTimer?.cancel();
      _gameTimer?.cancel();

      GameClaimDialog.show(
        context: context,
        ref: ref,
        sessionId: _sessionId,
        gameName: 'Emoji Memory',
        coinsEarned: _sessionCoins,
        onClaimCompleted: () {
          if (mounted) {
            setState(() {
              _sessionCoins = 0;
              _isPaused = false;
              _isSessionLoading = true;
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('saved_session_emoji_memory');
            await prefs.remove('saved_coins_emoji_memory');

            final session = await ref.read(userServiceProvider).startGameSession('emoji_memory');
            if (session != null) {
              if (mounted) {
                setState(() {
                  _sessionId = session;
                  _isSessionLoading = false;
                });
                _startGame();
              }
              await prefs.setString('saved_session_emoji_memory', session);
              await prefs.setInt('saved_coins_emoji_memory', 0);
            } else {
              if (mounted) {
                Navigator.of(context).pop();
              }
            }
          });
        },
        onContinue: () {
          if (mounted) {
            setState(() {
              _isPaused = false;
            });
            _resumeGame();
          }
        },
        onExit: () {
          _exitGame();
        },
        onCancel: () {
          if (mounted) {
            setState(() {
              _isPaused = false;
            });
            _resumeGame();
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);
    return DoubleBackExit(
      onExitConfirmed: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A24),
            title: Text(
              selectedLanguage == 'Hindi' ? 'गेम से बाहर निकलें?' : 'Exit Game?',
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              selectedLanguage == 'Hindi'
                  ? 'क्या आप गेम से बाहर निकलना चाहते हैं?'
                  : 'Do you want to exit?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  selectedLanguage == 'Hindi' ? 'रद्द करें' : 'Cancel',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  selectedLanguage == 'Hindi' ? 'बाहर निकलें' : 'Exit',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          _exitGame();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0C29),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: _isSessionLoading
                ? _buildLoadingScreen()
                : Column(
              children: [
                const GameBannerAd(),
                const SizedBox(height: 8),
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remaining Lives (Hearts)
                      Row(
                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Icon(
                              index < (3 - _wrongAttempts)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: index < (3 - _wrongAttempts) ? Colors.redAccent : Colors.white24,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      // Wallet
                      GameGullakBar(
                        currentCoins: _sessionCoins,
                        maxCoins: 50,
                        onClaim: _claimGullak,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Status Header / Target Emoji
                if (_isTransitioning || _isRoundEnding)
                  Column(
                    children: [
                      Text(
                        _wrongAttempts >= 3 ? context.tr('game_over', selectedLanguage) : context.tr('correct_guess', selectedLanguage),
                        style: GoogleFonts.orbitron(
                          color: _wrongAttempts >= 3 ? Colors.redAccent : Colors.greenAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else if (!_isPreviewActive)
                  Column(
                    children: [
                      Text(
                        context.tr('where_is_emoji', selectedLanguage),
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final glow = _pulseController.value;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.5 + 0.5 * glow),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4 * glow),
                                  blurRadius: 12 + 8 * glow,
                                  spreadRadius: 1 + 2 * glow,
                                )
                              ],
                            ),
                            child: Text(
                              _targetEmoji,
                              style: const TextStyle(fontSize: 36),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        context.tr('memorize', selectedLanguage),
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_previewSecondsLeft s',
                        style: GoogleFonts.orbitron(
                          color: AppColors.accent,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _shakeController,
                              builder: (context, child) {
                                final offset = _shakeController.isAnimating ? sin(_shakeAnimation.value * 4 * pi) * 12.0 : 0.0;
                                return Transform.translate(
                                  offset: Offset(offset, 0),
                                  child: GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: 9,
                                    itemBuilder: (context, index) {
                                      if (_grid.isEmpty) return const SizedBox.shrink();
                                      return _buildTile(index);
                                    },
                                  ),
                                );
                              },
                            ),
                            if (_isTransitioning)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey<int>(_countdownSeconds),
                                    tween: Tween<double>(begin: 1.5, end: 1.0),
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.bounceOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              context.tr('next_round_in', selectedLanguage),
                                              style: GoogleFonts.outfit(
                                                color: Colors.white70,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '$_countdownSeconds',
                                              style: GoogleFonts.orbitron(
                                                color: AppColors.accent,
                                                fontSize: 72,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (_showSuccessTick)
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 1.0, end: 0.0),
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.easeOutBack,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, value * 150),
                                      child: Opacity(
                                        opacity: (1 - value).clamp(0.0, 1.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.monetization_on,
                                              color: Colors.amber,
                                              size: 100,
                                              shadows: [
                                                Shadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 5))
                                              ],
                                            ),
                                            Text(
                                              '+3',
                                              style: GoogleFonts.orbitron(
                                                color: Colors.amber,
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  const Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2))
                                                ]
                                              ),
                                            )
                                          ]
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const GameExitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
