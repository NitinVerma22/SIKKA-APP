import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/arrow_escape_engine.dart';
import '../models/arrow_escape_models.dart';
import '../services/arrow_escape_service.dart';
import '../services/arrow_escape_audio_service.dart';
import '../widgets/arrow_escape_painter.dart';
import '../../../../core/ads/ad_service.dart';

class ArrowEscapeGameScreen extends StatefulWidget {
  final int levelNumber;
  final int multiplier;

  const ArrowEscapeGameScreen({
    super.key,
    required this.levelNumber,
    this.multiplier = 2,
  });

  @override
  State<ArrowEscapeGameScreen> createState() => _ArrowEscapeGameScreenState();
}

class _ArrowEscapeGameScreenState extends State<ArrowEscapeGameScreen> with TickerProviderStateMixin {
  final ArrowEscapeService _service = ArrowEscapeService();
  late ArrowEscapeGameState _gameState;
  final List<ArrowEscapeGameState> _history = [];

  bool _isLevelWon = false;
  bool _isGameOver = false;
  bool _isClaiming = false;
  bool _isAnimating = false;
  int _earnedCoins = 0;

  String? _activeHintArrowId;

  // Power-up Usage Allocations
  int _freeHintsRemaining = 1;
  int _freeUndosRemaining = 1;

  @override
  void initState() {
    super.initState();
    ArrowEscapeAudioService.instance.startBgm();
    _initLevel();
  }

  @override
  void dispose() {
    ArrowEscapeAudioService.instance.stopBgm();
    super.dispose();
  }

  void _initLevel() {
    setState(() {
      _gameState = ArrowEscapeEngine.generateLevel(widget.levelNumber);
      _history.clear();
      _isLevelWon = false;
      _isGameOver = false;
      _isClaiming = false;
      _isAnimating = false;
      _earnedCoins = 0;
      _activeHintArrowId = null;
      _freeHintsRemaining = 1;
      _freeUndosRemaining = 1;
    });
  }

  void _showRewardedAdHelper(VoidCallback onEarned) {
    if (!AdService.instance.isRewardedAdLoaded()) {
      AdService.instance.loadRewardedAd();
    }

    AdService.instance.showRewardedAd(
      context: context,
      userId: 'arrow_escape_user',
      onAdDismissed: () {},
      onUserEarnedReward: (reward) {
        onEarned();
      },
    );
  }

  Future<void> _onCellTap(int row, int col, Size canvasSize) async {
    if (_isAnimating || _isLevelWon || _isGameOver) return;

    final targetNode = _gameState.grid[row][col];
    if (targetNode == null || targetNode.isEscaping) return;

    setState(() {
      _isAnimating = true;
      _activeHintArrowId = null;
      _history.add(_gameState.clone());
    });

    ArrowEscapeAudioService.instance.playLaunchSfx();

    final bool canEscape = ArrowEscapeEngine.isPathClear(_gameState, row, col);
    final vec = targetNode.dir.vector;

    if (canEscape) {
      // ESCAPE ANIMATION (Flight off-screen)
      final double flightDist = math.max(canvasSize.width, canvasSize.height) * 1.2;

      for (double t = 0.0; t <= 1.0; t += 0.08) {
        if (!mounted) return;
        setState(() {
          targetNode.flightOffset = Offset(vec.dx * flightDist * t, vec.dy * flightDist * t);
        });
        await Future.delayed(const Duration(milliseconds: 16));
      }

      ArrowEscapeAudioService.instance.playEscapeSfx();

      if (!mounted) return;
      setState(() {
        targetNode.isEscaping = true;
        targetNode.flightOffset = Offset.zero;
        _gameState.movesCount++;
        _gameState.score += 20;
        _isAnimating = false;

        if (ArrowEscapeEngine.isLevelWon(_gameState)) {
          _onLevelComplete();
        }
      });
    } else {
      // COLLISION ANIMATION (Bounce back & lose 1 heart life)
      final double bounceDist = 35.0;

      // Forward bump into collision
      for (double t = 0.0; t <= 1.0; t += 0.15) {
        if (!mounted) return;
        setState(() {
          targetNode.flightOffset = Offset(vec.dx * bounceDist * t, vec.dy * bounceDist * t);
        });
        await Future.delayed(const Duration(milliseconds: 16));
      }

      ArrowEscapeAudioService.instance.playCollisionSfx();

      // Bounce back to original tile
      for (double t = 1.0; t >= 0.0; t -= 0.15) {
        if (!mounted) return;
        setState(() {
          targetNode.flightOffset = Offset(vec.dx * bounceDist * t, vec.dy * bounceDist * t);
        });
        await Future.delayed(const Duration(milliseconds: 16));
      }

      if (!mounted) return;
      setState(() {
        targetNode.flightOffset = Offset.zero;
        _gameState.livesCount--;
        _isAnimating = false;

        if (_gameState.livesCount <= 0) {
          _isGameOver = true;
        }
      });
    }
  }

  void _handleUndo() {
    if (_history.isEmpty || _isAnimating || _isLevelWon || _isGameOver) return;

    if (_freeUndosRemaining > 0) {
      setState(() {
        _freeUndosRemaining--;
        _gameState = _history.removeLast();
        _activeHintArrowId = null;
      });
    } else {
      _showRewardedAdHelper(() {
        setState(() {
          _freeUndosRemaining++;
          _gameState = _history.removeLast();
          _activeHintArrowId = null;
        });
      });
    }
  }

  void _handleHint() {
    if (_isAnimating || _isLevelWon || _isGameOver) return;

    if (_freeHintsRemaining > 0) {
      final hintNode = ArrowEscapeEngine.findHint(_gameState);
      if (hintNode != null) {
        setState(() {
          _freeHintsRemaining--;
          _activeHintArrowId = hintNode.id;
        });
      }
    } else {
      _showRewardedAdHelper(() {
        final hintNode = ArrowEscapeEngine.findHint(_gameState);
        if (hintNode != null) {
          setState(() {
            _freeHintsRemaining++;
            _activeHintArrowId = hintNode.id;
          });
        }
      });
    }
  }

  void _handleAddLife() {
    if (_isAnimating || _isLevelWon) return;

    _showRewardedAdHelper(() {
      setState(() {
        _gameState.livesCount += 2;
        _isGameOver = false;
      });
    });
  }

  Future<void> _onLevelComplete() async {
    setState(() {
      _isLevelWon = true;
      _isClaiming = true;
    });

    final int stars = _gameState.livesCount >= 3 ? 3 : (_gameState.livesCount >= 2 ? 2 : 1);

    final progress = await _service.loadProgress();
    final int nextMax = _service.max(progress.maxUnlockedLevel, widget.levelNumber + 1);
    final Map<int, int> newStars = Map<int, int>.from(progress.starsMap);
    newStars[widget.levelNumber] = stars;
    await _service.saveLocalProgress(nextMax, newStars);

    final result = await _service.claimLevelReward(
      levelNumber: widget.levelNumber,
      stars: stars,
      score: _gameState.score,
    );

    if (widget.levelNumber % 10 == 0) {
      if (!AdService.instance.isInterstitialAdLoaded()) {
        AdService.instance.loadInterstitialAd();
      }
      AdService.instance.showInterstitialAd(onAdDismissed: () {});
    }

    if (mounted) {
      setState(() {
        _earnedCoins = result['coinsEarned'] ?? (widget.levelNumber * widget.multiplier);
        _isClaiming = false;
      });
    }
  }

  void _handleExit() {
    AdService.instance.showInterstitialAd(
      onAdDismissed: () {
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _handleExit,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${widget.levelNumber}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Hearts/Lives Counter
                    Row(
                      children: List.generate(3, (i) {
                        return Icon(
                          i < _gameState.livesCount ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: i < _gameState.livesCount ? const Color(0xFFF43F5E) : const Color(0xFF475569),
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          ArrowEscapeAudioService.instance.toggleMute();
                        });
                      },
                      icon: Icon(
                        ArrowEscapeAudioService.instance.isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Game Canvas Board
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

                      return GestureDetector(
                        onTapUp: (details) {
                          final double cellW = canvasSize.width / _gameState.cols;
                          final double cellH = canvasSize.height / _gameState.rows;
                          final double cellSize = math.min(cellW, cellH);
                          final double padX = (canvasSize.width - (cellSize * _gameState.cols)) / 2.0;
                          final double padY = (canvasSize.height - (cellSize * _gameState.rows)) / 2.0;

                          final Offset pos = details.localPosition;
                          final int col = ((pos.dx - padX) / cellSize).floor();
                          final int row = ((pos.dy - padY) / cellSize).floor();

                          if (row >= 0 && row < _gameState.rows && col >= 0 && col < _gameState.cols) {
                            _onCellTap(row, col, canvasSize);
                          }
                        },
                        child: CustomPaint(
                          size: canvasSize,
                          painter: ArrowEscapePainter(
                            state: _gameState,
                            hintArrowId: _activeHintArrowId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Power-ups Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPowerUpBtn(
                      icon: Icons.lightbulb_rounded,
                      label: 'Hint',
                      badge: _freeHintsRemaining > 0 ? 'Free' : 'Ad',
                      onTap: _handleHint,
                    ),
                    _buildPowerUpBtn(
                      icon: Icons.undo_rounded,
                      label: 'Undo',
                      badge: _freeUndosRemaining > 0 ? 'Free' : 'Ad',
                      onTap: _handleUndo,
                    ),
                    _buildPowerUpBtn(
                      icon: Icons.favorite_rounded,
                      label: '+Lives ❤️',
                      badge: 'Ad 📺',
                      isAdRequired: true,
                      onTap: _handleAddLife,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Victory / Game Over Overlay Modal
        bottomSheet: (_isLevelWon || _isGameOver)
            ? Container(
                height: 320,
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isLevelWon ? const Color(0xFF0F766E) : const Color(0xFF450A0A),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLevelWon ? '🎉' : '💔', style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      _isLevelWon ? 'LEVEL CLEARED!' : 'OUT OF LIVES!',
                      style: GoogleFonts.outfit(
                        color: _isLevelWon ? const Color(0xFFFACC15) : const Color(0xFFF87171),
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLevelWon) ...[
                      if (_isClaiming)
                        const CircularProgressIndicator(color: Color(0xFFFACC15))
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF34D399)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                '+$_earnedCoins Sikka Coins',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF34D399),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLevelWon ? const Color(0xFF0D9488) : const Color(0xFFDC2626),
                        minimumSize: const Size(200, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (_isLevelWon) {
                          AdService.instance.showInterstitialAd(
                            onAdDismissed: () {
                              if (!mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArrowEscapeGameScreen(
                                    levelNumber: widget.levelNumber + 1,
                                    multiplier: widget.multiplier,
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          _initLevel();
                        }
                      },
                      child: Text(
                        _isLevelWon ? 'NEXT LEVEL' : 'RETRY LEVEL',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPowerUpBtn({
    required IconData icon,
    required String label,
    required String badge,
    bool isAdRequired = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isAdRequired
              ? const Color(0xFF0D9488).withValues(alpha: 0.2)
              : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdRequired
                ? const Color(0xFF2DD4BF).withValues(alpha: 0.5)
                : const Color(0xFF475569),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isAdRequired ? const Color(0xFF2DD4BF) : Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isAdRequired
                    ? const Color(0xFF0D9488)
                    : (badge == 'Free' ? const Color(0xFF059669) : const Color(0xFFD97706)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
