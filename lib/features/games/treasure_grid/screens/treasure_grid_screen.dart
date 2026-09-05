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
import 'package:sikkaplay/features/games/shared/widgets/game_audio_toggle.dart';
import 'package:sikkaplay/features/games/shared/utils/game_claim_dialog.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TileType { coin, bomb }

class TileData {
  final TileType type;
  final int coins;
  bool isOpened;

  TileData({
    required this.type,
    this.coins = 0,
    this.isOpened = false,
  });
}

class TreasureGridScreen extends ConsumerStatefulWidget {
  const TreasureGridScreen({super.key});

  @override
  ConsumerState<TreasureGridScreen> createState() => _TreasureGridScreenState();
}

class _TreasureGridScreenState extends ConsumerState<TreasureGridScreen> {
  final List<TileData> _grid = [];
  bool _isRevealed = false;
  bool _isShuffling = false;
  
  String? _sessionId;
  int _picksLeft = 3;
  int _roundCoins = 0;
  bool _isPerfectStreak = true;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;
  bool _isTransitioning = false;
  bool _isRoundEnding = false;
  int _sessionCoins = 0;
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  bool _isSessionLoading = true;
  bool _isPaused = false;
  bool _isWaitingForPlayAgain = false;

  @override
  void initState() {
    super.initState();
    GameAudio.init();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final savedSession = prefs.getString('saved_session_treasure_grid');
      final savedCoins = prefs.getInt('saved_coins_treasure_grid') ?? 0;
      final savedTime = prefs.getInt('saved_time_treasure_grid') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      bool isExpired = false;
      if (savedTime > 0 && (now - savedTime) > 23 * 60 * 60 * 1000) {
        isExpired = true;
      }

      if (isExpired && savedSession != null && savedSession.isNotEmpty) {
        final clearAndStartNewSession = () async {
          await prefs.remove('saved_session_treasure_grid');
          await prefs.remove('saved_coins_treasure_grid');
          await prefs.remove('saved_time_treasure_grid');

          if (mounted) {
            setState(() {
              _isSessionLoading = true;
            });
          }
          final session = await ref.read(userServiceProvider).startGameSession('treasure_grid');
          if (session != null) {
            if (mounted) {
              setState(() {
                _sessionId = session;
                _isSessionLoading = false;
              });
              _startGame();
            }
            await prefs.setString('saved_session_treasure_grid', session);
            await prefs.setInt('saved_coins_treasure_grid', 0);
            await prefs.setInt('saved_time_treasure_grid', DateTime.now().millisecondsSinceEpoch);
          } else {
            if (mounted) {
              final selectedLanguage = ref.read(languageProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('failed_start_session', selectedLanguage))),
              );
              Navigator.of(context).pop();
            }
          }
        };

        if (savedCoins > 0 && mounted) {
          final selectedLanguage = ref.read(languageProvider);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.timer_off_outlined, color: Colors.amber, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    selectedLanguage == 'Hindi' ? 'सत्र समाप्त' : 'Session Expired',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Text(
                selectedLanguage == 'Hindi'
                    ? 'आपका पिछला गेम सत्र 23 घंटे से अधिक पुराना होने के कारण समाप्त हो गया है। उस सत्र के अनक्लेम किए गए सिक्के समाप्त हो गए हैं।'
                    : 'Your previous game session has expired (exceeded 23 hours). Unclaimed coins from that session have expired.',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    clearAndStartNewSession();
                  },
                  child: Text(
                    selectedLanguage == 'Hindi' ? 'ठीक है' : 'Start Fresh',
                    style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        } else {
          clearAndStartNewSession();
        }
      } else if (savedSession != null && savedSession.isNotEmpty && savedCoins > 0) {
        if (mounted) {
          setState(() {
            _sessionId = savedSession;
            _sessionCoins = savedCoins;
            _isSessionLoading = false;
          });
          _startGame();
        }
      } else {
        final session = await ref.read(userServiceProvider).startGameSession('treasure_grid');
        if (session != null) {
          if (mounted) {
            setState(() {
              _sessionId = session;
              _isSessionLoading = false;
            });
            _startGame();
          }
          await prefs.setString('saved_session_treasure_grid', session);
          await prefs.setInt('saved_coins_treasure_grid', 0);
          await prefs.setInt('saved_time_treasure_grid', DateTime.now().millisecondsSinceEpoch);
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

  void _saveProgress() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('saved_coins_treasure_grid', _sessionCoins);
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
    if (mounted) {
      Navigator.of(context).pop();
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

  @override
  void dispose() {
    GameAudio.stopAll();
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startNewRound() {
    _picksLeft = 3;
    _roundCoins = 0;
    _isPerfectStreak = true;
    _isTransitioning = false;
    _isRoundEnding = false;
    _countdownTimer?.cancel();
    _generateGrid();
    
    setState(() {
      _isRevealed = true;
      _isShuffling = false;
    });
    
    GameAudio.playTreasureBlockShow();

    // Briefly show the grid, then hide and shuffle
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || _isPaused || _isTransitioning) return;
      
      GameAudio.playTreasureBlockHide();
      
      setState(() {
        _isRevealed = false;
        _isShuffling = true;
      });
      
      // Shuffle delay
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted || _isPaused || _isTransitioning) return;
        setState(() {
          _grid.shuffle(Random());
          _isShuffling = false;
        });
      });
    });
  }

  void _generateGrid() {
    _grid.clear();
    final random = Random();
    // 1 to 3 negative bomb blocks
    final negativeBlocksCount = random.nextInt(3) + 1;
    int countMinus3 = 0;
    
    for (int i = 0; i < negativeBlocksCount; i++) {
      int penalty;
      // At most 2 tiles can have penalty 3 (-3)
      if (countMinus3 < 2 && random.nextDouble() < 0.25) {
        penalty = 3;
        countMinus3++;
      } else {
        penalty = random.nextInt(2) + 1; // 1 or 2
      }
      _grid.add(TileData(type: TileType.bomb, coins: -penalty));
    }
    
    final positiveBlocksCount = 9 - negativeBlocksCount;
    bool hasThreeCoinTile = false;

    for (int i = 0; i < positiveBlocksCount; i++) {
      int coinReward;
      // Exactly 1 tile in positive tiles gets 3 coins; rest get 1 or 2 coins
      if (!hasThreeCoinTile && (i == positiveBlocksCount - 1 || random.nextDouble() < 0.30)) {
        coinReward = 3;
        hasThreeCoinTile = true;
      } else {
        coinReward = random.nextInt(2) + 1; // 1 or 2 coins
      }
      _grid.add(TileData(type: TileType.coin, coins: coinReward));
    }
    _grid.shuffle(random);
  }

  void _onTileTap(int index) {
    if (_isRoundEnding || _isTransitioning || _isRevealed || _isShuffling || _picksLeft <= 0 || _grid[index].isOpened) {
      return;
    }

    if (_sessionCoins >= 35) {
      final selectedLanguage = ref.read(languageProvider);
      GameNotifications.showCoinUpdate(context, selectedLanguage == 'Hindi' ? 'गुल्लक भर गई! पहले दावा करें' : 'Gullak Full! Claim first', isPenalty: true);
      return;
    }

    setState(() {
      _grid[index].isOpened = true;
      _picksLeft--;
      
      if (_grid[index].type == TileType.bomb) {
        GameAudio.playTreasureBomb();
        final penalty = _grid[index].coins; // negative value, e.g. -1, -2, -3
        _roundCoins = _roundCoins + penalty;
        _isPerfectStreak = false;
        HapticFeedback.vibrate();
        GameNotifications.showCoinUpdate(context, '$penalty Sikka', isPenalty: true);
      } else {
        GameAudio.playTreasureCoin();
        final reward = _grid[index].coins;
        _roundCoins += reward;
        // Clamp to prevent exceeding Gullak limit
        if (_sessionCoins + _roundCoins > 35) {
          _roundCoins = 35 - _sessionCoins;
        }
        GameNotifications.showCoinUpdate(context, '+$reward Sikka (Round)');
      }
    });

    if (_picksLeft <= 0) {
      setState(() {
        if (_isPerfectStreak && _roundCoins > 0) {
          _roundCoins += 1;
          if (_sessionCoins + _roundCoins > 35) {
            _roundCoins = 35 - _sessionCoins;
          }
          GameNotifications.showCoinUpdate(context, 'Perfect Streak! +1 Sikka Bonus! 🔥');
        }
        _sessionCoins = max(0, min(35, _sessionCoins + _roundCoins));
        _isRoundEnding = true;
      });
      _saveProgress();

      _revealBoardSequentially();
    }
  }

  Future<void> _revealBoardSequentially() async {
    // 1. Wait 200ms before starting flip
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 2. Flip Column 2 (Right side: indices 2, 5, 8)
    setState(() {
      _grid[2].isOpened = true;
      _grid[5].isOpened = true;
      _grid[8].isOpened = true;
    });

    // Wait 200ms
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 3. Flip Column 1 (Middle: indices 1, 4, 7)
    setState(() {
      _grid[1].isOpened = true;
      _grid[4].isOpened = true;
      _grid[7].isOpened = true;
    });

    // Wait 200ms
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 4. Flip Column 0 (Left: indices 0, 3, 6)
    setState(() {
      _grid[0].isOpened = true;
      _grid[3].isOpened = true;
      _grid[6].isOpened = true;
    });

    // 5. Hold for 500ms
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (_sessionCoins >= 35) {
      _claimGullak();
      return;
    }

    // 6. Start transition countdown
    setState(() {
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
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: _isShuffling
            ? const CircularProgressIndicator(color: AppColors.primary)
            : const Icon(Icons.question_mark_rounded, color: Colors.white54, size: 48),
      ),
    );
  }

  Widget _buildFrontFace(TileData tile) {
    final isBomb = tile.type == TileType.bomb;
    return Container(
      decoration: BoxDecoration(
        color: isBomb
            ? Colors.red.withValues(alpha: 0.2)
            : Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBomb ? Colors.red : Colors.green,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isBomb ? Colors.red : Colors.green).withValues(alpha: 0.4),
            blurRadius: 10,
          )
        ],
      ),
      child: Center(
        child: isBomb
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.redAccent, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    '${tile.coins}',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.yellow, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    '+${tile.coins}',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTile(int index) {
    final tile = _grid[index];
    final bool showContent = _isRevealed || tile.isOpened;

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
                    transform: Matrix4.identity()..rotateY(pi), // mirror back to avoid reversed content
                    child: _buildFrontFace(tile),
                  )
                : _buildBackFace(),
          );
        },
      ),
    );
  }

  void _claimGullak() {
    if (_sessionCoins >= 35) {
      setState(() {
        _isPaused = true;
      });
      _gameTimer?.cancel();

      GameClaimDialog.show(
        context: context,
        ref: ref,
        sessionId: _sessionId,
        gameName: 'Treasure Grid',
        coinsEarned: _sessionCoins,
        onClaimCompleted: () {
          if (mounted) {
            setState(() {
              _sessionCoins = 0;
              _isPaused = true;
              _isWaitingForPlayAgain = true;
              _isSessionLoading = false;
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('saved_session_treasure_grid');
            await prefs.remove('saved_coins_treasure_grid');
            await prefs.remove('saved_time_treasure_grid');

            final session = await ref.read(userServiceProvider).startGameSession('treasure_grid');
            if (session != null) {
              if (mounted) {
                setState(() {
                  _sessionId = session;
                  _isSessionLoading = false;
                });
                _startGame();
              }
              await prefs.setString('saved_session_treasure_grid', session);
              await prefs.setInt('saved_coins_treasure_grid', 0);
              await prefs.setInt('saved_time_treasure_grid', DateTime.now().millisecondsSinceEpoch);
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
                      // Remaining Picks Indicator (Keys)
                      Row(
                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Icon(
                              index < _picksLeft ? Icons.vpn_key_rounded : Icons.vpn_key_outlined,
                              color: index < _picksLeft ? Colors.amberAccent : Colors.white24,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                      // Wallet
                      Row(
                        children: [
                          const GameAudioToggle(),
                          const SizedBox(width: 8),
                          GameGullakBar(
                            currentCoins: _sessionCoins,
                            maxCoins: 35,
                            onClaim: _claimGullak,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                
                // Status Text
                Text(
                  _isTransitioning || _isRoundEnding
                      ? context.tr('round_completed', selectedLanguage)
                      : _isRevealed
                          ? context.tr('memorize_board', selectedLanguage)
                          : _isShuffling
                              ? context.tr('shuffling', selectedLanguage)
                              : (_picksLeft > 1
                                  ? context.tr('pick_tiles_count', selectedLanguage).replaceAll('{count}', '$_picksLeft')
                                  : context.tr('pick_tile_count', selectedLanguage).replaceAll('{count}', '$_picksLeft')),
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                          children: [
                            GridView.builder(
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
                                          mainAxisAlignment: MainAxisAlignment.center,
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Early Claim Button
                if (!_isRoundEnding && !_isTransitioning && !_isRevealed && !_isShuffling && _picksLeft > 0 && _picksLeft < 3 && _roundCoins > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
                      label: Text(
                        context.tr('claim_sikka_next_round', selectedLanguage).replaceAll('{coins}', '$_roundCoins'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () {
                        setState(() {
                          _sessionCoins = max(0, min(35, _sessionCoins + _roundCoins));
                          _isRoundEnding = true;
                        });
                        _saveProgress();
                        GameNotifications.showCoinUpdate(context, 'Claimed +$_roundCoins Sikka!');
                        GameAudio.playCorrect();
                        
                        _revealBoardSequentially();
                      },
                    ),
                  ),

                const SizedBox(height: 8),
                if (_isWaitingForPlayAgain)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isWaitingForPlayAgain = false;
                                _startGame();
                                _resumeGame();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'PLAY AGAIN',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'EXIT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const GameExitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
