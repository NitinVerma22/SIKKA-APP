import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'arrow_escape_game_screen.dart';
import '../services/arrow_escape_service.dart';

class NativeArrowEscapeLevelSelectScreen extends StatefulWidget {
  const NativeArrowEscapeLevelSelectScreen({super.key});

  @override
  State<NativeArrowEscapeLevelSelectScreen> createState() =>
      _NativeArrowEscapeLevelSelectScreenState();
}

class _NativeArrowEscapeLevelSelectScreenState
    extends State<NativeArrowEscapeLevelSelectScreen> {
  final ArrowEscapeService _service = ArrowEscapeService();

  int _currentLevel = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final progress = await _service.loadProgress();
    if (mounted) {
      setState(() {
        _currentLevel = progress.maxUnlockedLevel;
        if (_currentLevel < 1 || _currentLevel > 15) {
          _currentLevel = 1;
        }
        _isLoading = false;
      });
    }
  }

  // Winding path relative positions (0 = Start, 1..15 = Levels)
  final List<Offset> _relativePositions = [
    const Offset(0.15, 0.05), // Start (0)
    const Offset(0.35, 0.07), // 1
    const Offset(0.52, 0.08), // 2
    const Offset(0.69, 0.09), // 3
    const Offset(0.83, 0.12), // 4
    const Offset(0.85, 0.25), // 5 (Milestone turn)
    const Offset(0.70, 0.35), // 6
    const Offset(0.55, 0.36), // 7
    const Offset(0.40, 0.37), // 8
    const Offset(0.25, 0.38), // 9
    const Offset(0.15, 0.50), // 10 (Milestone turn)
    const Offset(0.35, 0.60), // 11
    const Offset(0.52, 0.62), // 12
    const Offset(0.69, 0.63), // 13
    const Offset(0.83, 0.64), // 14
    const Offset(0.50, 0.77), // 15 - Moved to center
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = 1000.0; // Fixed scrollable height for the path

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
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_esports_rounded, color: Color(0xFF7C3AED), size: 16),
                const SizedBox(width: 4),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Levels", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 8, fontWeight: FontWeight.bold, height: 1)),
                    Text("15", style: GoogleFonts.outfit(color: const Color(0xFF7C3AED), fontSize: 12, fontWeight: FontWeight.w900, height: 1)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : Column(
              children: [
                // Header
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
                            TextSpan(text: "Milestones ✨", style: TextStyle(color: Color(0xFF7C3AED))),
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
                // Map Area
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
                              // 1. Draw dashed path
                              CustomPaint(
                                size: Size(w, h),
                                painter: _PathPainter(_relativePositions),
                              ),
                              // 2. Draw nodes
                              ...List.generate(16, (index) {
                                final pos = _relativePositions[index];
                                final isMilestone = index % 5 == 0 && index > 0;
                                final double leftOffset = isMilestone ? 50 : 30; // Milestone width is 100
                                final double topOffset = isMilestone ? 85 : 30; // Milestone circle center is at 85px from top
                                
                                return Positioned(
                                  left: pos.dx * w - leftOffset,
                                  top: pos.dy * h - topOffset,
                                  child: _buildNode(index),
                                );
                              }),
                              // 3. Draw speech bubbles
                              _buildSpeechBubble(w * 0.65, h * 0.05, "Keep Going!"),
                              _buildSpeechBubble(w * 0.1, h * 0.32, "You're\nDoing Great!"),
                              _buildSpeechBubble(w * 0.6, h * 0.47, "Almost There!"),
                            ],
                          ),
                        ),
                      ),
                      // Sticky Bottom Banner
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF7C3AED), size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Clear all 15 levels", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text("Play, progress and earn big rewards!", style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Play current level
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NativeArrowEscapeGameScreen(
                                        initialLevel: _currentLevel,
                                      ),
                                    ),
                                  ).then((_) => _loadProgress());
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
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

  Widget _buildNode(int index) {
    if (index == 0) {
      return _buildStartNode();
    }
    
    final levelNum = index;
    final isCurrent = levelNum == _currentLevel;
    final isLocked = !isCurrent; // Strict progression logic preserved
    
    if (levelNum == 5) return _buildMilestoneNode(5, const Color(0xFFF97316), 'assets/images/arrow_escape/gift_orange.png', '+30 Coins', 'Great Start!', isCurrent, isLocked);
    if (levelNum == 10) return _buildMilestoneNode(10, const Color(0xFF3B82F6), 'assets/images/arrow_escape/gift_blue.png', '+70 Coins', 'Half Way There!', isCurrent, isLocked);
    if (levelNum == 15) return _buildMilestoneNode(15, const Color(0xFF9333EA), 'assets/images/arrow_escape/chest_purple.png', '+150 Coins', 'Awesome!', isCurrent, isLocked);

    return GestureDetector(
      onTap: isCurrent
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NativeArrowEscapeGameScreen(
                    initialLevel: levelNum,
                  ),
                ),
              );
              _loadProgress();
            }
          : null,
      child: Container(
        width: 45,
        height: 45,
        margin: const EdgeInsets.all(7.5),
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFF1F5F9) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: isCurrent ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0), width: isCurrent ? 3 : 0),
        ),
        child: Center(
          child: isLocked
            ? const Icon(Icons.lock_rounded, color: Color(0xFFCBD5E1), size: 18)
            : Text(
                "$levelNum",
                style: GoogleFonts.outfit(color: const Color(0xFF4C1D95), fontSize: 18, fontWeight: FontWeight.bold),
              ),
        ),
      ),
    );
  }

  Widget _buildStartNode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/games_hub/rocket.png',
          width: 50,
          height: 50,
          errorBuilder: (c, e, s) => const Icon(Icons.rocket_launch, color: Color(0xFF7C3AED), size: 40),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text("Start", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMilestoneNode(int level, Color color, String imagePath, String rewardText, String subtitle, bool isCurrent, bool isLocked) {
    return GestureDetector(
      onTap: isCurrent
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NativeArrowEscapeGameScreen(
                    initialLevel: level,
                  ),
                ),
              );
              _loadProgress();
            }
          : null,
      child: SizedBox(
        width: 100,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Reward Bubble (Pulsing and Centered at top)
            Positioned(
              top: -8,
              child: _PulsingReward(text: rewardText, color: color),
            ),
            // The Image
            Positioned(
              top: 15,
              child: Image.asset(
                imagePath,
                width: 65,
                height: 65,
                errorBuilder: (c, e, s) => Icon(Icons.card_giftcard, color: color, size: 50),
              ),
            ),
            // The Node Circle
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
            // Badge
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

  Widget _buildSpeechBubble(double x, double y, String text) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF4C1D95), fontSize: 10, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> relativePositions;

  _PathPainter(this.relativePositions);

  @override
  void paint(Canvas canvas, Size size) {
    if (relativePositions.isEmpty) return;

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
    // Convert to absolute coordinates
    final pts = relativePositions.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();

    path.moveTo(pts[0].dx, pts[0].dy);

    // Draw smooth curve using midpoints
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

    // Draw thick background path
    canvas.drawPath(path, paint);

    // Draw dashed path on top
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
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => false;
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
          boxShadow: [
            BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.toll_rounded, color: Color(0xFFF59E0B), size: 14), // Coin icon
            const SizedBox(width: 4),
            Text(
              widget.text,
              style: TextStyle(color: widget.color, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
