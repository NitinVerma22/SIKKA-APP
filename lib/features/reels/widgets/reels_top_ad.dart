import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';

class ReelsTopAd extends StatefulWidget {
  const ReelsTopAd({super.key});

  @override
  State<ReelsTopAd> createState() => _ReelsTopAdState();
}

class _ReelsTopAdState extends State<ReelsTopAd> with SingleTickerProviderStateMixin {
  late final PageController _adPageController;
  Timer? _adTimer;
  int _currentAdIndex = 0;

  final List<Map<String, dynamic>> _mockAds = [
    {
      'title': 'SPONSORED: SIKKA RUNNER 🏃',
      'subtitle': 'Play now & earn up to 500 Sikka coins daily! 🎮',
      'icon': Icons.sports_esports_rounded,
      'color': AppColors.primary,
    },
    {
      'title': 'SPONSORED: SPIN & WIN 🎯',
      'subtitle': 'Double rewards today! Grab 1,000 Sikka bonus! 💰',
      'icon': Icons.emoji_events_rounded,
      'color': AppColors.accent,
    },
    {
      'title': 'SPONSORED: GULLAK BONUS 💎',
      'subtitle': 'Upgrade to Gold Gullak for 3x hourly passive coins! 💸',
      'icon': Icons.auto_awesome_rounded,
      'color': AppColors.secondary,
    },
  ];

  @override
  void initState() {
    super.initState();
    _adPageController = PageController();
    _adTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_adPageController.hasClients) {
        _currentAdIndex = (_currentAdIndex + 1) % _mockAds.length;
        _adPageController.animateToPage(
          _currentAdIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _adPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Background Gradient subtle glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x1F6E5DE7), // 12% primary
                    Colors.transparent,
                    Color(0x1F00E5FF), // 12% secondary
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Sliding Sponsored Ads
          PageView.builder(
            controller: _adPageController,
            itemCount: _mockAds.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final ad = _mockAds[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Row(
                  children: [
                    // Sponsored tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (ad['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: (ad['color'] as Color).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'AD',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),

                    // Icon
                    Icon(
                      ad['icon'] as IconData,
                      color: ad['color'] as Color,
                      size: 16,
                    ),
                    const SizedBox(width: AppSizes.sm),

                    // Title & Description
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ad['title'] as String,
                            style: TextStyle(
                              color: ad['color'] as Color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            ad['subtitle'] as String,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Install/Action indicator
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white38,
                      size: 14,
                    ),
                  ],
                ),
              );
            },
          ),

          // Top thin neon border line
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                    AppColors.accent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
