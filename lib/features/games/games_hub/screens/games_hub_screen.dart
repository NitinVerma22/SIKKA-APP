import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/core/animations/custom_animations.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/games/shared/widgets/game_banner_ad.dart';
import 'package:sikkaplay/features/games/shared/screens/game_rules_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';

class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final homeState = ref.watch(homeProvider);
    final selectedLanguage = ref.watch(languageProvider);
    final userData = userState.userData ?? {};
    final referralEarning = userData['referralBalance'] ?? homeState.referralEarning;
    final walletBalance = (userData['balance'] ?? homeState.balance) + referralEarning;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFC), // Muted light slate top
              Color(0xFFF1F5F9), // Soft slate bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Wallet Pill Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('play_games', selectedLanguage),
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A), // Slate-900
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedLanguage == 'Hindi' ? 'खेलें और सिक्के कमाएं' : 'Play & Earn Coins',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B), // Slate-500
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Mockup wallet style pill
                    GestureDetector(
                      onTap: () => context.push('/wallet'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED), // Purple wallet container
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$walletBalance',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.monetization_on,
                              color: AppColors.yellowGlow, // Gold Star-Coin Icon
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8), // Slate-400
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Live Dynamic Stats Row
                const LiveStatsGrid(),
                const SizedBox(height: 28),

                // Top Games Header Row
                Row(
                  children: [
                    Text(
                      context.tr('top_games', selectedLanguage),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFC084FC), // soft purple sparkle matching mockup
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Game Card 1: Spin & Earn
                FadeInSlideWidget(
                  slideOffset: 20,
                  duration: const Duration(milliseconds: 500),
                  child: _buildGameCard(
                    context: context,
                    selectedLanguage: selectedLanguage,
                    title: context.tr('spin_earn', selectedLanguage),
                    description: context.tr('spin_earn_desc', selectedLanguage),
                    icon: Icons.casino_rounded,
                    colors: [const Color(0xFF7C3AED), const Color(0xFFC084FC)],
                    leftImagePath: 'assets/images/games_hub/spin_earn_left.webp',
                    rightImagePath: 'assets/images/games_hub/spin_earn_right.webp',
                    onTap: () {
                      context.push('/games/rules',
                          extra: GameRulesArgs(
                            title: context.tr('spin_earn', selectedLanguage),
                            description: context.tr('spin_earn_desc', selectedLanguage),
                            icon: Icons.casino_rounded,
                            colors: [const Color(0xFF7C3AED), const Color(0xFFC084FC)],
                            routePath: '/games/spin_earn',
                            imagePath: 'assets/images/games_hub/spin_earn_right.webp',
                            rules: [
                              context.tr('spin_rule1', selectedLanguage),
                              context.tr('spin_rule2', selectedLanguage),
                              context.tr('spin_rule3', selectedLanguage),
                            ],
                          ));
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Game Card 2: Treasure Grid
                FadeInSlideWidget(
                  slideOffset: 30,
                  duration: const Duration(milliseconds: 600),
                  child: _buildGameCard(
                    context: context,
                    selectedLanguage: selectedLanguage,
                    title: context.tr('treasure_grid', selectedLanguage),
                    description: context.tr('treasure_grid_desc', selectedLanguage),
                    icon: Icons.apps_rounded,
                    colors: [const Color(0xFFEF4444), const Color(0xFFFCA5A5)],
                    leftImagePath: 'assets/images/games_hub/treasure_grid_left.webp',
                    rightImagePath: 'assets/images/games_hub/treasure_grid_right.webp',
                    onTap: () {
                      context.push('/games/rules',
                          extra: GameRulesArgs(
                            title: context.tr('treasure_grid', selectedLanguage),
                            description: context.tr('treasure_grid_desc', selectedLanguage),
                            icon: Icons.apps_rounded,
                            colors: [const Color(0xFFEF4444), const Color(0xFFFCA5A5)],
                            routePath: '/games/treasure_grid',
                            imagePath: 'assets/images/games_hub/treasure_grid_right.webp',
                            rules: [
                              context.tr('treasure_rule1', selectedLanguage),
                              context.tr('treasure_rule2', selectedLanguage),
                              context.tr('treasure_rule3', selectedLanguage),
                            ],
                          ));
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Game Card 3: Emoji Memory
                FadeInSlideWidget(
                  slideOffset: 40,
                  duration: const Duration(milliseconds: 700),
                  child: _buildGameCard(
                    context: context,
                    selectedLanguage: selectedLanguage,
                    title: context.tr('emoji_memory', selectedLanguage),
                    description: context.tr('emoji_memory_desc', selectedLanguage),
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    colors: [const Color(0xFF3B82F6), const Color(0xFF93C5FD)],
                    leftImagePath: 'assets/images/games_hub/emoji_memory_left.webp',
                    rightImagePath: 'assets/images/games_hub/emoji_memory_right.webp',
                    onTap: () {
                      context.push('/games/rules',
                          extra: GameRulesArgs(
                            title: context.tr('emoji_memory', selectedLanguage),
                            description: context.tr('emoji_memory_desc', selectedLanguage),
                            icon: Icons.sentiment_satisfied_alt_rounded,
                            colors: [const Color(0xFF3B82F6), const Color(0xFF93C5FD)],
                            routePath: '/games/emoji_memory',
                            imagePath: 'assets/images/games_hub/emoji_memory_right.webp',
                            rules: [
                              context.tr('emoji_rule1', selectedLanguage),
                              context.tr('emoji_rule2', selectedLanguage),
                              context.tr('emoji_rule3', selectedLanguage),
                            ],
                          ));
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Game Card 4: Math Rush
                FadeInSlideWidget(
                  slideOffset: 50,
                  duration: const Duration(milliseconds: 800),
                  child: _buildGameCard(
                    context: context,
                    selectedLanguage: selectedLanguage,
                    title: context.tr('math_rush', selectedLanguage),
                    description: context.tr('math_rush_desc', selectedLanguage),
                    icon: Icons.calculate_rounded,
                    colors: [const Color(0xFF10B981), const Color(0xFF6EE7B7)],
                    leftImagePath: 'assets/images/games_hub/math_rush_left.webp',
                    rightImagePath: 'assets/images/games_hub/math_rush_right.webp',
                    onTap: () {
                      context.push('/games/rules',
                          extra: GameRulesArgs(
                            title: context.tr('math_rush', selectedLanguage),
                            description: context.tr('math_rush_desc', selectedLanguage),
                            icon: Icons.calculate_rounded,
                            colors: [const Color(0xFF10B981), const Color(0xFF6EE7B7)],
                            routePath: '/games/math_rush',
                            imagePath: 'assets/images/games_hub/math_rush_right.webp',
                            rules: [
                              context.tr('math_rule1', selectedLanguage),
                              context.tr('math_rule2', selectedLanguage),
                              context.tr('math_rule3', selectedLanguage),
                              context.tr('math_rule4', selectedLanguage),
                            ],
                          ));
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const GameBannerAd(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Simulated 3D pedestal widget supporting float effect
  Widget _buildPedestalIcon({
    required IconData icon,
    required List<Color> colors,
  }) {
    final primaryColor = colors.first;
    return SizedBox(
      width: 66,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base Shadow Ellipse
          Positioned(
            bottom: 4,
            child: Container(
              width: 50,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.elliptical(25, 7)),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          // Lower Pedestal Stage
          Positioned(
            bottom: 6,
            child: Container(
              width: 54,
              height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.4),
                    primaryColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.all(Radius.elliptical(27, 9)),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
            ),
          ),
          // Upper Pedestal Stage
          Positioned(
            bottom: 11,
            child: Container(
              width: 46,
              height: 14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.6),
                    primaryColor.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.all(Radius.elliptical(23, 7)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
            ),
          ),
          // Floating Icon Card
          Positioned(
            top: 4,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Redesigned game card layout
  Widget _buildGameCard({
    required BuildContext context,
    required String selectedLanguage,
    required String title,
    required String description,
    required IconData icon,
    required List<Color> colors,
    required String leftImagePath,
    required String rightImagePath,
    required VoidCallback onTap,
  }) {
    final Color primaryColor = colors.first;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 124,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.08),
              Colors.white,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Right-side 3D game illustration
            Positioned(
              right: 6,
              bottom: 4,
              top: 4,
              width: 100,
              child: Image.asset(
                rightImagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      icon,
                      size: 56,
                      color: primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
            // Card main body content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 66,
                    height: 80,
                    child: Image.asset(
                      leftImagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => _buildPedestalIcon(
                        icon: icon,
                        colors: colors,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(right: 90), // Leaves enough room for right-side illustration
                          child: Text(
                            description,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Custom Pill click button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr('click_to_play', selectedLanguage),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
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

// Stateful Widget to animate stats dynamically
class LiveStatsGrid extends ConsumerStatefulWidget {
  const LiveStatsGrid({super.key});

  @override
  ConsumerState<LiveStatsGrid> createState() => _LiveStatsGridState();
}

class _LiveStatsGridState extends ConsumerState<LiveStatsGrid> {
  late int _playingNow;
  late int _earnedToday;
  final Random _random = Random();
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    // Random realistic starting numbers for players and coins earned
    _playingNow = 12000 + _random.nextInt(8000);      // 12k to 20k players
    _earnedToday = 1500000 + _random.nextInt(2000000);  // 1.5M to 3.5M coins
    _startSimulatingStats();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _startSimulatingStats() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Playing now fluctuates slightly up and down
          _playingNow += _random.nextInt(7) - 3; // -3 to +3
          if (_playingNow < 10000) _playingNow = 12000;
          
          // Earned today steadily ticks up
          _earnedToday += _random.nextInt(150) + 20; // increases by 20 to 170 coins
        });
      }
    });
  }

  String _formatK(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              title: context.tr('live_stats_playing', selectedLanguage),
              subtitle: context.tr('live_stats_players', selectedLanguage),
              value: _formatK(_playingNow),
              icon: Icons.groups_rounded,
              color: const Color(0xFF2563EB), // Premium Blue
              gradientColors: const [Color(0xFFEFF6FF), Colors.white],
              imagePath: 'assets/images/games_hub/gamepad_stats.webp',
              showLiveDot: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              title: context.tr('live_stats_earned', selectedLanguage),
              subtitle: context.tr('live_stats_coins', selectedLanguage),
              value: _formatK(_earnedToday),
              icon: Icons.monetization_on_rounded,
              color: const Color(0xFF16A34A), // Premium Green
              gradientColors: const [Color(0xFFF0FDF4), Colors.white],
              imagePath: 'assets/images/games_hub/coins_stats.webp',
              showLiveDot: false,
            ),
          ),
        ],
      ),
    );
  }
}

class LiveGreenDot extends StatefulWidget {
  const LiveGreenDot({super.key});

  @override
  State<LiveGreenDot> createState() => _LiveGreenDotState();
}

class _LiveGreenDotState extends State<LiveGreenDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF22C55E), // Live Green
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF22C55E),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final String imagePath;
  final bool showLiveDot;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradientColors,
    required this.imagePath,
    this.showLiveDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Actual Image Illustration (positioned on the right)
          Positioned(
            right: 6,
            bottom: 4,
            height: 72,
            width: 72,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          // Content Block
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showLiveDot) ...[
                            const SizedBox(width: 4),
                            const LiveGreenDot(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 52),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, -0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            key: ValueKey<String>(value),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0F172A),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
