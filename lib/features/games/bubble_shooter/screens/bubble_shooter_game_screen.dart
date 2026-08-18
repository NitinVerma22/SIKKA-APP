import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/aim_line_painter.dart';
import '../widgets/bubble_widget.dart';
import '../widgets/stars_painter.dart';
import '../services/bubble_shooter_service.dart';
import '../services/bubble_shooter_audio_service.dart';
import '../../../../core/ads/ad_service.dart';

const List<Color> kBubbleColors = [
  Color(0xFFFF4E91),
  Color(0xFF00CFFF),
  Color(0xFF7CFF6B),
  Color(0xFFFFD93D),
  Color(0xFFB44FFF),
  Color(0xFFFF7B54),
];

class BubbleModel {
  double x;
  double y;
  Color color;
  bool alive;

  BubbleModel({
    required this.x,
    required this.y,
    required this.color,
    this.alive = true,
  });
}

class ShooterBubble {
  double x;
  double y;
  double dx;
  double dy;
  Color color;
  bool moving;

  ShooterBubble({
    required this.x,
    required this.y,
    required this.color,
    this.dx = 0,
    this.dy = 0,
    this.moving = false,
  });
}

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

class _BubbleShooterGameScreenState extends State<BubbleShooterGameScreen> with TickerProviderStateMixin {
  static const int kCols = 8;
  static const int kRows = 12;
  static const double kBubbleRadius = 22;
  static const double kSpeed = 12.0;

  final BubbleShooterService _service = BubbleShooterService();
  List<BubbleModel?> grid = [];
  ShooterBubble? shooterBubble;
  Color nextColor = kBubbleColors[0];
  Color currentColor = kBubbleColors[1];

  double shooterX = 0;
  double aimX = 0;
  double aimY = 0;
  bool isAiming = false;

  int score = 0;
  bool gameOver = false;
  bool gameWon = false;
  bool _isClaiming = false;
  int _earnedCoins = 0;

  Timer? gameTimer;
  final Random rng = Random();

  double get bubbleDiameter => kBubbleRadius * 2;

  late AnimationController _shooterPulse;
  final List<Offset> _starsOffsets = [];
  final List<double> _starsOpacities = [];

  @override
  void initState() {
    super.initState();
    _shooterPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Seed background stars
    final r = Random(42);
    for (int i = 0; i < 50; i++) {
      _starsOffsets.add(Offset(r.nextDouble() * 400, r.nextDouble() * 800));
      _starsOpacities.add(r.nextDouble() * 0.7 + 0.3);
    }

    BubbleShooterAudioService.instance.startBgm();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGame();
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _shooterPulse.dispose();
    BubbleShooterAudioService.instance.stopBgm();
    super.dispose();
  }

  void _initGame() {
    final size = MediaQuery.of(context).size;
    shooterX = size.width / 2;

    grid = List.filled(kCols * kRows, null);

    // Number of filled rows scales with level
    final int colorCount = min(kBubbleColors.length, 3 + (widget.levelNumber ~/ 5));
    final int filledRows = min(8, 4 + (widget.levelNumber ~/ 3));

    for (int row = 0; row < filledRows; row++) {
      for (int col = 0; col < kCols; col++) {
        final index = row * kCols + col;
        grid[index] = BubbleModel(
          x: _colToX(col, row),
          y: _rowToY(row),
          color: kBubbleColors[rng.nextInt(colorCount)],
        );
      }
    }

    currentColor = kBubbleColors[rng.nextInt(colorCount)];
    nextColor = kBubbleColors[rng.nextInt(colorCount)];

    gameOver = false;
    gameWon = false;
    _isClaiming = false;
    score = 0;
    _earnedCoins = 0;

    setState(() {});
  }

  double _colToX(int col, int row) {
    final size = MediaQuery.of(context).size;
    final startX = (size.width - kCols * bubbleDiameter) / 2;
    final offset = (row % 2 == 0) ? 0.0 : kBubbleRadius;
    return startX + col * bubbleDiameter + kBubbleRadius + offset;
  }

  double _rowToY(int row) {
    return 140.0 + row * (kBubbleRadius * 1.75);
  }

  void _shoot(double targetX, double targetY) {
    if (shooterBubble != null && shooterBubble!.moving) return;
    if (gameOver || gameWon) return;

    final size = MediaQuery.of(context).size;
    final startY = size.height - 130;

    final dx = targetX - shooterX;
    final dy = targetY - startY;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist == 0 || dy >= 0) return;

    final ndx = (dx / dist) * kSpeed;
    final ndy = (dy / dist) * kSpeed;

    shooterBubble = ShooterBubble(
      x: shooterX,
      y: startY,
      dx: ndx,
      dy: ndy,
      color: currentColor,
      moving: true,
    );

    BubbleShooterAudioService.instance.playShootSfx();

    final int colorCount = min(kBubbleColors.length, 3 + (widget.levelNumber ~/ 5));
    currentColor = nextColor;
    nextColor = kBubbleColors[rng.nextInt(colorCount)];

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), _tick);

    setState(() {});
  }

  void _tick(Timer timer) {
    if (shooterBubble == null || !shooterBubble!.moving) {
      timer.cancel();
      return;
    }

    final size = MediaQuery.of(context).size;
    final b = shooterBubble!;

    b.x += b.dx;
    b.y += b.dy;

    // Left wall bounce
    if (b.x - kBubbleRadius < 0) {
      b.x = kBubbleRadius;
      b.dx = -b.dx;
    }
    // Right wall bounce
    else if (b.x + kBubbleRadius > size.width) {
      b.x = size.width - kBubbleRadius;
      b.dx = -b.dx;
    }

    // Top ceiling collision
    if (b.y - kBubbleRadius < 130) {
      b.moving = false;
      timer.cancel();
      _snapToGrid(b);
      return;
    }

    // Grid bubbles collision check
    for (int i = 0; i < grid.length; i++) {
      final g = grid[i];
      if (g == null || !g.alive) continue;

      final dist = sqrt(pow(b.x - g.x, 2) + pow(b.y - g.y, 2));
      if (dist < bubbleDiameter - 4) {
        b.moving = false;
        timer.cancel();
        _snapToGrid(b);
        return;
      }
    }

    if (mounted) setState(() {});
  }

  void _snapToGrid(ShooterBubble b) {
    int bestRow = 0;
    int bestCol = 0;
    double bestDist = double.infinity;

    for (int row = 0; row < kRows; row++) {
      for (int col = 0; col < kCols; col++) {
        final index = row * kCols + col;
        if (grid[index] != null && grid[index]!.alive) continue;

        final gx = _colToX(col, row);
        final gy = _rowToY(row);
        final dist = sqrt(pow(b.x - gx, 2) + pow(b.y - gy, 2));

        if (dist < bestDist) {
          bestDist = dist;
          bestRow = row;
          bestCol = col;
        }
      }
    }

    final index = bestRow * kCols + bestCol;
    grid[index] = BubbleModel(
      x: _colToX(bestCol, bestRow),
      y: _rowToY(bestRow),
      color: b.color,
    );

    shooterBubble = null;

    _findAndPop(bestRow, bestCol, b.color);
    _checkGameOver();

    setState(() {});
  }

  void _findAndPop(int row, int col, Color color) {
    final visited = <int>{};
    final matched = <int>[];

    void dfs(int r, int c) {
      if (r < 0 || r >= kRows || c < 0 || c >= kCols) return;
      final i = r * kCols + c;
      if (visited.contains(i)) return;
      final cell = grid[i];
      if (cell == null || !cell.alive || cell.color != color) return;

      visited.add(i);
      matched.add(i);

      final isOdd = r % 2 == 1;
      dfs(r, c - 1);
      dfs(r, c + 1);
      dfs(r - 1, c);
      dfs(r + 1, c);
      if (isOdd) {
        dfs(r - 1, c + 1);
        dfs(r + 1, c + 1);
      } else {
        dfs(r - 1, c - 1);
        dfs(r + 1, c - 1);
      }
    }

    dfs(row, col);

    if (matched.length >= 3) {
      BubbleShooterAudioService.instance.playPopSfx();
      for (final i in matched) {
        grid[i] = null;
      }
      score += matched.length * 10 * widget.levelNumber;
      _dropFloating();
    }
  }

  void _dropFloating() {
    final connected = <int>{};

    for (int col = 0; col < kCols; col++) {
      final i = col;
      if (grid[i] != null && grid[i]!.alive) {
        _markConnected(0, col, connected);
      }
    }

    bool droppedAny = false;
    for (int i = 0; i < grid.length; i++) {
      if (grid[i] != null && grid[i]!.alive && !connected.contains(i)) {
        grid[i] = null;
        score += 15;
        droppedAny = true;
      }
    }

    if (droppedAny) {
      BubbleShooterAudioService.instance.playExplosionSfx();
    }
  }

  void _markConnected(int row, int col, Set<int> visited) {
    if (row < 0 || row >= kRows || col < 0 || col >= kCols) return;
    final i = row * kCols + col;
    if (visited.contains(i)) return;
    if (grid[i] == null || !grid[i]!.alive) return;

    visited.add(i);

    final isOdd = row % 2 == 1;
    _markConnected(row, col - 1, visited);
    _markConnected(row, col + 1, visited);
    _markConnected(row - 1, col, visited);
    _markConnected(row + 1, col, visited);
    if (isOdd) {
      _markConnected(row - 1, col + 1, visited);
      _markConnected(row + 1, col + 1, visited);
    } else {
      _markConnected(row - 1, col - 1, visited);
      _markConnected(row + 1, col - 1, visited);
    }
  }

  Future<void> _checkGameOver() async {
    final size = MediaQuery.of(context).size;
    bool anyAlive = false;

    for (int i = 0; i < grid.length; i++) {
      if (grid[i] != null && grid[i]!.alive) {
        anyAlive = true;
        if (grid[i]!.y > size.height - 200) {
          setState(() => gameOver = true);
          return;
        }
      }
    }

    if (!anyAlive) {
      _onLevelComplete();
    }
  }

  Future<void> _onLevelComplete() async {
    setState(() {
      gameWon = true;
      _isClaiming = true;
    });

    final progress = await _service.loadProgress();
    final int nextMax = _service.max(progress.maxUnlockedLevel, widget.levelNumber + 1);
    final Map<int, int> newStars = Map<int, int>.from(progress.starsMap);
    newStars[widget.levelNumber] = 3;
    await _service.saveLocalProgress(nextMax, newStars);

    final result = await _service.claimLevelReward(
      levelNumber: widget.levelNumber,
      stars: 3,
      score: score,
    );

    if (widget.levelNumber % 10 == 0) {
      if (!AdService.instance.isInterstitialAdLoaded()) {
        AdService.instance.loadRewardedAd();
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

  List<Offset> _getAimLine(double targetX, double targetY, Size size) {
    final points = <Offset>[];
    double x = shooterX;

    double startY = size.height - 130;
    double dx = targetX - x;
    double dy = targetY - startY;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0 || dy >= 0) return points;

    dx = (dx / dist) * kSpeed;
    dy = (dy / dist) * kSpeed;

    int steps = 0;
    while (startY > 130 && steps < 200) {
      points.add(Offset(x, startY));
      x += dx;
      startY += dy;
      if (x < kBubbleRadius) {
        x = kBubbleRadius;
        dx = -dx;
      } else if (x > size.width - kBubbleRadius) {
        x = size.width - kBubbleRadius;
        dx = -dx;
      }
      steps++;
    }

    return points;
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
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        body: GestureDetector(
          onPanStart: (d) {
            setState(() {
              isAiming = true;
              aimX = d.localPosition.dx;
              aimY = d.localPosition.dy;
            });
          },
          onPanUpdate: (d) {
            setState(() {
              aimX = d.localPosition.dx;
              aimY = d.localPosition.dy;
            });
          },
          onPanEnd: (_) {
            if (isAiming) {
              _shoot(aimX, aimY);
            }
            setState(() => isAiming = false);
          },
          onTapUp: (d) {
            _shoot(d.localPosition.dx, d.localPosition.dy);
          },
          child: Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF07071A), Color(0xFF0D0D2B), Color(0xFF12123A)],
              ),
            ),
            child: Stack(
              children: [
                CustomPaint(size: size, painter: StarsPainter(_starsOffsets, _starsOpacities)),
                _buildGrid(),
                if (isAiming && aimY < size.height - 100)
                  CustomPaint(
                    size: size,
                    painter: AimLinePainter(
                      _getAimLine(aimX, aimY, size),
                      currentColor,
                    ),
                  ),
                if (shooterBubble != null && shooterBubble!.moving)
                  _buildMovingBubble(),
                Positioned(top: 40, left: 0, right: 0, child: _buildTopBar()),
                _buildShooterArea(size),
                if (gameOver || gameWon) _buildOverlay(size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleExit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                'SCORE',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$score',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                'LEVEL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${widget.levelNumber}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFFD93D),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                BubbleShooterAudioService.instance.toggleMute();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                BubbleShooterAudioService.instance.isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Stack(
      children: grid.where((b) => b != null && b.alive).map((b) {
        return Positioned(
          left: b!.x - kBubbleRadius,
          top: b.y - kBubbleRadius,
          child: BubbleWidget(color: b.color, radius: kBubbleRadius),
        );
      }).toList(),
    );
  }

  Widget _buildMovingBubble() {
    final b = shooterBubble!;
    return Positioned(
      left: b.x - kBubbleRadius,
      top: b.y - kBubbleRadius,
      child: BubbleWidget(color: b.color, radius: kBubbleRadius),
    );
  }

  Widget _buildShooterArea(Size size) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFF07071A).withValues(alpha: 0.95),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 45,
              bottom: 35,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    final temp = currentColor;
                    currentColor = nextColor;
                    nextColor = temp;
                  });
                },
                child: Column(
                  children: [
                    const Text(
                      'NEXT ⇄',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    BubbleWidget(color: nextColor, radius: 16),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 45,
              child: Column(
                children: [
                  const Text(
                    'SHOOT',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _shooterPulse,
                    builder: (_, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: currentColor.withValues(
                                alpha: 0.3 + 0.3 * _shooterPulse.value,
                              ),
                              blurRadius: 20 + 10 * _shooterPulse.value,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: BubbleWidget(
                          color: currentColor,
                          radius: kBubbleRadius + 3,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gameWon
                  ? [const Color(0xFF1A3A2A), const Color(0xFF0D2018)]
                  : [const Color(0xFF3A1A1A), const Color(0xFF200D0D)],
            ),
            border: Border.all(
              color: gameWon
                  ? const Color(0xFF7CFF6B)
                  : const Color(0xFFFF4E91),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(gameWon ? '🎉' : '💥', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                gameWon ? 'LEVEL CLEARED!' : 'GAME OVER',
                style: GoogleFonts.outfit(
                  color: gameWon
                      ? const Color(0xFF7CFF6B)
                      : const Color(0xFFFF4E91),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              if (gameWon) ...[
                if (_isClaiming)
                  const CircularProgressIndicator(color: Color(0xFF7CFF6B))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF34D399)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '+$_earnedCoins Sikka Coins',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF34D399),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gameWon ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (gameWon) {
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
                        _initGame();
                      }
                    },
                    child: Text(
                      gameWon ? 'NEXT LEVEL' : 'RETRY',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
