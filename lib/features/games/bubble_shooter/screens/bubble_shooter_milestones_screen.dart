import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/profile/controllers/user_controller.dart';
import '../../shared/utils/milestone_config.dart';
import '../services/bubble_shooter_service.dart';

class BubbleShooterMilestonesScreen extends ConsumerStatefulWidget {
  const BubbleShooterMilestonesScreen({super.key});

  @override
  ConsumerState<BubbleShooterMilestonesScreen> createState() => _BubbleShooterMilestonesScreenState();
}

class _BubbleShooterMilestonesScreenState extends ConsumerState<BubbleShooterMilestonesScreen> {
  final BubbleShooterService _service = BubbleShooterService();
  bool _isLoading = true;
  int _maxUnlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    final progress = await _service.loadProgress();
    if (mounted) {
      setState(() {
        _maxUnlockedLevel = progress.maxUnlockedLevel;
        _isLoading = false;
      });
    }
  }

  String _getMilestoneImage(int index) {
    switch (index) {
      case 0: return 'assets/images/buble-milestone/bubble_blue (1).png';
      case 1: return 'assets/images/buble-milestone/bubble_green (1).png';
      case 2: return 'assets/images/buble-milestone/bubble_purple (1).png';
      case 3: return 'assets/images/buble-milestone/bubble_orange (1).png';
      case 4: return 'assets/images/buble-milestone/bubble_pink (1).png';
      case 5: return 'assets/images/buble-milestone/bubble_blue (1).png'; // Reused for 6
      case 6: return 'assets/images/water_sort/trophy_gold.png'; // 7
      case 7: return 'assets/images/water_sort/crown_purple.png'; // 8
      case 8: return 'assets/images/water_sort/chest_pink.png'; // 9
      case 9: return 'assets/images/water_sort/bottle_bluepink.png'; // 10
      default: return 'assets/images/water_sort/trophy_gold.png';
    }
  }

  Color _getMilestoneColor(int index) {
    switch (index) {
      case 0: return const Color(0xFF0EA5E9); // Blue
      case 1: return const Color(0xFF10B981); // Green
      case 2: return const Color(0xFF8B5CF6); // Purple
      case 3: return const Color(0xFFF59E0B); // Orange
      case 4: return const Color(0xFFEC4899); // Pink
      case 5: return const Color(0xFF3B82F6); // Blue
      case 6: return const Color(0xFFF59E0B); // Gold/Orange
      case 7: return const Color(0xFF8B5CF6); // Purple
      case 8: return const Color(0xFFEC4899); // Pink
      case 9: return const Color(0xFF3B82F6); // Blue
      default: return const Color(0xFF0EA5E9); 
    }
  }

  LinearGradient _getMilestoneGradient(int index) {
    switch (index) {
      case 0: return const LinearGradient(colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)]); // Light Blue
      case 1: return const LinearGradient(colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5)]); // Light Green
      case 2: return const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)]); // Light Purple
      case 3: return const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)]); // Light Orange
      case 4: return const LinearGradient(colors: [Color(0xFFFCE7F3), Color(0xFFFDF2F8)]); // Light Pink
      case 5: return const LinearGradient(colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)]); // Light Blue
      case 6: return const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)]); // Light Orange
      case 7: return const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)]); // Light Purple
      case 8: return const LinearGradient(colors: [Color(0xFFFCE7F3), Color(0xFFFDF2F8)]); // Light Pink
      case 9: return const LinearGradient(colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)]); // Light Blue
      default: return const LinearGradient(colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)]); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final dynamicMaxLevel = userState.userData?['bubbleShooterLevel'] as int? ?? _maxUnlockedLevel;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/buble-milestone/buble_milestone_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
                      ),
                    ),
                    // Title Area
                    Expanded(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/buble-milestone/bubble_sort_text.png',
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Milestones',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Play more levels and earn bigger rewards!',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1E3A8A),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40), 
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // List of Milestones
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: MilestonesData.milestones.length,
                      itemBuilder: (context, index) {
                        final milestone = MilestonesData.milestones[index];
                        final isUnlocked = dynamicMaxLevel >= milestone.startLevel;
                        final isCompleted = dynamicMaxLevel > milestone.endLevel;
                        final isActive = isUnlocked && !isCompleted;

                        double progressFraction = 0.0;
                        if (isCompleted) {
                          progressFraction = 1.0;
                        } else if (isUnlocked) {
                          progressFraction = (dynamicMaxLevel - milestone.startLevel) / (milestone.endLevel - milestone.startLevel + 1);
                        }

                        return _buildMilestoneCard(
                          milestone: milestone,
                          index: index,
                          isUnlocked: isUnlocked,
                          isActive: isActive,
                          progressFraction: progressFraction,
                          dynamicMaxLevel: dynamicMaxLevel,
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneCard({
    required MilestoneConfig milestone,
    required int index,
    required bool isUnlocked,
    required bool isActive,
    required double progressFraction,
    required int dynamicMaxLevel,
  }) {
    final themeColor = _getMilestoneColor(index);
    final gradient = _getMilestoneGradient(index);
    final imagePath = _getMilestoneImage(index);

    BoxBorder border;
    List<BoxShadow> boxShadow;
    
    if (isActive) {
      border = Border.all(color: Colors.white, width: 3);
      boxShadow = [
        BoxShadow(color: themeColor.withOpacity(0.6), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 4)),
      ];
    } else {
      border = Border.all(color: Colors.white.withOpacity(0.5), width: 2);
      boxShadow = [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
      ];
    }

    // Get max coins from the last checkpoint
    final totalCoins = milestone.checkpoints.values.isNotEmpty 
        ? milestone.checkpoints.values.last 
        : (index + 1) * 100; // Fallback

    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          context.push('/games/bubble_shooter/level_select', extra: {
            'milestoneId': milestone.id,
            'startLevel': milestone.startLevel,
            'endLevel': milestone.endLevel,
            'globalMaxLevel': dynamicMaxLevel,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Complete previous milestones to unlock!', style: GoogleFonts.outfit()),
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: border,
          boxShadow: boxShadow,
        ),
        child: Stack(
          children: [
            // Dark overlay if locked
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Left Bubble Icon
                  Image.asset(
                    imagePath,
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bubble_chart, color: themeColor, size: 40),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Center Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Milestone ${milestone.id}',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Levels ${milestone.startLevel} to ${milestone.endLevel}',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Progress Bar (4 segments)
                        Row(
                          children: List.generate(4, (segIdx) {
                            final segActive = progressFraction > (segIdx * 0.25);
                            return Expanded(
                              child: Container(
                                height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: segActive ? themeColor : themeColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Right Reward Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/buble-milestone/single_coin.png',
                              width: 20,
                              height: 20,
                              errorBuilder: (c, e, s) => const Icon(Icons.stars, color: Color(0xFFF59E0B), size: 20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalCoins',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF92400E),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Coins',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFB45309),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Lock Icon Overlay
            if (!isUnlocked)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
