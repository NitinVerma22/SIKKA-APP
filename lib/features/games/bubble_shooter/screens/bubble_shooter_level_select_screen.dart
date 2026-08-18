import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/bubble_shooter_service.dart';
import 'bubble_shooter_game_screen.dart';
import '../../../../core/ads/ad_service.dart';

class BubbleShooterLevelSelectScreen extends StatefulWidget {
  const BubbleShooterLevelSelectScreen({super.key});

  @override
  State<BubbleShooterLevelSelectScreen> createState() => _BubbleShooterLevelSelectScreenState();
}

class _BubbleShooterLevelSelectScreenState extends State<BubbleShooterLevelSelectScreen> {
  final BubbleShooterService _service = BubbleShooterService();
  bool _isLoading = true;
  int _maxUnlockedLevel = 1;
  Map<int, int> _starsMap = {};
  int _multiplier = 2;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    setState(() => _isLoading = true);
    final progress = await _service.loadProgress();
    if (mounted) {
      setState(() {
        _maxUnlockedLevel = progress.maxUnlockedLevel;
        _starsMap = progress.starsMap;
        _multiplier = progress.multiplier;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bubble Shooter 2D',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0EA5E9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          'Multiplier: ${_multiplier}x',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Header Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pop Bubbles & Claim Sikka Coins!',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Solve 3-5 min puzzle levels to earn coins (Level × $_multiplier)',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFBAE6FD),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Level Grid (200 Levels)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: 200,
                      itemBuilder: (context, index) {
                        final levelNum = index + 1;
                        final isUnlocked = levelNum <= _maxUnlockedLevel;
                        final stars = _starsMap[levelNum] ?? 0;
                        final projectedCoins = levelNum * _multiplier;

                        return _buildLevelCard(
                          levelNum: levelNum,
                          isUnlocked: isUnlocked,
                          stars: stars,
                          projectedCoins: projectedCoins,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard({
    required int levelNum,
    required bool isUnlocked,
    required int stars,
    required int projectedCoins,
  }) {
    return InkWell(
      onTap: isUnlocked
          ? () {
              AdService.instance.showInterstitialAd(
                onAdDismissed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BubbleShooterGameScreen(
                        levelNumber: levelNum,
                        multiplier: _multiplier,
                      ),
                    ),
                  );
                  _fetchProgress();
                },
              );
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFF0284C7).withValues(alpha: 0.7)
                : const Color(0xFF334155).withValues(alpha: 0.4),
            width: isUnlocked ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isUnlocked) ...[
              Text(
                'Lvl $levelNum',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: i < stars ? const Color(0xFFFACC15) : const Color(0xFF475569),
                  );
                }),
              ),
              const SizedBox(height: 4),
              // Coin Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 2),
                    Text(
                      '$projectedCoins',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Icon(Icons.lock_rounded, color: Color(0xFF475569), size: 22),
              const SizedBox(height: 4),
              Text(
                '$levelNum',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
