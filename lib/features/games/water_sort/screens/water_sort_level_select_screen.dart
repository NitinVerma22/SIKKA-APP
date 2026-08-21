import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/water_sort_service.dart';
import 'water_sort_game_screen.dart';
import '../../../../core/ads/ad_service.dart';

class WaterSortLevelSelectScreen extends StatefulWidget {
  const WaterSortLevelSelectScreen({super.key});

  @override
  State<WaterSortLevelSelectScreen> createState() => _WaterSortLevelSelectScreenState();
}

class _WaterSortLevelSelectScreenState extends State<WaterSortLevelSelectScreen> {
  final WaterSortService _service = WaterSortService();
  bool _isLoading = true;
  int _maxUnlockedLevel = 1;
  Map<int, int> _starsMap = {};
  int _multiplier = 2; // Admin N multiplier

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

  int get _totalStars => _starsMap.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate blue background
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF334155), width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Water Sort Puzzle',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Total Stars Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF08A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFACC15), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$_totalStars',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFACC15),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Banner Notice
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D28D9).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🧪', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort Liquids & Win Sikka Coins!',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Complete levels to earn Sikka coins!',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFDDD6FE),
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
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA78BFA)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: 200, // 200 levels
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
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WaterSortGameScreen(
                    levelNumber: levelNum,
                    multiplier: _multiplier,
                  ),
                ),
              );
              _fetchProgress(); // Refresh progress when returning
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                : const Color(0xFF334155).withValues(alpha: 0.4),
            width: isUnlocked ? 1.5 : 1.0,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isUnlocked)
              const Icon(Icons.lock_rounded, color: Color(0xFF64748B), size: 26)
            else
              Text(
                'Lvl $levelNum',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

            const SizedBox(height: 6),

            // Stars Rating (if completed)
            if (isUnlocked && stars > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < stars ? const Color(0xFFFACC15) : const Color(0xFF475569),
                  );
                }),
              )
            else if (!isUnlocked)
              Text(
                'Locked',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),

            const SizedBox(height: 6),

            // Coin Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFF059669).withValues(alpha: 0.2)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUnlocked
                      ? const Color(0xFF10B981).withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 2),
                  Text(
                    '+$projectedCoins',
                    style: GoogleFonts.outfit(
                      color: isUnlocked ? const Color(0xFF34D399) : const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
