import 'package:flutter/material.dart';

class BadgeInfo {
  final String name;
  final int targetCoins;
  final String imagePath;
  final IconData fallbackIcon;
  final Color color;

  BadgeInfo({
    required this.name,
    required this.targetCoins,
    required this.imagePath,
    required this.fallbackIcon,
    required this.color,
  });
}

// Global list of badges and thresholds
final List<BadgeInfo> appBadges = [
  BadgeInfo(
    name: 'Bronze',
    targetCoins: 2000,
    imagePath: 'assets/images/profile/badge_bronze.webp',
    fallbackIcon: Icons.military_tech_rounded,
    color: const Color(0xFFCD7F32), // Bronze Color
  ),
  BadgeInfo(
    name: 'Silver',
    targetCoins: 5000,
    imagePath: 'assets/images/profile/badge_silver.webp',
    fallbackIcon: Icons.military_tech_rounded,
    color: const Color(0xFFC0C0C0), // Silver Color
  ),
  BadgeInfo(
    name: 'Gold',
    targetCoins: 10000,
    imagePath: 'assets/images/profile/badge_gold.webp',
    fallbackIcon: Icons.military_tech_rounded,
    color: const Color(0xFFFFD700), // Gold Color
  ),
  BadgeInfo(
    name: 'Explorer',
    targetCoins: 15000,
    imagePath: 'assets/images/profile/badge_explorer.webp',
    fallbackIcon: Icons.explore_rounded,
    color: const Color(0xFF3F51B5), // Indigo Explorer Color
  ),
  BadgeInfo(
    name: 'Diamond',
    targetCoins: 30000,
    imagePath: 'assets/images/profile/badge_diamond.webp',
    fallbackIcon: Icons.diamond_rounded,
    color: const Color(0xFF00B4D8), // Diamond Blue
  ),
  BadgeInfo(
    name: 'Legend',
    targetCoins: 50000,
    imagePath: 'assets/images/profile/badge_legend.webp',
    fallbackIcon: Icons.workspace_premium_rounded,
    color: const Color(0xFFE91E63), // Pink Legend Color
  ),
];
