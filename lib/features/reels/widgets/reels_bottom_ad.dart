import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';

class ReelsBottomAd extends StatefulWidget {
  const ReelsBottomAd({super.key});

  @override
  State<ReelsBottomAd> createState() => _ReelsBottomAdState();
}

class _ReelsBottomAdState extends State<ReelsBottomAd> {
  late final PageController _adController;
  Timer? _timer;
  int _currentAd = 0;

  final List<Map<String, dynamic>> _bottomAds = [
    {
      'badge': 'DEAL',
      'title': 'Sikka Gold Pass',
      'action': 'CLAIM 10% BOOST',
      'color': AppColors.yellowGlow,
      'description': 'Enjoy +10% rewards on all games and reels!',
    },
    {
      'badge': 'NEW',
      'title': 'Sikka Runner v2',
      'action': 'PLAY NOW',
      'color': AppColors.secondary,
      'description': 'Daily multiplayer tournaments now live!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _adController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_adController.hasClients) {
        _currentAd = (_currentAd + 1) % _bottomAds.length;
        _adController.animateToPage(
          _currentAd,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _adController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Stack(
          children: [
            // Glassmorphic shimmer reflection
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.02),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            PageView.builder(
              controller: _adController,
              itemCount: _bottomAds.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final ad = _bottomAds[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Row(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (ad['color'] as Color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ad['badge'] as String,
                          style: TextStyle(
                            color: ad['color'] as Color,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),

                      // Text Info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ad['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ad['description'] as String,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 9,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (ad['color'] as Color),
                              (ad['color'] as Color).withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: (ad['color'] as Color).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                        child: Text(
                          ad['action'] as String,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
