import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/profile/controllers/user_controller.dart';
import '../../shared/utils/milestone_config.dart';
import '../services/water_sort_service.dart';

class WaterSortMilestonesScreen extends ConsumerStatefulWidget {
  const WaterSortMilestonesScreen({super.key});

  @override
  ConsumerState<WaterSortMilestonesScreen> createState() => _WaterSortMilestonesScreenState();
}

class _WaterSortMilestonesScreenState extends ConsumerState<WaterSortMilestonesScreen> {
  final WaterSortService _service = WaterSortService();
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

  // Fallback image mapping
  String _getMilestoneImage(int index) {
    switch (index) {
      case 0: return 'assets/images/water_sort/bottle_bluepink.png';
      case 1: return 'assets/images/water_sort/bottle_green_pink.png';
      case 2: return 'assets/images/water_sort/bottle_bluepink.png'; // Fallback for orange
      case 3: return 'assets/images/water_sort/chest_pink.png';
      case 4: return 'assets/images/water_sort/crown_purple.png';
      default: return 'assets/images/water_sort/trophy_gold.png';
    }
  }

  // Theme colors per milestone
  Color _getMilestoneColor(int index) {
    switch (index) {
      case 0: return const Color(0xFF3B82F6); // Blue
      case 1: return const Color(0xFF10B981); // Green
      case 2: return const Color(0xFFF59E0B); // Orange
      case 3: return const Color(0xFFEC4899); // Pink
      case 4: return const Color(0xFF8B5CF6); // Purple
      default: return const Color(0xFF0EA5E9); // Light Blue
    }
  }

  // Lighter background gradient per milestone (like the image)
  LinearGradient _getMilestoneGradient(int index) {
    switch (index) {
      case 0: return const LinearGradient(colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)]); // Light Blue
      case 1: return const LinearGradient(colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5)]); // Light Green
      case 2: return const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)]); // Light Orange
      case 3: return const LinearGradient(colors: [Color(0xFFFCE7F3), Color(0xFFFDF2F8)]); // Light Pink
      case 4: return const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)]); // Light Purple
      default: return const LinearGradient(colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)]); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read dynamic global level
    final userState = ref.watch(userProvider);
    final dynamicMaxLevel = userState.userData?['waterSortLevel'] as int? ?? _maxUnlockedLevel;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/water_sort/bg_water_splash.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
                      ),
                    ),
                    // Title Area
                    Expanded(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/water_sort/color_sort_logo.png',
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Milestones',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF0F172A),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Play more levels and earn bigger rewards!',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF336699),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40), // Balance the back button
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // List of Milestones
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: MilestonesData.milestones.length,
                      itemBuilder: (context, index) {
                        final milestone = MilestonesData.milestones[index];
                        final isUnlocked = dynamicMaxLevel >= milestone.startLevel;
                        final isCompleted = dynamicMaxLevel > milestone.endLevel;
                        final isActive = isUnlocked && !isCompleted;

                        // Calculate segmented progress
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

    // Styling based on state (isActive = glowing border)
    BoxBorder border;
    List<BoxShadow> boxShadow;
    
    if (isActive) {
      border = Border.all(color: themeColor, width: 2.5);
      boxShadow = [
        BoxShadow(color: themeColor.withOpacity(0.4), blurRadius: 12, spreadRadius: 1),
        const BoxShadow(color: Colors.white, blurRadius: 20, spreadRadius: 5), // Outer white glow for contrast
      ];
    } else {
      border = Border.all(color: Colors.white.withOpacity(0.6), width: 1.5);
      boxShadow = [
        BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 10, spreadRadius: 0),
      ];
    }

    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          context.push('/games/water_sort/level_select', extra: {
            'milestoneId': milestone.id,
            'startLevel': milestone.startLevel,
            'endLevel': milestone.endLevel,
            'globalMaxLevel': dynamicMaxLevel,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reach Level ${milestone.startLevel} to unlock this milestone!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Left Icon
              SizedBox(
                width: 70,
                height: 80,
                child: isUnlocked 
                  ? Image.asset(imagePath, fit: BoxFit.contain)
                  : ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ]),
                      child: Image.asset(imagePath, fit: BoxFit.contain, opacity: const AlwaysStoppedAnimation(0.5)),
                    ),
              ),
              const SizedBox(width: 12),
              
              // Center Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Milestone ${milestone.id}',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Levels ${milestone.startLevel} to ${milestone.endLevel}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar (4 segments)
                    Row(
                      children: List.generate(4, (i) {
                        double segmentFraction = (progressFraction * 4) - i;
                        bool isFilled = segmentFraction >= 1.0;
                        bool isPartial = segmentFraction > 0 && segmentFraction < 1.0;
                        
                        return Expanded(
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                            decoration: BoxDecoration(
                              color: isFilled 
                                ? themeColor 
                                : (isPartial ? themeColor.withOpacity(0.5) : const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(3),
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
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFDE68A).withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/water_sort/coin_pile.png', width: 20, height: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${milestone.totalReward}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Coins',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
