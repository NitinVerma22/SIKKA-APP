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
              // 1. Top Section (Header + Banner)
              _buildTopSection(),
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

  Widget _buildTopSection() {
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
            const SizedBox(height: 80), // Increase space to make room for boy
            
            // Purple Banner (with reduced vertical padding)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
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
            ),
          ],
        ),
        
        // Boy sits exactly on top of the banner
        Positioned(
          bottom: 11.5, // Moved boy 1.5px up
          right: -20, // Moved 7px left from previous position
          child: SizedBox(
            width: 230, 
            height: 230,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    'assets/images/games_hub/header-boy.png',
                    fit: BoxFit.contain,
                    width: 220, 
                    height: 220,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridCards(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 0.95, // Cards are shorter
      children: [
        // Card 1: Win 250 Coins
        _buildGridCard(
          titleWidget: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), height: 1.1),
              children: const [
                TextSpan(text: "Win\n"),
                TextSpan(text: "250 Coins", style: TextStyle(color: Color(0xFFF64D67))),
              ],
            ),
          ),
          middleWidget: RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFFF64D67), fontSize: 13, fontWeight: FontWeight.bold, height: 1.1),
              children: [
                TextSpan(text: "in just 5\n"),
                TextSpan(text: "minutes!"),
              ],
            ),
          ),
          buttonText: "Play →",
          buttonColor: const Color(0xFFF64D67), 
          backgroundColor: const Color(0xFFFEF6F7), 
          imagePath: 'assets/images/games_hub/coins_stack.png',
          imageWidth: 95, 
          imageHeight: 95,
          imageRight: -5, 
          imageTop: 65, // Image further down
          onTap: () => context.push('/games/arrow_escape'),
          badgeWidget: _buildBadge("HOT", const Color(0xFFF64D67), const Color(0xFFFFEBF0), Icons.local_fire_department_rounded),
        ),

        // Card 2: Win 600 Coins
        _buildGridCard(
          titleWidget: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), height: 1.1),
              children: const [
                TextSpan(text: "Win\n"),
                TextSpan(text: "600 Coins", style: TextStyle(color: Color(0xFF6C42EC))),
              ],
            ),
          ),
          middleWidget: RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFF6C42EC), fontSize: 13, fontWeight: FontWeight.bold, height: 1.1),
              children: [
                TextSpan(text: "in 10\n"),
                TextSpan(text: "minutes!"),
              ],
            ),
          ),
          buttonText: "Play →",
          buttonColor: const Color(0xFF6C42EC), 
          backgroundColor: const Color(0xFFF6F5FD), 
          imagePath: 'assets/images/games_hub/card_clock.png',
          imageWidth: 90,
          imageHeight: 90,
          imageRight: -5,
          imageTop: 70, // Image further down
          onTap: () => context.push('/games/win_600'),
          badgeWidget: _buildBadge("POPULAR", const Color(0xFF6C42EC), const Color(0xFFE9E5FC), Icons.star_rounded),
        ),

        // Card 3: Colour Sort
        _buildGridCard(
          titleWidget: Text(
            "Colour Sort",
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
          ),
          middleWidget: RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
              children: [
                TextSpan(text: "Win upto\n"),
                TextSpan(text: "1 Lakh\n", style: TextStyle(color: Color(0xFF257CE9), fontWeight: FontWeight.w900, fontSize: 16)),
                TextSpan(text: "Coins", style: TextStyle(color: Color(0xFF257CE9), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          buttonText: "Play →",
          buttonColor: const Color(0xFF257CE9), 
          backgroundColor: const Color(0xFFF2F8FF), 
          imagePath: 'assets/images/games_hub/card_chips.png',
          imageWidth: 90,
          imageHeight: 90,
          imageRight: -5,
          imageTop: 70, // Image further down
          onTap: () => context.push('/games/water_sort'),
        ),

        // Card 4: Bubble Sort
        _buildGridCard(
          titleWidget: Text(
            "Bubble Sort",
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
          ),
          middleWidget: RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
              children: [
                TextSpan(text: "Win upto\n"),
                TextSpan(text: "1 Lakh\n", style: TextStyle(color: Color(0xFF21B761), fontWeight: FontWeight.w900, fontSize: 16)),
                TextSpan(text: "Coins", style: TextStyle(color: Color(0xFF21B761), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          buttonText: "Play →",
          buttonColor: const Color(0xFF21B761), 
          backgroundColor: const Color(0xFFF1FCF5), 
          imagePath: 'assets/images/games_hub/card_bubbles.png',
          imageWidth: 95,
          imageHeight: 95,
          imageRight: -5,
          imageTop: 65, // Image further down
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
          Icon(icon, color: textColor, size: 10),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required Widget titleWidget,
    Widget? middleWidget,
    Widget? bottomWidget,
    required String buttonText,
    required Color buttonColor,
    required Color backgroundColor,
    required String imagePath,
    required VoidCallback onTap,
    double imageWidth = 80,
    double imageHeight = 80,
    double imageRight = -10,
    double imageTop = 40,
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
                  titleWidget,
                  if (middleWidget != null) ...[
                    const SizedBox(height: 4),
                    middleWidget,
                  ],
                  const Spacer(),
                  Transform.translate(
                    offset: const Offset(-4, 0), // Shift button left
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Restored to 12 as requested
                      decoration: BoxDecoration(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (bottomWidget != null) ...[
                    const SizedBox(height: 6),
                    bottomWidget,
                  ] else ...[
                    const SizedBox(height: 12), // Moved button up even more
                  ],
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
              top: imageTop, 
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                ],
              ),
            ),
            // Right Side Gift Image + Text Below
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/games_hub/banner_gift.png',
                  width: 100, // Slightly reduced to fit thinner banner
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
