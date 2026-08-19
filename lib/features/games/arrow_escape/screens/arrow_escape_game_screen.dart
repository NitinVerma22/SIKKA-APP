import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

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

class _ArrowEscapeGameScreenState extends State<ArrowEscapeGameScreen> {
  final ArrowEscapeService _service = ArrowEscapeService();
  late ArrowEscapeGameState _gameState;
  final List<ArrowEscapeGameState> _history = [];

  bool _isLevelWon = false;
  bool _isGameOver = false;
  bool _isClaiming = false;
  bool _isAnimating = false;
  int _earnedCoins = 0;

  String? _activeHintArrowId;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initLevel() {
    _timer?.cancel();
    setState(() {
      _gameState = ArrowEscapeEngine.generateLevel(widget.levelNumber);
      _history.clear();
      _isLevelWon = false;
      _isGameOver = false;
      _isClaiming = false;
      _isAnimating = false;
      _earnedCoins = 0;
      _activeHintArrowId = null;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isLevelWon || _isGameOver) {
        t.cancel();
        return;
      }
      if (_gameState.remainingTimeSeconds > 0) {
        setState(() {
          _gameState.remainingTimeSeconds--;
        });
      } else {
        t.cancel();
        setState(() {
          _isGameOver = true;
        });
      }
    });
  }

  Future<void> _onCellTap(int row, int col) async {
    if (_isAnimating || _isLevelWon || _isGameOver) return;

    // Find arrow whose path contains (row, col)
    ArrowModel? targetArrow;
    for (final arrow in _gameState.arrows) {
      if (!arrow.isEscaping && arrow.path.any((pt) => pt[0] == row && pt[1] == col)) {
        targetArrow = arrow;
        break;
      }
    }

    if (targetArrow == null) return;

    setState(() {
      _isAnimating = true;
      _activeHintArrowId = null;
      _history.add(_gameState.clone());
    });

    ArrowEscapeAudioService.instance.playTapSfx();

    final bool canEscape = ArrowEscapeEngine.isPathClear(_gameState, targetArrow);

    if (canEscape) {
      // ESCAPE ANIMATION (Slide along winding path)
      for (double progress = 0.0; progress <= 1.0; progress += 0.1) {
        if (!mounted) return;
        setState(() {
          targetArrow!.animProgress = progress;
        });
        await Future.delayed(const Duration(milliseconds: 16));
      }

      ArrowEscapeAudioService.instance.playEscapeSfx();

      if (!mounted) return;
      setState(() {
        targetArrow!.isEscaping = true;
        targetArrow.animProgress = 0.0;
        _isAnimating = false;

        if (ArrowEscapeEngine.isLevelWon(_gameState)) {
          _onLevelComplete();
        }
      });
    } else {
      // COLLISION ANIMATION (Bump along path and bounce back)
      targetArrow.isColliding = true;

      for (double progress = 0.0; progress <= 1.0; progress += 0.2) {
        if (!mounted) return;
        setState(() {
          targetArrow!.animProgress = progress;
        });
        await Future.delayed(const Duration(milliseconds: 16));
      }

      ArrowEscapeAudioService.instance.playCollisionSfx();

      if (!mounted) return;
      setState(() {
        targetArrow!.isColliding = false;
        targetArrow.animProgress = 0.0;
        _gameState.livesCount--;
        _isAnimating = false;

        if (_gameState.livesCount <= 0) {
          _isGameOver = true;
        }
      });
    }
  }

  Future<void> _onLevelComplete() async {
    _timer?.cancel();
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
        backgroundColor: const Color(0xFF111318),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar Header matching screenshot
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _handleExit,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'CLASSIC - LVL ${widget.levelNumber}',
                          style: const TextStyle(
                            fontFamily: 'BebasNeue',
                            color: Colors.white,
                            fontSize: 24,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Balance left icon
                  ],
                ),
              ),

              // Main Game Canvas
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

                      return GestureDetector(
                        onTapUp: (details) {
                          final double cellSize = math.min(canvasSize.width, canvasSize.height) / _gameState.gridSize;
                          final double padX = (canvasSize.width - (cellSize * _gameState.gridSize)) / 2.0;
                          final double padY = (canvasSize.height - (cellSize * _gameState.gridSize)) / 2.0;

                          final Offset pos = details.localPosition;
                          final int col = ((pos.dx - padX) / cellSize).floor();
                          final int row = ((pos.dy - padY) / cellSize).floor();

                          if (row >= 0 && row < _gameState.gridSize && col >= 0 && col < _gameState.gridSize) {
                            _onCellTap(row, col);
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

              // Bottom Control Bar matching screenshot
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    // Green Timer Progress Bar on bottom-left
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (_gameState.remainingTimeSeconds / _gameState.totalTimeSeconds).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 32),

                    // 3 White Heart Lives on bottom-right matching screenshot
                    Row(
                      children: List.generate(3, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            i < _gameState.livesCount ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: i < _gameState.livesCount ? Colors.white : const Color(0xFF475569),
                            size: 24,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Victory / Game Over Dialog Modal
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
                      _isLevelWon ? 'LEVEL CLEARED!' : 'GAME OVER',
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        color: Colors.white,
                        fontSize: 32,
                        letterSpacing: 2,
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
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
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
                        style: const TextStyle(
                          fontFamily: 'BebasNeue',
                          color: Colors.white,
                          fontSize: 20,
                          letterSpacing: 1.5,
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
}
