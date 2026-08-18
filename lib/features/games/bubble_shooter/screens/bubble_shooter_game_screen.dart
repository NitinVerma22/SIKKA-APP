import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/bubble_shooter_engine.dart';
import '../models/bubble_shooter_models.dart';
import '../services/bubble_shooter_service.dart';
import '../services/bubble_shooter_audio_service.dart';
import '../widgets/bubble_shooter_painter.dart';
import '../../../../core/ads/ad_service.dart';

class BubbleShooterGameScreen extends StatefulWidget {
  final int levelNumber;
  final int multiplier;

  const BubbleShooterGameScreen({
    super.key,
    required this.levelNumber,
    this.multiplier = 2,
  });

  @override
  State<BubbleShooterGameScreen> createState() => _BubbleShooterGameScreenState();
}

class _BubbleShooterGameScreenState extends State<BubbleShooterGameScreen> with SingleTickerProviderStateMixin {
  final BubbleShooterService _service = BubbleShooterService();
  late BubbleShooterGameState _gameState;
  final List<BubbleShooterGameState> _history = [];

  bool _isLevelWon = false;
  bool _isGameOver = false;
  bool _isClaiming = false;
  bool _isShooting = false;
  int _earnedCoins = 0;

  // Active Shot Animation
  Offset? _shotPos;
  int? _shotColor;

  // Power-up Usage Allocations
  int _freeAimGuidesRemaining = 1;
  int _freeUndosRemaining = 1;
  int _bombBubblesUsed = 0;
  bool _isBombActive = false;

  @override
  void initState() {
    super.initState();
    BubbleShooterAudioService.instance.startBgm();
    _initLevel();
  }

  @override
  void dispose() {
    BubbleShooterAudioService.instance.stopBgm();
    super.dispose();
  }

  void _initLevel() {
    setState(() {
      _gameState = BubbleShooterEngine.generateLevel(widget.levelNumber);
      _history.clear();
      _isLevelWon = false;
      _isGameOver = false;
      _isClaiming = false;
      _isShooting = false;
      _earnedCoins = 0;
      _shotPos = null;
      _shotColor = null;
      _freeAimGuidesRemaining = 1;
      _freeUndosRemaining = 1;
      _bombBubblesUsed = 0;
      _isBombActive = false;
    });
  }

  void _showRewardedAdHelper(VoidCallback onEarned) {
    if (!AdService.instance.isRewardedAdLoaded()) {
      AdService.instance.loadRewardedAd();
    }

    AdService.instance.showRewardedAd(
      context: context,
      userId: 'bubble_shooter_user',
      onAdDismissed: () {},
      onUserEarnedReward: (reward) {
        onEarned();
      },
    );
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    if (_isShooting || _isLevelWon || _isGameOver) return;

    final Offset cannonCenter = Offset(canvasSize.width * 0.5, canvasSize.height - 70);
    final Offset touchPos = details.localPosition;

    // Check if user tapped on the Upcoming Bubbles Queue (holder pos left of cannon)
    final Offset holderPos = Offset(cannonCenter.dx - 110, cannonCenter.dy);
    if ((touchPos - holderPos).distance <= 50) {
      _swapUpcomingBubble(0);
      return;
    }

    final double dx = touchPos.dx - cannonCenter.dx;
    final double dy = touchPos.dy - cannonCenter.dy;

    double angle = math.atan2(dx, -dy);
    angle = angle.clamp(-1.2, 1.2);

    setState(() {
      _gameState.cannonAngle = angle;
    });
  }

  void _swapUpcomingBubble(int index) {
    if (_isShooting || _isLevelWon || _isGameOver) return;
    if (index >= 0 && index < _gameState.upcomingShotColors.length) {
      setState(() {
        final selectedColor = _gameState.upcomingShotColors[index];
        _gameState.upcomingShotColors[index] = _gameState.currentShotColor;
        _gameState.currentShotColor = selectedColor;
      });
    }
  }

  Future<void> _fireShot(Size canvasSize) async {
    if (_isShooting || _isLevelWon || _isGameOver || _gameState.shotsRemaining <= 0) return;

    setState(() {
      _isShooting = true;
      _history.add(_gameState.clone());
    });

    BubbleShooterAudioService.instance.playShootSfx();

    final double bubbleRadius = (canvasSize.width / (BubbleShooterEngine.cols + 0.5)) / 2.0;
    final double bubbleDiameter = bubbleRadius * 2.0;
    final double rowHeight = bubbleDiameter * 0.866;

    final Offset cannonCenter = Offset(canvasSize.width * 0.5, canvasSize.height - 70);
    double curX = cannonCenter.dx;
    double curY = cannonCenter.dy;
    double dirX = math.sin(_gameState.cannonAngle);
    double dirY = -math.cos(_gameState.cannonAngle);

    final int shootingColor = _gameState.currentShotColor;
    final bool isBombShot = _isBombActive;

    // Animate shot trajectory flying with sub-step circle distance collision physics!
    while (curY > 10) {
      curX += dirX * 18;
      curY += dirY * 18;

      // Bounce off Left Wall
      if (curX - bubbleRadius <= 0) {
        dirX = -dirX;
        curX = bubbleRadius;
      }
      // Bounce off Right Wall
      else if (curX + bubbleRadius >= canvasSize.width) {
        dirX = -dirX;
        curX = canvasSize.width - bubbleRadius;
      }

      setState(() {
        _shotPos = Offset(curX, curY);
        _shotColor = shootingColor;
      });

      // True Circle-to-Circle collision check against all active grid bubbles!
      bool collided = false;
      for (int r = 0; r < _gameState.maxRows; r++) {
        final int maxC = (r % 2 == 1) ? _gameState.maxCols - 1 : _gameState.maxCols;
        final double rowY = r * rowHeight + bubbleRadius + 10;
        final bool isOdd = (r % 2 == 1);
        final double rowOffsetX = isOdd ? bubbleRadius : 0.0;

        for (int c = 0; c < maxC; c++) {
          if (_gameState.grid[r][c] != null) {
            final double bx = c * bubbleDiameter + bubbleRadius + rowOffsetX + 4;
            final double by = rowY;
            final double dist = math.sqrt((curX - bx) * (curX - bx) + (curY - by) * (curY - by));

            // Collision threshold: 2 * R * 0.88 (allows sliding through narrow gaps!)
            if (dist <= bubbleDiameter * 0.88) {
              collided = true;
              break;
            }
          }
        }
        if (collided) break;
      }

      // Check collision with existing grid bubble or top ceiling
      if (collided || curY <= bubbleRadius + 10) {
        // Find nearest empty hex grid cell (targetR, targetC) to (curX, curY)
        int targetR = ((curY - 10) / rowHeight).round().clamp(0, _gameState.maxRows - 1);
        final bool targetIsOdd = (targetR % 2 == 1);
        final double targetRowOffsetX = targetIsOdd ? bubbleRadius : 0.0;
        int targetC = ((curX - targetRowOffsetX - 4) / bubbleDiameter).round().clamp(0, targetIsOdd ? BubbleShooterEngine.cols - 2 : BubbleShooterEngine.cols - 1);

        // If target cell is occupied, find adjacent empty neighbor
        if (_gameState.grid[targetR][targetC] != null) {
          final neighbors = BubbleShooterEngine.getNeighbors(targetR, targetC, _gameState.maxRows, _gameState.maxCols);
          double minDistance = 999999.0;
          Point<int>? bestCell;

          for (final n in neighbors) {
            if (_gameState.grid[n.x][n.y] == null) {
              final double nRowY = n.x * rowHeight + bubbleRadius + 10;
              final bool nIsOdd = (n.x % 2 == 1);
              final double nRowOffsetX = nIsOdd ? bubbleRadius : 0.0;
              final double nx = n.y * bubbleDiameter + bubbleRadius + nRowOffsetX + 4;

              final double d = math.sqrt((curX - nx) * (curX - nx) + (curY - nRowY) * (curY - nRowY));
              if (d < minDistance) {
                minDistance = d;
                bestCell = n;
              }
            }
          }

          if (bestCell != null) {
            targetR = bestCell.x;
            targetC = bestCell.y;
          }
        }

        // Snap into target hex grid cell!
        _snapAndProcessPop(targetR, targetC, shootingColor, isBombShot);
        break;
      }

      await Future.delayed(const Duration(milliseconds: 14)); // ~70 FPS smooth flight
    }

    if (!mounted) return;

    setState(() {
      _shotPos = null;
      _shotColor = null;
      _isShooting = false;
      _isBombActive = false;
      _gameState.shotsRemaining--;
      _gameState.movesCount++;

      // Advance upcoming shot colors queue
      _gameState.currentShotColor = _gameState.upcomingShotColors.removeAt(0);
      final rng = math.Random();
      _gameState.upcomingShotColors.add(rng.nextInt(7));

      // Check win/loss condition
      if (BubbleShooterEngine.isLevelWon(_gameState)) {
        _onLevelComplete();
      } else if (_gameState.shotsRemaining <= 0) {
        _isGameOver = true;
      }
    });
  }

  void _snapAndProcessPop(int r, int c, int colorId, bool isBomb) {
    if (isBomb) {
      BubbleShooterAudioService.instance.playExplosionSfx();
      for (int i = r - 1; i <= r + 1; i++) {
        for (int j = c - 1; j <= c + 1; j++) {
          if (i >= 0 && i < _gameState.maxRows && j >= 0 && j < _gameState.maxCols) {
            _gameState.grid[i][j] = null;
          }
        }
      }
    } else {
      _gameState.grid[r][c] = BubbleNode(colorId: colorId, row: r, col: c);

      final cluster = BubbleShooterEngine.findCluster(_gameState, r, c);
      if (cluster.length >= 3) {
        BubbleShooterAudioService.instance.playPopSfx();
        for (final p in cluster) {
          _gameState.grid[p.x][p.y] = null;
          _gameState.score += 10;
        }

        final orphans = BubbleShooterEngine.findOrphanBubbles(_gameState);
        if (orphans.isNotEmpty) {
          BubbleShooterAudioService.instance.playExplosionSfx();
          for (final p in orphans) {
            _gameState.grid[p.x][p.y] = null;
            _gameState.score += 20;
          }
        }
      }
    }
  }

  void _handleUndo() {
    if (_history.isEmpty || _isShooting || _isLevelWon || _isGameOver) return;

    if (_freeUndosRemaining > 0) {
      setState(() {
        _freeUndosRemaining--;
        _gameState = _history.removeLast();
      });
    } else {
      _showRewardedAdHelper(() {
        setState(() {
          _freeUndosRemaining++;
          _gameState = _history.removeLast();
        });
      });
    }
  }

  void _handleAimGuide() {
    if (_isShooting || _isLevelWon || _isGameOver) return;

    if (_freeAimGuidesRemaining > 0) {
      setState(() {
        _freeAimGuidesRemaining--;
      });
    } else {
      _showRewardedAdHelper(() {
        setState(() {
          _freeAimGuidesRemaining++;
        });
      });
    }
  }

  void _handleAddBombBubble() {
    if (_isShooting || _isLevelWon || _isGameOver) return;

    _showRewardedAdHelper(() {
      setState(() {
        _isBombActive = true;
        _bombBubblesUsed++;
      });
    });
  }

  Future<void> _onLevelComplete() async {
    setState(() {
      _isLevelWon = true;
      _isClaiming = true;
    });

    final int stars = _gameState.shotsRemaining >= 10 ? 3 : (_gameState.shotsRemaining >= 5 ? 2 : 1);

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
          child: Stack(
            children: [
              // FULL SCREEN GAME CANVAS (NO BOTTOM NAVBAR, NO BOTTOM ADS!)
              Column(
                children: [
                  // Top Glass Floating Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        IconButton(
                          onPressed: () {
                            setState(() {
                              BubbleShooterAudioService.instance.toggleMute();
                            });
                          },
                          icon: Icon(
                            BubbleShooterAudioService.instance.isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Shots Left Counter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF38BDF8)),
                          ),
                          child: Text(
                            'Shots: ${_gameState.shotsRemaining}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF38BDF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Full Canvas Board
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

                        return GestureDetector(
                          onPanUpdate: (d) => _onPanUpdate(d, canvasSize),
                          onPanEnd: (_) => _fireShot(canvasSize),
                          onTapUp: (details) {
                            _onPanUpdate(DragUpdateDetails(globalPosition: details.globalPosition, localPosition: details.localPosition), canvasSize);
                            _fireShot(canvasSize);
                          },
                          child: CustomPaint(
                            size: canvasSize,
                            painter: BubbleShooterPainter(
                              state: _gameState,
                              cannonAngle: _gameState.cannonAngle,
                              showAimGuide: _freeAimGuidesRemaining > 0,
                              shotBubblePos: _shotPos,
                              shotBubbleColor: _shotColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Power-ups Glass Bar (Above Bottom Edge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPowerUpBtn(
                          icon: Icons.alt_route_rounded,
                          label: 'Aim Guide',
                          badge: _freeAimGuidesRemaining > 0 ? 'Free' : 'Ad',
                          onTap: _handleAimGuide,
                        ),
                        _buildPowerUpBtn(
                          icon: Icons.undo_rounded,
                          label: 'Undo',
                          badge: _freeUndosRemaining > 0 ? 'Free' : 'Ad',
                          onTap: _handleUndo,
                        ),
                        _buildPowerUpBtn(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Bomb 💣',
                          badge: 'Ad 📺',
                          isAdRequired: true,
                          onTap: _handleAddBombBubble,
                        ),
                      ],
                    ),
                  ),
                ],
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
                  color: _isLevelWon ? const Color(0xFF1E1B4B) : const Color(0xFF450A0A),
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
                      _isLevelWon ? 'LEVEL CLEARED!' : 'OUT OF SHOTS!',
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
                        backgroundColor: _isLevelWon ? const Color(0xFF0284C7) : const Color(0xFFDC2626),
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
                                  builder: (context) => BubbleShooterGameScreen(
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
              ? const Color(0xFF0284C7).withValues(alpha: 0.2)
              : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdRequired
                ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                : const Color(0xFF475569),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isAdRequired ? const Color(0xFF38BDF8) : Colors.white, size: 20),
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
                    ? const Color(0xFF0284C7)
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
