import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/utils/milestone_config.dart';
import 'bubble_shooter_game_screen.dart';

class BubbleShooterLevelSelectScreen extends StatefulWidget {
  final int milestoneId;
  final int startLevel;
  final int endLevel;
  final int globalMaxLevel;

  const BubbleShooterLevelSelectScreen({
    super.key,
    required this.milestoneId,
    required this.startLevel,
    required this.endLevel,
    required this.globalMaxLevel,
  });

  @override
  State<BubbleShooterLevelSelectScreen> createState() => _BubbleShooterLevelSelectScreenState();
}

class _BubbleShooterLevelSelectScreenState extends State<BubbleShooterLevelSelectScreen> {
  int _currentMilestoneLevel = 1;
  bool _isLoading = true;
  late List<Offset> _relativePositions;

  @override
  void initState() {
    super.initState();
    _relativePositions = _generateWindingPath(widget.endLevel - widget.startLevel + 1);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    
    if (widget.globalMaxLevel >= widget.startLevel && widget.globalMaxLevel <= widget.endLevel) {
      _currentMilestoneLevel = widget.globalMaxLevel;
    } 
    else if (widget.globalMaxLevel > widget.endLevel) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'sikkaplay_bs_milestone_${widget.milestoneId}_progress';
      _currentMilestoneLevel = prefs.getInt(key) ?? widget.startLevel;
    }
    else {
      _currentMilestoneLevel = widget.startLevel;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Offset> _generateWindingPath(int totalLevels) {
    List<Offset> positions = [];
    for (int i = 0; i <= totalLevels; i++) {
      if (i == 0) {
        positions.add(const Offset(0.2, 0.03));
        continue;
      }
      double dy = 0.03 + (i * 0.94 / totalLevels); 
      double dx = 0.5 + 0.35 * math.sin((i - 1) * math.pi / 3.5 - math.pi / 2);
      positions.add(Offset(dx, dy));
    }
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final totalLevels = widget.endLevel - widget.startLevel + 1;
    final h = totalLevels * 120.0; // 120px spacing per level

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E1E)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.bubble_chart_rounded, color: Color(0xFFD946EF), size: 16),
                const SizedBox(width: 4),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Milestone", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 8, fontWeight: FontWeight.bold, height: 1)),
                    Text("${widget.milestoneId}", style: GoogleFonts.outfit(color: const Color(0xFFD946EF), fontSize: 12, fontWeight: FontWeight.w900, height: 1)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD946EF)))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                          children: const [
                            TextSpan(text: "Level "),
                            TextSpan(text: "Milestones ✨", style: TextStyle(color: Color(0xFFD946EF))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Play and clear levels to earn amazing rewards!",
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: Size(w, h),
                                painter: _PathPainter(_relativePositions),
                              ),
                              ...List.generate(totalLevels + 1, (index) {
                                final pos = _relativePositions[index];
                                final levelNum = index == 0 ? 0 : widget.startLevel + index - 1;
                                final isMilestone = index > 0 && MilestonesData.milestones[widget.milestoneId - 1].checkpoints.containsKey(levelNum);
                                final double leftOffset = isMilestone ? 50 : 25;
                                final double topOffset = isMilestone ? 85 : 25;
                                
                                return Positioned(
                                  left: pos.dx * w - leftOffset,
                                  top: pos.dy * h - topOffset,
                                  child: _buildNode(index, levelNum),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFFDF4FF), borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFD946EF), size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Clear all $totalLevels levels", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text("Play, progress and earn big rewards!", style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _playLevel(_currentMilestoneLevel),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD946EF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text("Let's Play", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNode(int index, int levelNum) {
    if (index == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/games_hub/rocket.png',
            width: 50,
            height: 50,
            errorBuilder: (c, e, s) => const Icon(Icons.rocket_launch, color: Color(0xFFD946EF), size: 40),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD946EF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text("Start", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    
    final isCurrent = levelNum == _currentMilestoneLevel;
    final isLocked = levelNum > _currentMilestoneLevel;
    
    final config = MilestonesData.milestones[widget.milestoneId - 1];
    final bool isCheckpoint = config.checkpoints.containsKey(levelNum);

    if (isCheckpoint) {
      final coins = config.checkpoints[levelNum]!;
      String chestImg = 'assets/images/arrow_escape/gift_orange.png';
      Color boxColor = const Color(0xFFF97316);
      if (coins > 50) {
        chestImg = 'assets/images/arrow_escape/gift_blue.png';
        boxColor = const Color(0xFF3B82F6);
      }
      if (coins >= 150) {
        chestImg = 'assets/images/arrow_escape/chest_purple.png';
        boxColor = const Color(0xFF9333EA);
      }

      return _buildMilestoneNode(
        levelNum,
        boxColor,
        chestImg,
        '+${coins} Coins',
        isCurrent ? 'Current Goal' : (isLocked ? 'Locked' : 'Completed'),
        isCurrent,
        isLocked,
      );
    }

    return GestureDetector(
      onTap: isLocked ? null : () => _playLevel(levelNum),
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFF1F5F9) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: const Color(0xFFD946EF).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: isCurrent ? const Color(0xFFD946EF) : const Color(0xFFE2E8F0), width: isCurrent ? 3 : 0),
        ),
        child: Center(
          child: isLocked
            ? const Icon(Icons.lock_rounded, color: Color(0xFFCBD5E1), size: 20)
            : Text(
                "$levelNum",
                style: GoogleFonts.outfit(color: const Color(0xFF701A75), fontSize: 20, fontWeight: FontWeight.bold),
              ),
        ),
      ),
    );
  }

  Widget _buildMilestoneNode(int level, Color color, String imagePath, String rewardText, String subtitle, bool isCurrent, bool isLocked) {
    return GestureDetector(
      onTap: isLocked ? null : () => _playLevel(level),
      child: SizedBox(
        width: 100,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -8,
              child: _PulsingReward(text: rewardText, color: color),
            ),
            Positioned(
              top: 15,
              child: Image.asset(
                imagePath,
                width: 65,
                height: 65,
                errorBuilder: (c, e, s) => Icon(Icons.card_giftcard, color: color, size: 50),
              ),
            ),
            Positioned(
              top: 65,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isLocked ? Colors.grey.shade300 : color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: isLocked 
                    ? const Icon(Icons.lock_rounded, color: Colors.white70, size: 16)
                    : Text("$level", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Text("Level $level", style: TextStyle(color: const Color(0xFF1E293B), fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: const Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playLevel(int levelNum) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BubbleShooterGameScreen(
          levelNumber: levelNum,
          multiplier: 2,
        ),
      ),
    ).then((_) => _loadProgress());
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;
  _PathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final pts = points.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();

    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      if (i == 0) {
        path.lineTo(mid.dx, mid.dy);
      } else {
        path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
      }
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    canvas.drawPath(path, paint);
    final dashedPath = _createDashedPath(path, 15, 10);
    canvas.drawPath(dashedPath, dashPaint);
  }

  Path _createDashedPath(Path source, double dashArray, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashArray : dashSpace;
        if (draw) dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PulsingReward extends StatefulWidget {
  final String text;
  final Color color;
  const _PulsingReward({required this.text, required this.color});

  @override
  State<_PulsingReward> createState() => _PulsingRewardState();
}

class _PulsingRewardState extends State<_PulsingReward> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.color.withOpacity(0.5), width: 1.5),
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.toll_rounded, color: Color(0xFFF59E0B), size: 14),
            const SizedBox(width: 4),
            Text(widget.text, style: TextStyle(color: widget.color, fontSize: 11, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

