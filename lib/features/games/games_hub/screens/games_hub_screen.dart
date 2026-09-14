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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              _buildHeader(),
              const SizedBox(height: 16),
              
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Hello!',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('👋', style: TextStyle(fontSize: 28)),
                ],
              ),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                  ),
                  children: const [
                    TextSpan(text: "Let's "),
                    TextSpan(text: "Earn ", style: TextStyle(color: Color(0xFF8B5CF6))),
                    TextSpan(text: "Together!"),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Play Games • Complete Tasks • Earn Unlimited Sikka",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        // Right boy image
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                'assets/images/games_hub/header-boy.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 120,
                  height: 120,
                  child: Icon(Icons.person, size: 80, color: Color(0xFFE5E7EB)),
                ),
              ),
              Positioned(
                top: 0,
                left: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFA78BFA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: const Text(
                    "Play\nEarn\nRepeat!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
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
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFFDE047), size: 28),
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
            width: 40,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.monetization_on,
              color: Color(0xFFFDE047),
              size: 32,
            ),
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
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.82,
      children: [
        // Card 1: Win 250 Coins
        _buildGridCard(
          titleWidget: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
              children: const [
                TextSpan(text: "Win "),
                TextSpan(text: "250 Coins", style: TextStyle(color: Color(0xFFF43F5E))),
              ],
            ),
          ),
          subtitleWidget: const Text(
            "in just 5 minutes!",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          buttonText: "Play Now →",
          buttonGradient: const [Color(0xFFF43F5E), Color(0xFFE11D48)],
          backgroundColor: const Color(0xFFFFF1F2), // Light pink
          iconWidget: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.sports_esports_rounded, color: Color(0xFFF43F5E), size: 20),
          ),
          imagePath: 'assets/images/games_hub/coins_stack.png',
          onTap: () => context.push('/games/arrow_escape'),
          badgeWidget: _buildBadge("HOT", const Color(0xFFF43F5E), const Color(0xFFFFE4E6), Icons.local_fire_department_rounded),
        ),

        // Card 2: Win 600 Coins
        _buildGridCard(
          titleWidget: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
              children: const [
                TextSpan(text: "Win "),
                TextSpan(text: "600 Coins", style: TextStyle(color: Color(0xFF8B5CF6))),
              ],
            ),
          ),
          subtitleWidget: const Text(
            "in 10 minutes!",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          buttonText: "Start Now →",
          buttonGradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          backgroundColor: const Color(0xFFF5F3FF), // Light purple
          iconWidget: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF8B5CF6), size: 20),
          ),
          imagePath: 'assets/images/games_hub/card_clock.png',
          onTap: () => context.push('/games/win_600'),
          badgeWidget: _buildBadge("POPULAR", const Color(0xFF8B5CF6), const Color(0xFFEDE9FE), Icons.star_rounded), // Using star for popular
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
                TextSpan(text: "20000 Coins", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          buttonText: "Play Now →",
          buttonGradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
          backgroundColor: const Color(0xFFEFF6FF), // Light blue
          iconWidget: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.grid_view_rounded, color: Color(0xFF3B82F6), size: 20),
          ),
          imagePath: 'assets/images/games_hub/card_chips.png',
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
                TextSpan(text: "20000 Coins", style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          buttonText: "Play Now →",
          buttonGradient: const [Color(0xFF10B981), Color(0xFF059669)],
          backgroundColor: const Color(0xFFECFDF5), // Light green
          iconWidget: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bubble_chart_rounded, color: Color(0xFF10B981), size: 20),
          ),
          imagePath: 'assets/images/games_hub/card_bubbles.png',
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
    required List<Color> buttonGradient,
    required Color backgroundColor,
    required Widget iconWidget,
    required String imagePath,
    required VoidCallback onTap,
    Widget? badgeWidget,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
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
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: buttonGradient),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
              bottom: 0,
              right: -10,
              width: 80,
              height: 80,
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
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.card_giftcard_rounded,
                      color: Color(0xFFF59E0B),
                      size: 60,
                    ),
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
