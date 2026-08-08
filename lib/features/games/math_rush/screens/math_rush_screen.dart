import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MathRushScreen extends ConsumerStatefulWidget {
  const MathRushScreen({super.key});

  @override
  ConsumerState<MathRushScreen> createState() => _MathRushScreenState();
}

class _MathRushScreenState extends ConsumerState<MathRushScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;

  String? _sessionId;
  int _sessionCoins = 0;
  int _gullakCoins = 0;
  bool _isSessionLoading = true;
  bool _isPaused = false;

  String _currentQuestion = '';
  int _correctAnswer = 0;
  List<int> _options = [];
  int? _selectedOption;
  bool _isAnswerEvaluated = false;

  Timer? _questionTimer;
  int _questionTimeLeft = 10;
  Timer? _gameTimer;
  int _elapsedSeconds = 0;

  final Random _random = Random();
  int _questionCount = 0;
  String _difficulty = 'easy';
  String _selectedDifficultyMode = 'default';
  int _questionTimeMax = 10;

  @override
  void initState() {
    super.initState();
    GameAudio.init();

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final savedSession = prefs.getString('saved_session_math_rush');
      final savedCoins = prefs.getInt('saved_coins_math_rush') ?? 0;
      final savedDifficulty = prefs.getString('saved_difficulty_math_rush');

      if (savedSession != null && savedSession.isNotEmpty) {
        if (mounted) {
          setState(() {
            _sessionId = savedSession;
            _gullakCoins = savedCoins;
            _sessionCoins = savedCoins;
            _isSessionLoading = false;
          });
          
          if (savedDifficulty != null && savedDifficulty.isNotEmpty) {
            setState(() {
              _selectedDifficultyMode = savedDifficulty;
            });
            _startGame();
          } else {
            _showDifficultySelectionDialog();
          }
        }
      } else {
        final session = await ref.read(userServiceProvider).startGameSession('math_rush');
        if (session != null) {
          if (mounted) {
            setState(() {
              _sessionId = session;
              _isSessionLoading = false;
            });
            _showDifficultySelectionDialog();
          }
          await prefs.setString('saved_session_math_rush', session);
          await prefs.setInt('saved_coins_math_rush', 0);
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
      prefs.setInt('saved_coins_math_rush', _gullakCoins);
    });
  }

  void _showDifficultySelectionDialog() {
    final selectedLanguage = ref.read(languageProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String tempSelection = 'default';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildDifficultyCard(String value, String title, String subtitle, Color color, IconData icon) {
              final isSelected = tempSelection == value;
              return GestureDetector(
                onTap: () {
                  setDialogState(() {
                    tempSelection = value;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? color.withValues(alpha: 0.15) 
                      : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : Colors.white10,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ] : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: color, size: 24),
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF161525),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Center(
                child: Text(
                  context.tr('select_difficulty', selectedLanguage),
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildDifficultyCard(
                      'default',
                      context.tr('difficulty_default_title', selectedLanguage),
                      context.tr('difficulty_default_desc', selectedLanguage),
                      AppColors.secondary,
                      Icons.star_rounded,
                    ),
                    buildDifficultyCard(
                      'easy',
                      context.tr('difficulty_easy_title', selectedLanguage),
                      context.tr('difficulty_easy_desc', selectedLanguage),
                      Colors.greenAccent,
                      Icons.child_care_rounded,
                    ),
                    buildDifficultyCard(
                      'medium',
                      context.tr('difficulty_medium_title', selectedLanguage),
                      context.tr('difficulty_medium_desc', selectedLanguage),
                      Colors.amberAccent,
                      Icons.psychology_rounded,
                    ),
                    buildDifficultyCard(
                      'hard',
                      context.tr('difficulty_hard_title', selectedLanguage),
                      context.tr('difficulty_hard_desc', selectedLanguage),
                      Colors.redAccent,
                      Icons.local_fire_department_rounded,
                    ),
                  ],
                ),
              ),
              actions: [
                Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedDifficultyMode = tempSelection;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('saved_difficulty_math_rush', tempSelection);
                        _startGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                      ),
                      child: Text(
                        selectedLanguage == 'Hindi' ? 'गेम शुरू करें' : 'Start Game',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startGame() {
    _elapsedSeconds = 0;
    _questionCount = 0;

    if (_selectedDifficultyMode == 'easy') {
      _difficulty = 'easy';
      _questionTimeMax = 10;
    } else if (_selectedDifficultyMode == 'medium') {
      _difficulty = 'medium';
      _questionTimeMax = 8;
    } else if (_selectedDifficultyMode == 'hard') {
      _difficulty = 'hard';
      _questionTimeMax = 6;
    } else {
      _difficulty = 'easy';
      _questionTimeMax = 10;
    }

    _timerController.duration = Duration(seconds: _questionTimeMax);
    _generateQuestion();

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
    if (_questionTimeLeft > 0 && !_isAnswerEvaluated) {
      _timerController.forward();
    }
    
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) return;
      setState(() {
        _questionTimeLeft--;
        if (_questionTimeLeft <= 0) {
          timer.cancel();
          _handleTimeout();
        }
      });
    });

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

  void _generateQuestion() {
    setState(() {
      _selectedOption = null;
      _isAnswerEvaluated = false;
      _questionTimeLeft = _questionTimeMax;
    });

    _timerController.duration = Duration(seconds: _questionTimeMax);
    _timerController.reset();
    _timerController.forward();

    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _questionTimeLeft--;
        if (_questionTimeLeft <= 0) {
          timer.cancel();
          _handleTimeout();
        }
      });
    });

    if (_difficulty == 'easy') {
      final ops = ['+', '-', '×'];
      final op = ops[_random.nextInt(ops.length)];
      int a, b;
      if (op == '+') {
        a = _random.nextInt(15) + 1;
        b = _random.nextInt(15) + 1;
        _correctAnswer = a + b;
        _currentQuestion = '$a + $b = ?';
      } else if (op == '-') {
        a = _random.nextInt(15) + 5;
        b = _random.nextInt(a - 1) + 1;
        _correctAnswer = a - b;
        _currentQuestion = '$a - $b = ?';
      } else {
        a = _random.nextInt(8) + 2;
        b = _random.nextInt(8) + 2;
        _correctAnswer = a * b;
        _currentQuestion = '$a × $b = ?';
      }
    } else if (_difficulty == 'medium') {
      final type = _random.nextInt(4);
      int a = _random.nextInt(8) + 2;
      int b = _random.nextInt(8) + 2;
      int c = _random.nextInt(15) + 2;
      
      if (type == 0) {
        _correctAnswer = a * b + c;
        _currentQuestion = '$a × $b + $c = ?';
      } else if (type == 1) {
        _correctAnswer = c + a * b;
        _currentQuestion = '$c + $a × $b = ?';
      } else if (type == 2) {
        if (a * b < c) c = a * b - 1;
        _correctAnswer = a * b - c;
        _currentQuestion = '$a × $b - $c = ?';
      } else {
        if (c < a * b) c = a * b + _random.nextInt(10) + 1;
        _correctAnswer = c - a * b;
        _currentQuestion = '$c - $a × $b = ?';
      }
    } else {
      final type = _random.nextInt(4);
      if (type == 0) {
        int a = _random.nextInt(10) + 2;
        int b = _random.nextInt(10) + 2;
        int c = _random.nextInt(8) + 2;
        _correctAnswer = (a + b) * c;
        _currentQuestion = '($a + $b) × $c = ?';
      } else if (type == 1) {
        int a = _random.nextInt(8) + 3;
        int b = _random.nextInt(15) + 5;
        int c = _random.nextInt(b - 2) + 1;
        _correctAnswer = a * (b - c);
        _currentQuestion = '$a × ($b - $c) = ?';
      } else if (type == 2) {
        int c = _random.nextInt(6) + 2;
        int quotient = _random.nextInt(8) + 2;
        int product = quotient * c;
        List<int> factors = [];
        for (int i = 1; i <= product; i++) {
          if (product % i == 0) factors.add(i);
        }
        int aFactorIndex = _random.nextInt(factors.length);
        int aVal = factors[aFactorIndex];
        int bVal = product ~/ aVal;
        _correctAnswer = quotient;
        _currentQuestion = '($aVal × $bVal) ÷ $c = ?';
      } else {
        int a = _random.nextInt(10) + 2;
        int b = _random.nextInt(10) + 2;
        int c = _random.nextInt(8) + 2;
        int d = _random.nextInt(8) + 2;
        if (a * b < c * d) {
          int temp = a; a = c; c = temp;
          temp = b; b = d; d = temp;
        }
        _correctAnswer = a * b - c * d;
        _currentQuestion = '$a × $b - $c × $d = ?';
      }
    }

    Set<int> opsSet = {_correctAnswer};
    while (opsSet.length < 4) {
      int offset = _random.nextInt(10) - 5;
      if (offset == 0) offset = 5;
      int fakeAns = _correctAnswer + offset;
      if (fakeAns >= 0) opsSet.add(fakeAns);
    }
    _options = opsSet.toList()..shuffle();
    setState(() {});
  }

  void _handleTimeout() {
    GameAudio.playWrong();
    setState(() {
      _sessionCoins = max(0, _sessionCoins - 10);
      _gullakCoins = max(0, _gullakCoins - 10);
    });
    _saveProgress();
    GameNotifications.showCoinUpdate(context, 'Timeout! -10 Sikka', isPenalty: true);
    
    _questionCount++;
    if (_selectedDifficultyMode == 'default' && _questionCount == 15) {
      _showLevelUpDialog('medium');
    } else if (_selectedDifficultyMode == 'default' && _questionCount == 30) {
      _showLevelUpDialog('hard');
    } else {
      _generateQuestion();
    }
  }

  void _checkAnswer(int answer) {
    if (_isAnswerEvaluated) return;

    setState(() {
      _isAnswerEvaluated = true;
      _selectedOption = answer;
    });

    _questionTimer?.cancel();
    _timerController.stop();

    if (answer == _correctAnswer) {
      GameAudio.playCorrect();
      
      int reward = 2;
      if (_selectedDifficultyMode == 'easy') {
        reward = 1;
      } else if (_selectedDifficultyMode == 'medium') {
        reward = 2;
      } else if (_selectedDifficultyMode == 'hard') {
        reward = 3;
      }

      if (_gullakCoins >= 50) {
        final selectedLanguage = ref.read(languageProvider);
        GameNotifications.showCoinUpdate(context, selectedLanguage == 'Hindi' ? 'गुल्लक भर गई! पहले दावा करें' : 'Gullak Full! Claim first', isPenalty: true);
        _claimGullak();
      } else {
        setState(() {
          _sessionCoins += reward;
          _gullakCoins = min(50, _gullakCoins + reward);
        });
        _saveProgress();
        GameNotifications.showCoinUpdate(context, '+$reward Sikka');
        if (_gullakCoins >= 50) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _claimGullak();
            }
          });
        }
      }
    } else {
      GameAudio.playWrong();
      setState(() {
        _sessionCoins = max(0, _sessionCoins - 1);
        _gullakCoins = max(0, _gullakCoins - 1);
      });
      _saveProgress();
      GameNotifications.showCoinUpdate(context, '-1 Sikka', isPenalty: true);
    }
    
    _questionCount++;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (_selectedDifficultyMode == 'default' && _questionCount == 15) {
          _showLevelUpDialog('medium');
        } else if (_selectedDifficultyMode == 'default' && _questionCount == 30) {
          _showLevelUpDialog('hard');
        } else {
          _generateQuestion();
        }
      }
    });
  }

  void _showLevelUpDialog(String newLevel) {
    setState(() {
      _difficulty = newLevel;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String title = '';
        String desc = '';
        Color levelColor = Colors.green;

        final selectedLanguage = ref.read(languageProvider);
        if (newLevel == 'medium') {
          title = context.tr('level_up', selectedLanguage) + ' ⚡';
          desc = context.tr('level_up_medium_desc', selectedLanguage);
          levelColor = const Color(0xFFF59E0B);
        } else {
          title = context.tr('level_up', selectedLanguage) + ' 🔥';
          desc = context.tr('level_up_hard_desc', selectedLanguage);
          levelColor = const Color(0xFFEF4444);
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Center(
            child: Text(
              title,
              style: GoogleFonts.orbitron(
                color: levelColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          content: Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _generateQuestion();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: levelColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                ),
                child: Text(
                  context.tr('lets_go', selectedLanguage),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _claimGullak() {
    if (_gullakCoins >= 50) {
      setState(() {
        _isPaused = true;
      });
      _timerController.stop();
      _questionTimer?.cancel();
      _gameTimer?.cancel();

      GameClaimDialog.show(
        context: context,
        ref: ref,
        sessionId: _sessionId,
        gameName: 'Math Rush',
        coinsEarned: _gullakCoins,
        onClaimCompleted: () {
          if (mounted) {
            setState(() {
              _gullakCoins = 0;
              _isPaused = false;
              _isSessionLoading = true;
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('saved_session_math_rush');
            await prefs.remove('saved_coins_math_rush');
            await prefs.remove('saved_difficulty_math_rush');

            final session = await ref.read(userServiceProvider).startGameSession('math_rush');
            if (session != null) {
              if (mounted) {
                setState(() {
                  _sessionId = session;
                  _isSessionLoading = false;
                });
                _startGame();
              }
              await prefs.setString('saved_session_math_rush', session);
              await prefs.setInt('saved_coins_math_rush', 0);
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
  void dispose() {
    _questionTimer?.cancel();
    _timerController.dispose();
    _gameTimer?.cancel();
    super.dispose();
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Wallet
                      GameGullakBar(
                        currentCoins: _gullakCoins,
                        maxCoins: 50,
                        onClaim: _claimGullak,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Timer Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AnimatedBuilder(
                    animation: _timerController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: 1.0 - _timerController.value,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _questionTimeLeft <= 3 ? Colors.red : Colors.greenAccent,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Question Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _currentQuestion,
                      style: GoogleFonts.orbitron(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Options Grid
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _options.length,
                    itemBuilder: (context, index) {
                      final option = _options[index];
                      
                      Color gradientStart = const Color(0xFF00C6FF);
                      Color gradientEnd = const Color(0xFF0072FF);
                      Color shadowColor = const Color(0xFF0072FF);
                      
                      if (_isAnswerEvaluated) {
                        if (option == _correctAnswer) {
                          gradientStart = Colors.greenAccent;
                          gradientEnd = Colors.green;
                          shadowColor = Colors.green;
                        } else if (option == _selectedOption) {
                          gradientStart = Colors.redAccent;
                          gradientEnd = Colors.red;
                          shadowColor = Colors.red;
                        } else {
                          gradientStart = Colors.grey;
                          gradientEnd = Colors.blueGrey;
                          shadowColor = Colors.transparent;
                        }
                      }

                      return GestureDetector(
                        onTap: () => _checkAnswer(option),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [gradientStart, gradientEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$option',
                              style: GoogleFonts.orbitron(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
