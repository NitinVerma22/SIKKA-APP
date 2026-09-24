import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/milestone_config.dart';

class MilestoneSelectionScreen extends StatelessWidget {
  final String gameName; // e.g., 'Bubble Sort' or 'Color Sort'
  final String gameRoute; // e.g., '/games/bubble_shooter/level_select'
  final int globalMaxLevel;
  final Color themeColor;

  const MilestoneSelectionScreen({
    super.key,
    required this.gameName,
    required this.gameRoute,
    required this.globalMaxLevel,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light modern background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '$gameName Milestones',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: MilestonesData.milestones.length,
          itemBuilder: (context, index) {
            final milestone = MilestonesData.milestones[index];
            final isUnlocked = globalMaxLevel >= milestone.startLevel;
            final isCompleted = globalMaxLevel > milestone.endLevel;
            final isActive = isUnlocked && !isCompleted;

            return _buildMilestoneCard(context, milestone, isUnlocked, isCompleted, isActive);
          },
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context,
    MilestoneConfig milestone,
    bool isUnlocked,
    bool isCompleted,
    bool isActive,
  ) {
    final bgColor = isUnlocked ? Colors.white : const Color(0xFFF1F5F9);
    final borderColor = isActive ? themeColor : (isUnlocked ? Colors.grey.shade300 : Colors.grey.shade200);
    final iconColor = isActive ? Colors.white : (isUnlocked ? themeColor : Colors.grey.shade400);
    final iconBgColor = isActive ? themeColor : (isUnlocked ? themeColor.withOpacity(0.1) : Colors.grey.shade300);

    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          // Go to Level Select (Zig-Zag) for this milestone
          context.push(gameRoute, extra: {
            'milestoneId': milestone.id,
            'startLevel': milestone.startLevel,
            'endLevel': milestone.endLevel,
            'globalMaxLevel': globalMaxLevel,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reach Level ${milestone.startLevel} to unlock this milestone!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: isActive ? 2 : 1),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Left Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.replay_rounded
                      : (isUnlocked ? Icons.play_arrow_rounded : Icons.lock_rounded),
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Center Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Milestone ${milestone.id}',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Levels ${milestone.startLevel} to ${milestone.endLevel}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isUnlocked ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right Reward Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFFFFFBEB) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked ? const Color(0xFFFDE68A) : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          color: isUnlocked ? const Color(0xFFF59E0B) : Colors.grey.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${milestone.totalReward}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? const Color(0xFFD97706) : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Coins',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? const Color(0xFFB45309) : Colors.grey.shade500,
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
