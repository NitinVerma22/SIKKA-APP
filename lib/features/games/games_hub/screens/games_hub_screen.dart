import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          // We apply padding here, but we will use Stack with negative positioning for bleed
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              _buildHeader(),
              const SizedBox(height: 4),
              
              // 2. Purple Banner
              _buildPurpleBanner(),
              const SizedBox(height: 16),
              
              // 3. Grid of Cards
              _buildGridCards(context),
              const SizedBox(height: 16),
              
              // 4. Bottom Banner (Friends / Gifts)
              _buildBottomBanner(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Hello! 👋 Let's ",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  "Earn",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF6C42EC),
                  ),
                ),
              ],
            ),
            Text(
              "Together!",
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111827),
              ),
            ),
            // Adding bottom padding inside the column to push the banner down 
            // exactly where the boy's image will end.
            const SizedBox(height: 20),
          ],
        ),
        // The boy bleeds out of the right side, top, and bottom
        Positioned(
          top: -30,
          right: -24, 
          child: SizedBox(
            width: 200, // Even bigger
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    'assets/images/games_hub/header-boy.png',
                    fit: BoxFit.contain,
                    width: 190,
                    height: 190,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ),
                Positioned(
                  top: 25,
                  left: -10, // Play Earn Repeat bubble
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFA78BFA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: const Text(
                      "Play\nEarn\nRepeat!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurpleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B3AF2), Color(0xFF6224DB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFFFD43B), size: 28),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Upto 20000 Coins Daily in just 80-120 Minutes.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/games_hub/coins_stack.png',
            width: 45,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCards(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 0.85, // Closer to image proportions
      children: [
        // Card 1: Win 250 Coins
        _buildGridCard(
          titleWidget: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
              children: const [
                TextSpan(text: "Win "),
                TextSpan(text: "250 Coins", style: TextStyle(color: Color(0xFFF64D67))),
              ],
            ),
          ),
          subtitleWidget: const Text(
            "in just 5 minutes!",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          buttonText: "Play Now →",
          buttonColor: const Color(0xFFF64D67), // Solid Pink
          backgroundColor: const Color(0xFFFEF6F7), // Very Light Pink
          iconWidget: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFFFEBF0), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.sports_esports_rounded, color: Color(0xFFF64D67), size: 20),
          ),
          imagePath: 'assets/images/games_hub/coins_stack.png',
          imageWidth: 100, // Big image
          imageHeight: 100,
          imageRight: -10,
          imageBottom: -5,
          onTap: () => context.push('/games/arrow_escape'),
          badgeWidget: _buildBadge("HOT", const Color(0xFFF64D67), const Color(0xFFFFEBF0), Icons.local_fire_department_rounded),
        ),

        // Card 2: Win 600 Coins
        _buildGridCard(
          titleWidget: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
              children: const [
                TextSpan(text: "Win "),
                TextSpan(text: "600 Coins", style: TextStyle(color: Color(0xFF6C42EC))),
              ],
            ),
          ),
          subtitleWidget: const Text(
            "in 10 minutes!",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          buttonText: "Start Now →",
          buttonColor: const Color(0xFF6C42EC), // Solid Purple
          backgroundColor: const Color(0xFFF6F5FD), // Very Light Purple
          iconWidget: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE9E5FC), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF6C42EC), size: 20),
          ),
          imagePath: 'assets/images/games_hub/card_clock.png',
          imageWidth: 90,
          imageHeight: 90,
          imageRight: -5,
          imageBottom: -5,
          onTap: () => context.push('/games/win_600'),
          badgeWidget: _buildBadge("POPULAR", const Color(0xFF6C42EC), const Color(0xFFE9E5FC), Icons.star_rounded),
        ),

        // Card 3: Colour Sort
        _buildGridCard(
          titleWidget: Text(
            "Colour Sort",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
          ),
          subtitleWidget: RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500, height: 1.2),
              children: [
                TextSpan(text: "Win upto\n"),
                TextSpan(text: "20000 Coins", style: TextStyle(color: Color(0xFF257CE9), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          buttonText: "Play Now →",
          buttonColor: const Color(0xFF257CE9), // Solid Blue
          backgroundColor: const Color(0xFFF2F8FF), // Very Light Blue
          iconWidget: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFDCEAFF), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.grid_view_rounded, color: Color(0xFF257CE9), size: 20),
          ),
          imagePath: 'assets/images/games_hub/card_chips.png',
          imageWidth: 95,
          imageHeight: 95,
          imageRight: -10,
          imageBottom: -10,
          onTap: () => context.push('/games/water_sort'),
        ),

        // Card 4: Bubble Sort
        _buildGridCard(
          titleWidget: Text(
            "Bubble Sort",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
          ),
          subtitleWidget: RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500, height: 1.2),
              children: [
                TextSpan(text: "Win upto\n"),
                TextSpan(text: "20000 Coins", style: TextStyle(color: Color(0xFF21B761), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          buttonText: "Play Now →",
          buttonColor: const Color(0xFF21B761), // Solid Green
          backgroundColor: const Color(0xFFF1FCF5), // Very Light Green
          iconWidget: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFD4F7E1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bubble_chart_rounded, color: Color(0xFF21B761), size: 20),
          ),
          imagePath: 'assets/images/games_hub/card_bubbles.png',
          imageWidth: 100,
          imageHeight: 100,
          imageRight: -12,
          imageBottom: -5,
          onTap: () => context.push('/games/bubble_shooter'),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required Widget titleWidget,
    required Widget subtitleWidget,
    required String buttonText,
    required Color buttonColor,
    required Color backgroundColor,
    required Widget iconWidget,
    required String imagePath,
    required VoidCallback onTap,
    double imageWidth = 80,
    double imageHeight = 80,
    double imageRight = -10,
    double imageBottom = 0,
    Widget? badgeWidget,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: backgroundColor.withOpacity(0.8), width: 1.5),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  iconWidget,
                  const Spacer(),
                  titleWidget,
                  const SizedBox(height: 2),
                  subtitleWidget,
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            if (badgeWidget != null)
              Positioned(
                top: 12,
                right: 12,
                child: badgeWidget,
              ),
            Positioned(
              bottom: imageBottom,
              right: imageRight,
              width: imageWidth,
              height: imageHeight,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/playground/friends'), // Route to friends page
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dost bnao", style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 20, fontWeight: FontWeight.w900, height: 1.1)),
                  const Text("Gifts managao", style: TextStyle(color: Color(0xFFF43F5E), fontSize: 20, fontWeight: FontWeight.w900, height: 1.1)),
                  const Row(
                    children: [
                      Text("Sell kro ", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 20, fontWeight: FontWeight.w900, height: 1.1)),
                      Text("😉", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Trade, collect and earn big rewards\nwith your friends!",
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            // Right Side Gift Image + Yellow Card
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: Image.asset(
                    'assets/images/games_hub/banner_gift.png',
                    width: 85,
                    height: 85,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ),
                Positioned(
                  right: -10,
                  bottom: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE066), // Yellow card color
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Text(
                          "Win Upto",
                          style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "100000\nCoins",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFD9480F), fontSize: 14, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
