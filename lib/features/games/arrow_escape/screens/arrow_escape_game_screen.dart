import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/arrow_escape_models.dart';
import '../engine/arrow_escape_engine.dart';
import '../widgets/arrow_escape_painter.dart';
import '../services/arrow_escape_service.dart';
import '../../shared/widgets/game_banner_ad.dart';
import '../../../../core/ads/ad_service.dart';
import '../../../../features/profile/controllers/user_controller.dart';
import '../../../../core/user/user_service.dart';
import '../../shared/utils/game_notifications.dart';

class NativeArrowEscapeGameScreen extends ConsumerStatefulWidget {
  final int initialLevel;
  final int multiplier;
  final VoidCallback? onBack;

  const NativeArrowEscapeGameScreen({
    super.key,
    required this.initialLevel,
    this.multiplier = 2,
    this.onBack,
  });

  @override
  ConsumerState<NativeArrowEscapeGameScreen> createState() => _NativeArrowEscapeGameScreenState();
}

class _NativeArrowEscapeGameScreenState extends ConsumerState<NativeArrowEscapeGameScreen>
    with SingleTickerProviderStateMixin {
  final ArrowEscapeService _service = ArrowEscapeService();
  late int _currentLevelNum;
  late ArrowLevelModel _levelModel;
  late List<ArrowSnakeModel> _arrows;

  int _lives = 3;
  int _maxAllowedLives = 3;
  int _totalOriginalArrows = 0;
  String? _highlightedArrowId;

  bool _isLevelComplete = false;
  bool _isGameOver = false;
  bool _isClaiming = false;
  int _earnedCoins = 0;

  late AnimationController _animController;
  final List<ParticleModel> _particles = [];
  final Random _random = Random();
  String? _sessionId;

  late final Widget _cachedBannerAd;

  @override
  void initState() {
    super.initState();
    UserService().startGameSession('arrow_escape').then((id) {
      if (mounted) _sessionId = id;
    });
    _cachedBannerAd = const KeyedSubtree(
      key: ValueKey('cached_arrow_escape_banner'),
      child: RepaintBoundary(
        child: GameBannerAd(),
      ),
    );

    _currentLevelNum = widget.initialLevel;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_gameLoop);
    _animController.repeat();

    // Preload Rewarded & Interstitial Ads
    AdService.instance.loadRewardedAd();
    AdService.instance.loadInterstitialAd();

    _loadLevel(_currentLevelNum);
  }

  void _loadLevel(int levelNum) {
    _currentLevelNum = levelNum;
    _levelModel = ArrowEscapeEngine.generateLevel(levelNum);
    _arrows = List.from(_levelModel.arrows.map((a) => a.copyWith()));
    _totalOriginalArrows = _arrows.length;

    // Preload next Interstitial Ad for seamless level transitions
    AdService.instance.loadInterstitialAd();

    // Lives Scaling Rules:
    // Level 1-99: 3 Hearts
    // Level 100-149: 2 Hearts
    // Level 150+: 1 Heart
    if (levelNum >= 150) {
      _maxAllowedLives = 1;
    } else if (levelNum >= 100) {
      _maxAllowedLives = 2;
    } else {
      _maxAllowedLives = 3;
    }
    _lives = _maxAllowedLives;

    _highlightedArrowId = null;
    _isLevelComplete = false;
    _isGameOver = false;
    _isClaiming = false;
    _earnedCoins = 0;
    _particles.clear();
    setState(() {});
  }

  void _gameLoop() {
    bool needsStateUpdate = false;

    // Update arrow animations
    for (int i = _arrows.length - 1; i >= 0; i--) {
      final arrow = _arrows[i];

      if (arrow.isEscaping) {
        needsStateUpdate = true;
        // 3.0 Seconds Total Escape Speed at 60 FPS (1.0 / 180 frames = 0.00556)
        arrow.escapeProgress += 0.00556;
        if (arrow.escapeProgress >= 1.0) {
          // Arrow exited screen!
          final exitedKeyId = arrow.targetLockedId;
          final wasKey = arrow.isKey;
          _arrows.removeAt(i);

          // If Key Arrow escaped, unlock its matching Locked Arrow!
          if (wasKey && exitedKeyId != null) {
            for (final a in _arrows) {
              if (a.id == exitedKeyId) {
                a.isLocked = false; // Unlocked!
                break;
              }
            }
          }

          _checkWinCondition();
        }
      } else if (arrow.isBlockedShaking) {
        needsStateUpdate = true;
        arrow.shakeProgress += 0.12;
        if (arrow.shakeProgress >= 1.0) {
          arrow.isBlockedShaking = false;
          arrow.shakeProgress = 0.0;
        }
      }
    }

    // Update particles
    if (_particles.isNotEmpty) {
      needsStateUpdate = true;
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.position += p.velocity * 0.016;
        p.alpha -= 0.03;
        p.radius *= 0.96;
        if (p.alpha <= 0.0) {
          _particles.removeAt(i);
        }
      }
    }

    if (needsStateUpdate && mounted) {
      setState(() {});
    }
  }

  void _onCanvasTap(TapUpDetails details, double boardSize) {
    if (_isLevelComplete || _isGameOver) return;

    final cellSize = boardSize / _levelModel.gridSize;
    final tapX = (details.localPosition.dx / cellSize).floor();
    final tapY = (details.localPosition.dy / cellSize).floor();
    final tappedPt = Point2D(tapX, tapY);

    ArrowSnakeModel? tappedArrow;
    for (final arrow in _arrows) {
      if (arrow.isEscaping) continue;
      if (arrow.pathPoints.contains(tappedPt)) {
        tappedArrow = arrow;
        break;
      }
    }

    if (tappedArrow == null) return;

    // Check if tappedArrow is locked or path is blocked
    if (tappedArrow.isLocked) {
      tappedArrow.isBlockedShaking = true;
      tappedArrow.shakeProgress = -1.0;
      _lives--;
      if (_lives <= 0) _isGameOver = true;
      setState(() {});
      return;
    }

    final canEscape = ArrowEscapeEngine.canArrowEscape(
      tappedArrow,
      _arrows,
      _levelModel.deflectors,
      _levelModel.gridSize,
    );

    if (canEscape) {
      tappedArrow.isEscaping = true;
      tappedArrow.escapeProgress = 0.0;

      _spawnParticleBurst((tappedPt.x + 0.5) * cellSize, (tappedPt.y + 0.5) * cellSize, tappedArrow.color);
      _highlightedArrowId = null;
    } else {
      tappedArrow.isBlockedShaking = true;
      tappedArrow.shakeProgress = -1.0;

      _lives--;
      if (_lives <= 0) {
        _isGameOver = true;
      }
    }

    setState(() {});
  }

  void _spawnParticleBurst(double x, double y, Color color) {
    for (int i = 0; i < 18; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 100.0 + _random.nextDouble() * 160.0;
      _particles.add(ParticleModel(
        position: Offset(x, y),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        radius: 3.5 + _random.nextDouble() * 3.5,
      ));
    }
  }

  void _checkWinCondition() {
    if (_arrows.isEmpty && !_isLevelComplete) {
      _onLevelComplete();
    }
  }

  Future<void> _onLevelComplete() async {
    setState(() {
      _isLevelComplete = true;
      _isClaiming = true;
    });

    final progress = await _service.loadProgress();
    final int nextMax = _service.max(progress.maxUnlockedLevel, _currentLevelNum + 1);
    final Map<int, int> newStars = Map<int, int>.from(progress.starsMap);
    newStars[_currentLevelNum] = 3;
    await _service.saveLocalProgress(nextMax, newStars);

    final result = await _service.claimLevelReward(
      levelNumber: _currentLevelNum,
      stars: 3,
      score: 100,
      sessionId: _sessionId,
    );

    if (AdService.instance.isMilestoneLockLevel(_currentLevelNum)) {
      await AdService.instance.showMilestoneLockDialog(
        context: context,
        levelCleared: _currentLevelNum,
        userId: 'arrow_escape_user',
        onUnlocked: () {},
      );
    } else if (AdService.instance.isPost170Level(_currentLevelNum)) {
      await AdService.instance.showPost170RewardedDialog(
        context: context,
        levelCleared: _currentLevelNum,
        userId: 'arrow_escape_user',
        onEarned: () {},
      );
    } else if (AdService.instance.shouldShowLevelCompleteAd(_currentLevelNum)) {
      if (!AdService.instance.isInterstitialAdLoaded()) {
        AdService.instance.loadInterstitialAd();
      }
      AdService.instance.showInterstitialAd(onAdDismissed: () {});
    }

    final coins = result['coinsEarned'] ?? (_currentLevelNum * widget.multiplier);

    if (mounted) {
      setState(() {
        _earnedCoins = coins;
        _isClaiming = false;
      });
      ref.read(userProvider.notifier).addDirectCoins(_earnedCoins);
      GameNotifications.showCoinUpdate(context, '+$_earnedCoins Sikka');
    }
  }

  void _watchRewardedAdForLives() {
    if (!AdService.instance.isRewardedAdLoaded()) {
      AdService.instance.loadRewardedAd();
    }

    AdService.instance.showRewardedAd(
      context: context,
      userId: 'arrow_escape_user',
      onAdDismissed: () {},
      onUserEarnedReward: (reward) {
        if (mounted) {
          setState(() {
            _lives = 2; // Grant +2 Hearts
            _isGameOver = false;
          });
        }
      },
    );
  }

  void _onHintPressed() {
    final hintArrow = ArrowEscapeEngine.findSolvableArrow(
      _arrows,
      _levelModel.deflectors,
      _levelModel.gridSize,
    );
    if (hintArrow != null) {
      setState(() {
        _highlightedArrowId = hintArrow.id;
      });
    }
  }

  void _handleExit() {
    AdService.instance.showInterstitialAd(
      onAdDismissed: () {
        if (mounted) {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingArrows = _arrows.where((a) => !a.isEscaping).length;
    final progress = _totalOriginalArrows > 0
        ? (1.0 - (remainingArrows / _totalOriginalArrows)).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Banner Ad FIRST
                _cachedBannerAd,
                const SizedBox(height: 8),

                // Header Bar below Banner Ad
                _buildHeader(context),

                const Spacer(),

                // Canvas Area
                LayoutBuilder(
                  builder: (context, constraints) {
                    final boardSize = min(constraints.maxWidth - 32, constraints.maxHeight - 40);
                    return Center(
                      child: GestureDetector(
                        onTapUp: (details) => _onCanvasTap(details, boardSize),
                        child: SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: CustomPainterWidget(
                            painter: ArrowEscapePainter(
                              level: _levelModel,
                              arrows: _arrows,
                              highlightedArrowId: _highlightedArrowId,
                              particles: _particles,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Bottom Controls Bar
                _buildBottomControls(progress),
              ],
            ),

            // Level Complete Modal with Sikka Coin Rewards
            if (_isLevelComplete) _buildWinModal(),

            // Game Over Modal with Rewarded Ad Option
            if (_isGameOver) _buildGameOverModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _handleExit,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
          ),
          Text(
            'LEVEL $_currentLevelNum',
            style: GoogleFonts.bebasNeue(
              fontSize: 32,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
          Row(
            children: List.generate(_maxAllowedLives, (index) {
              return Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(
                  index < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: index < _lives ? const Color(0xFFFF1744) : Colors.white24,
                  size: 24,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Color(0xFF76ED12), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFF1E222B),
                    color: const Color(0xFF76ED12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E222B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleExit,
                icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFFF1744), size: 18),
                label: Text('EXIT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E222B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _loadLevel(_currentLevelNum),
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF), size: 18),
                label: Text('RESTART', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF76ED12),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _onHintPressed,
                icon: const Icon(Icons.lightbulb_rounded, color: Colors.black, size: 18),
                label: Text('HINT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinModal() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF181B22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF76ED12), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF76ED12).withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VICTORY! 🎉',
                style: GoogleFonts.bebasNeue(fontSize: 40, color: const Color(0xFF76ED12)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(Icons.star_rounded, color: Color(0xFFFFEA00), size: 36),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // COINS REWARD CONTAINER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF222733),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFEA00), width: 1.5),
                ),
                child: _isClaiming
                    ? const CircularProgressIndicator(color: Color(0xFFFFEA00))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFEA00), size: 28),
                          const SizedBox(width: 10),
                          Text(
                            '+$_earnedCoins COINS',
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFEA00),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF76ED12),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  AdService.instance.handleNextLevelTransition(
                    context: context,
                    currentLevel: _currentLevelNum,
                    gameName: 'arrow_escape',
                    onProceedToNextLevel: () => _loadLevel(_currentLevelNum + 1),
                  );
                },
                child: Text(
                  'NEXT LEVEL ➔',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverModal() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF181B22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF1744), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OUT OF LIVES! 💔',
                style: GoogleFonts.bebasNeue(fontSize: 36, color: const Color(0xFFFF1744)),
              ),
              const SizedBox(height: 8),
              Text(
                'Failed Level $_currentLevelNum',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 20),

              // WATCH REWARDED AD BUTTON (+2 HEARTS)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEA00),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _watchRewardedAdForLives,
                icon: const Icon(Icons.ondemand_video_rounded, color: Colors.black),
                label: Text(
                  'WATCH AD (+2 HEARTS ❤️)',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E222B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _loadLevel(_currentLevelNum),
                child: Text(
                  'RESTART LEVEL 🔄',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomPainterWidget extends StatelessWidget {
  final CustomPainter painter;
  const CustomPainterWidget({super.key, required this.painter});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: painter, child: Container());
  }
}
