import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/arrow_escape_models.dart';
import '../engine/arrow_escape_engine.dart';
import '../widgets/arrow_escape_painter.dart';

class NativeArrowEscapeGameScreen extends StatefulWidget {
  final int initialLevel;
  final VoidCallback? onBack;

  const NativeArrowEscapeGameScreen({
    super.key,
    required this.initialLevel,
    this.onBack,
  });

  @override
  State<NativeArrowEscapeGameScreen> createState() => _NativeArrowEscapeGameScreenState();
}

class _NativeArrowEscapeGameScreenState extends State<NativeArrowEscapeGameScreen>
    with SingleTickerProviderStateMixin {
  late int _currentLevelNum;
  late ArrowLevelModel _levelModel;
  late List<ArrowSnakeModel> _arrows;

  int _lives = 3;
  int _totalOriginalArrows = 0;
  String? _highlightedArrowId;
  
  bool _isLevelComplete = false;
  bool _isGameOver = false;

  late AnimationController _animController;
  final List<ParticleModel> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _currentLevelNum = widget.initialLevel;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_gameLoop);
    _animController.repeat();

    _loadLevel(_currentLevelNum);
  }

  void _loadLevel(int levelNum) {
    _currentLevelNum = levelNum;
    _levelModel = ArrowEscapeEngine.generateLevel(levelNum);
    _arrows = List.from(_levelModel.arrows.map((a) => a.copyWith()));
    _totalOriginalArrows = _arrows.length;
    _lives = 3;
    _highlightedArrowId = null;
    _isLevelComplete = false;
    _isGameOver = false;
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
        arrow.escapeProgress += 0.08;
        if (arrow.escapeProgress >= 1.0) {
          // Arrow exited screen!
          _arrows.removeAt(i);
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
        p.alpha -= 0.04;
        p.radius *= 0.95;
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

    // Find arrow occupying tappedPt
    ArrowSnakeModel? tappedArrow;
    for (final arrow in _arrows) {
      if (arrow.isEscaping) continue;
      if (arrow.pathPoints.contains(tappedPt)) {
        tappedArrow = arrow;
        break;
      }
    }

    if (tappedArrow == null) return;

    // Check if tappedArrow can escape
    final canEscape = ArrowEscapeEngine.canArrowEscape(tappedArrow, _arrows, _levelModel.gridSize);

    if (canEscape) {
      // Trigger Escape Animation
      tappedArrow.isEscaping = true;
      tappedArrow.escapeProgress = 0.0;

      // Spawn Particle Burst
      _spawnParticleBurst((tappedPt.x + 0.5) * cellSize, (tappedPt.y + 0.5) * cellSize, tappedArrow.color);
      _highlightedArrowId = null;
    } else {
      // Trigger Blocked Shake
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
    for (int i = 0; i < 16; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 120.0 + _random.nextDouble() * 180.0;
      _particles.add(ParticleModel(
        position: Offset(x, y),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        radius: 4.0 + _random.nextDouble() * 4.0,
      ));
    }
  }

  void _checkWinCondition() {
    if (_arrows.isEmpty) {
      _isLevelComplete = true;
      setState(() {});
    }
  }

  void _onHintPressed() {
    final hintArrow = ArrowEscapeEngine.findSolvableArrow(_arrows, _levelModel.gridSize);
    if (hintArrow != null) {
      setState(() {
        _highlightedArrowId = hintArrow.id;
      });
    }
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
                // Top Header
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

                // Bottom Controls & Status Bar
                _buildBottomControls(progress),
              ],
            ),

            // Level Complete Modal
            if (_isLevelComplete) _buildWinModal(),

            // Game Over Modal
            if (_isGameOver) _buildGameOverModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: widget.onBack ?? () => Navigator.pop(context),
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
            children: List.generate(3, (index) {
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
          // Progress Bar
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
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E222B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _loadLevel(_currentLevelNum),
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF)),
                label: Text('RESTART', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF76ED12),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _onHintPressed,
                icon: const Icon(Icons.lightbulb_rounded, color: Colors.black),
                label: Text('HINT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF181B22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF76ED12), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VICTORY! 🎉',
                style: GoogleFonts.bebasNeue(fontSize: 40, color: const Color(0xFF76ED12)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(Icons.star_rounded, color: Color(0xFFFFEA00), size: 40),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'Level $_currentLevelNum Cleared!',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF76ED12),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _loadLevel(_currentLevelNum + 1),
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
          padding: const EdgeInsets.all(28),
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
              const SizedBox(height: 12),
              Text(
                'All 3 hearts lost on Level $_currentLevelNum',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1744),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _loadLevel(_currentLevelNum),
                child: Text(
                  'TRY AGAIN 🔄',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
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
