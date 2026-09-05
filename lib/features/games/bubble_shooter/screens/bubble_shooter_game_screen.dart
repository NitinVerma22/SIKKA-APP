import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/aim_line_painter.dart';
import '../widgets/bubble_widget.dart';
import '../widgets/stars_painter.dart';
import '../services/bubble_shooter_service.dart';
import '../services/bubble_shooter_audio_service.dart';
import '../../shared/widgets/game_banner_ad.dart';
import '../../../../core/ads/ad_service.dart';
import 'package:sikkaplay/features/games/shared/widgets/game_audio_toggle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/profile/controllers/user_controller.dart';
import '../../../../core/user/user_service.dart';
import '../../shared/utils/game_notifications.dart';

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

class BubbleShooterGameScreen extends ConsumerStatefulWidget {
  final int levelNumber;
  final int multiplier;

  const BubbleShooterGameScreen({
    super.key,
    required this.levelNumber,
    this.multiplier = 2,
  });

  @override
  ConsumerState<BubbleShooterGameScreen> createState() => _BubbleShooterGameScreenState();
}

class _BubbleShooterGameScreenState extends ConsumerState<BubbleShooterGameScreen> with TickerProviderStateMixin {
  static const int kCols = 10;
  static const int kRows = 16;
  static const double kBubbleRadius = 14; // MUCH SMALLER BUBBLE SIZE
  static const double kSpeed = 14.0;

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
  int remainingShots = 25;
  bool gameOver = false;
  bool gameWon = false;
  bool noShotsLeft = false;
  bool _isClaiming = false;
  int _earnedCoins = 0;

  Timer? gameTimer;
  final Random rng = Random();

  double get bubbleDiameter => kBubbleRadius * 2;

  late AnimationController _shooterPulse;
  final List<Offset> _starsOffsets = [];
  final List<double> _starsOpacities = [];
  late final Widget _cachedBannerAd;

  String? _sessionId;

  @override
  void initState() {
    super.initState();
    UserService().startGameSession('bubble_shooter').then((id) {
      if (mounted) _sessionId = id;
    });
    _cachedBannerAd = const KeyedSubtree(
      key: ValueKey('cached_bubble_shooter_banner'),
      child: RepaintBoundary(
        child: GameBannerAd(),
      ),
    );

    _shooterPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

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

  Set<Color> _getActiveGridColors() {
    final Set<Color> active = {};
    for (final b in grid) {
      if (b != null && b.alive) {
        active.add(b.color);
      }
    }
    return active;
  }

  Color _getRandomActiveColor() {
    final active = _getActiveGridColors();
    if (active.isNotEmpty) {
      final list = active.toList();
      return list[rng.nextInt(list.length)];
    }
    final int colorCount = min(kBubbleColors.length, 3 + (widget.levelNumber ~/ 5));
    return kBubbleColors[rng.nextInt(colorCount)];
  }

  void _validateShooterColors() {
    final active = _getActiveGridColors();
    if (active.isEmpty) return;

    if (!active.contains(currentColor)) {
      currentColor = _getRandomActiveColor();
    }
    if (!active.contains(nextColor)) {
      nextColor = _getRandomActiveColor();
    }
  }

  void _initGame() {
    final size = MediaQuery.of(context).size;
    shooterX = size.width / 2;

    grid = List.filled(kCols * kRows, null);

    final int colorCount = min(kBubbleColors.length, 3 + (widget.levelNumber ~/ 5));
    final int filledRows = min(10, 6 + (widget.levelNumber ~/ 3));

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

    currentColor = _getRandomActiveColor();
    nextColor = _getRandomActiveColor();

    remainingShots = max(15, 28 - (widget.levelNumber ~/ 4));
    gameOver = false;
    gameWon = false;
    noShotsLeft = false;
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
    // Starts below banner ad + top header (around y = 175)
    return 175.0 + row * (kBubbleRadius * 1.75);
  }

  void _shoot(double targetX, double targetY) {
    if (shooterBubble != null && shooterBubble!.moving) return;
    if (gameOver || gameWon || noShotsLeft) return;
    if (remainingShots <= 0) return;

    final size = MediaQuery.of(context).size;
    final startY = size.height - 90;

    final dx = targetX - shooterX;
    final dy = targetY - startY;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist == 0 || dy >= 0) return;

    remainingShots--;

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

    currentColor = nextColor;
    nextColor = _getRandomActiveColor();
    _validateShooterColors();

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

    // Wall bounce
    if (b.x - kBubbleRadius < 0) {
      b.x = kBubbleRadius;
      b.dx = -b.dx;
    } else if (b.x + kBubbleRadius > size.width) {
      b.x = size.width - kBubbleRadius;
      b.dx = -b.dx;
    }

    // Ceiling collision below top header
    if (b.y - kBubbleRadius < 175) {
      b.moving = false;
      timer.cancel();
      _snapToGrid(b);
      return;
    }

    // Grid collision
    for (int i = 0; i < grid.length; i++) {
      final g = grid[i];
      if (g == null || !g.alive) continue;

      final dist = sqrt(pow(b.x - g.x, 2) + pow(b.y - g.y, 2));
      if (dist < bubbleDiameter - 2) {
        b.moving = false;
        timer.cancel();
        _snapToGrid(b);
        return;
      }
    }

    setState(() {});
  }

  void _snapToGrid(ShooterBubble b) {
    int bestIndex = -1;
    double minDist = double.infinity;

    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        final idx = r * kCols + c;
        if (grid[idx] != null && grid[idx]!.alive) continue;

        final gx = _colToX(c, r);
        final gy = _rowToY(r);
        final d = sqrt(pow(b.x - gx, 2) + pow(b.y - gy, 2));

        if (d < minDist) {
          minDist = d;
          bestIndex = idx;
        }
      }
    }

    if (bestIndex != -1) {
      final row = bestIndex ~/ kCols;
      final col = bestIndex % kCols;

      grid[bestIndex] = BubbleModel(
        x: _colToX(col, row),
        y: _rowToY(row),
        color: b.color,
      );

      _popMatches(row, col, b.color);
    }

    shooterBubble = null;
    _validateShooterColors();
    _checkGameOver();
    setState(() {});
  }

  void _popMatches(int startRow, int startCol, Color color) {
    final matches = <int>{};
    _findMatches(startRow, startCol, color, matches);

    if (matches.length >= 3) {
      for (final idx in matches) {
        grid[idx]?.alive = false;
      }
      score += matches.length * 10;
      BubbleShooterAudioService.instance.playPopSfx();

      _dropUnconnected();
    }
  }

  void _findMatches(int row, int col, Color color, Set<int> matches) {
    if (row < 0 || row >= kRows || col < 0 || col >= kCols) return;
    final i = row * kCols + col;
    if (matches.contains(i)) return;
    if (grid[i] == null || !grid[i]!.alive || grid[i]!.color != color) return;

    matches.add(i);

    final isOdd = row % 2 == 1;
    _findMatches(row, col - 1, color, matches);
    _findMatches(row, col + 1, color, matches);
    _findMatches(row - 1, col, color, matches);
    _findMatches(row + 1, col, color, matches);
    if (isOdd) {
      _findMatches(row - 1, col + 1, color, matches);
      _findMatches(row + 1, col + 1, color, matches);
    } else {
      _findMatches(row - 1, col - 1, color, matches);
      _findMatches(row + 1, col - 1, color, matches);
    }
  }

  void _dropUnconnected() {
    final connected = <int>{};

    for (int col = 0; col < kCols; col++) {
      if (grid[col] != null && grid[col]!.alive) {
        _markConnected(0, col, connected);
      }
    }

    bool droppedAny = false;
    for (int i = 0; i < grid.length; i++) {
      if (grid[i] != null && grid[i]!.alive && !connected.contains(i)) {
        grid[i]!.alive = false;
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
        if (grid[i]!.y > size.height - 150) {
          setState(() => gameOver = true);
          return;
        }
      }
    }

    if (!anyAlive) {
      _onLevelComplete();
    } else if (remainingShots <= 0 && (shooterBubble == null || !shooterBubble!.moving)) {
      setState(() => noShotsLeft = true);
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
      sessionId: _sessionId,
    );

    // Ad logic removed from here — ads now fire ONLY via handleNextLevelTransition
    // when user taps the "NEXT LEVEL" button, preventing double-ad bug.

    final coins = result['coinsEarned'] ?? (widget.levelNumber * widget.multiplier);

    if (mounted) {
      setState(() {
        _earnedCoins = coins;
        _isClaiming = false;
      });
      ref.read(userProvider.notifier).addDirectCoins(_earnedCoins);
      GameNotifications.showCoinUpdate(context, '+$_earnedCoins Sikka');
    }
  }

  List<Offset> _getAimLine(double targetX, double targetY, Size size) {
    final points = <Offset>[];
    double x = shooterX;

    double startY = size.height - 90;
    double dx = targetX - x;
    double dy = targetY - startY;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0 || dy >= 0) return points;

    dx = (dx / dist) * kSpeed;
    dy = (dy / dist) * kSpeed;

    int steps = 0;
    while (startY > 175 && steps < 200) {
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
    // Respect ad frequency rules on exit — skip for early levels (1, 2, 4, 5...)
    if (AdService.instance.shouldShowLevelCompleteAd(widget.levelNumber)) {
      AdService.instance.showInterstitialAd(
        onAdDismissed: () {
          if (mounted) Navigator.pop(context);
        },
      );
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _handleWatchAdForExtraShots() {
    if (!AdService.instance.isRewardedInterstitialAdLoaded()) {
      AdService.instance.loadRewardedInterstitialAd();
    }

    AdService.instance.showRewardedInterstitialAd(
      context: context,
      userId: 'bubble_shooter_user',
      onAdDismissed: () {},
      onUserEarnedReward: (reward) {
        setState(() {
          remainingShots += 20;
          noShotsLeft = false;
        });
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
        backgroundColor: const Color(0xFF07071A),
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          // Touch pan/drag handling anywhere on playfield except bottom shooter bar
          onPanStart: (d) {
            if (d.localPosition.dy < size.height - 110) {
              setState(() {
                isAiming = true;
                aimX = d.localPosition.dx;
                aimY = d.localPosition.dy;
              });
            }
          },
          onPanUpdate: (d) {
            if (isAiming && d.localPosition.dy < size.height - 110) {
              setState(() {
                aimX = d.localPosition.dx;
                aimY = d.localPosition.dy;
              });
            }
          },
          onPanEnd: (_) {
            if (isAiming) {
              _shoot(aimX, aimY);
            }
            setState(() => isAiming = false);
          },
          onTapUp: (d) {
            // TAP BLOCKED in bottom shooter container area (dy >= size.height - 110)
            if (d.localPosition.dy < size.height - 110) {
              _shoot(d.localPosition.dx, d.localPosition.dy);
            }
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
                CustomPaint(
                  size: size,
                  painter: AimLinePainter(
                    (isAiming && aimY < size.height - 110)
                        ? _getAimLine(aimX, aimY, size)
                        : const [],
                    currentColor,
                  ),
                ),
                _buildMovingBubble(),
                
                // TOP SECTION: Banner Ad FIRST at top with margin, THEN Header Bar below it
                Positioned(
                  key: const ValueKey('bubble_shooter_top_section'),
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      _cachedBannerAd,
                      const SizedBox(height: 12), // Clear margin between ad and header
                      _buildTopBar(),
                    ],
                  ),
                ),

                // BOTTOM SECTION: Shooter Controls
                _buildShooterArea(size),

                // Overlay Modals
                _buildOverlay(size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                'SHOTS',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$remainingShots',
                style: GoogleFonts.outfit(
                  color: remainingShots <= 5 ? const Color(0xFFFF4E91) : const Color(0xFF38BDF8),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                'SCORE',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$score',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
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
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${widget.levelNumber}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFFD93D),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          const GameAudioToggle(),
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
    final b = shooterBubble;
    if (b == null || !b.moving) {
      return const Positioned(
        left: 0,
        top: 0,
        child: SizedBox.shrink(),
      );
    }
    return Positioned(
      key: const ValueKey('bubble_shooter_moving_bubble'),
      left: b.x - kBubbleRadius,
      top: b.y - kBubbleRadius,
      child: BubbleWidget(color: b.color, radius: kBubbleRadius),
    );
  }

  Widget _buildShooterArea(Size size) {
    return Positioned(
      key: const ValueKey('bubble_shooter_bottom_section'),
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          color: const Color(0xFF101225).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF25294A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. NEXT Swap Box (Left)
            GestureDetector(
              onTap: () {
                setState(() {
                  final temp = currentColor;
                  currentColor = nextColor;
                  nextColor = temp;
                  _validateShooterColors();
                });
              },
              child: Container(
                width: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF171A33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2B2F57), width: 1.2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'NEXT',
                      style: GoogleFonts.orbitron(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    BubbleWidget(color: nextColor, radius: 11),
                    const SizedBox(height: 3),
                    const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ),

            // 2. SHOOT Cannon Indicator (Center)
            GestureDetector(
              onTap: () => _shoot(shooterX, size.height - 350),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SHOOT',
                    style: GoogleFonts.orbitron(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _shooterPulse,
                    builder: (_, child) {
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: currentColor.withValues(alpha: 0.6 + 0.4 * _shooterPulse.value),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: currentColor.withValues(
                                alpha: 0.3 + 0.3 * _shooterPulse.value,
                              ),
                              blurRadius: 14 + 6 * _shooterPulse.value,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: BubbleWidget(
                          color: currentColor,
                          radius: kBubbleRadius + 2,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 3. BOMB Power-up Slot (Right Middle)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF171A33),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2B2F57), width: 1.2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF9100), size: 24),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '3',
                        style: GoogleFonts.orbitron(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. EXIT Red Button (Right)
            GestureDetector(
              onTap: _handleExit,
              child: Container(
                width: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFB20710)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE50914).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'EXIT',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(Size size) {
    if (!gameOver && !gameWon && !noShotsLeft) {
      return const SizedBox.shrink();
    }
    final bool isNoShots = noShotsLeft && !gameWon && !gameOver;

    return Container(
      width: size.width,
      height: size.height,
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gameWon
                  ? [const Color(0xFF1A3A2A), const Color(0xFF0D2018)]
                  : (isNoShots
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFF3A1A1A), const Color(0xFF200D0D)]),
            ),
            border: Border.all(
              color: gameWon
                  ? const Color(0xFF7CFF6B)
                  : (isNoShots ? const Color(0xFF38BDF8) : const Color(0xFFFF4E91)),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(gameWon ? '🎉' : (isNoShots ? '🎯' : '💥'), style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text(
                gameWon ? 'LEVEL CLEARED!' : (isNoShots ? 'NO SHOTS LEFT!' : 'GAME OVER'),
                style: GoogleFonts.outfit(
                  color: gameWon
                      ? const Color(0xFF7CFF6B)
                      : (isNoShots ? const Color(0xFF38BDF8) : const Color(0xFFFF4E91)),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
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
              const SizedBox(height: 20),
              if (isNoShots) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _handleWatchAdForExtraShots,
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                  label: Text(
                    'WATCH VIDEO (+20 SHOTS)',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _initGame,
                  child: Text(
                    'RESTART GAME',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gameWon ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (gameWon) {
                      AdService.instance.handleNextLevelTransition(
                        context: context,
                        currentLevel: widget.levelNumber,
                        gameName: 'bubble_shooter',
                        onProceedToNextLevel: () {
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
            ],
          ),
        ),
      ),
    );
  }
}
