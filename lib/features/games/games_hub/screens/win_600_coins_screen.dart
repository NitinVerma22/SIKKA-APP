import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class Win600CoinsScreen extends StatelessWidget {
  const Win600CoinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E1E)),
          onTap: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF4C1D95), size: 14),
                const SizedBox(width: 4),
                Text(
                  "10 Minutes Only",
                  style: GoogleFonts.outfit(color: const Color(0xFF4C1D95), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopCard(),
            const SizedBox(height: 24),
            _buildClaimGullakSection(),
            const SizedBox(height: 24),
            _buildCalculationCard(),
            const SizedBox(height: 24),
            _buildPlayAnyGameSection(context),
            const SizedBox(height: 24),
            _buildBottomBanner(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                    children: const [
                      TextSpan(text: "Win "),
                      TextSpan(text: "600 Coins", style: TextStyle(color: Color(0xFF7C3AED))),
                    ],
                  ),
                ),
                Text(
                  "in 10 Minutes Only!",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Play games, claim gullak and earn big rewards!",
                    style: GoogleFonts.outfit(color: const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/games_hub/coins_stack.png',
            width: 90,
            height: 90,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.monetization_on, size: 60, color: Color(0xFFFBBF24)),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimGullakSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "Claim These Gullak",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.auto_awesome, color: Color(0xFFC084FC), size: 18),
              ],
            ),
            Text(
              "Play any game and claim each gullak!",
              style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 16,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            bool isLast = index == 9;
            return Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isLast ? const Color(0xFFFEF08A) : const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        isLast ? 'assets/images/games_hub/banner_gift.png' : 'assets/images/games_hub/gullak.png',
                        width: 45,
                        height: 45,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          isLast ? Icons.card_giftcard : Icons.savings_rounded,
                          color: isLast ? const Color(0xFFB45309) : const Color(0xFFF472B6),
                          size: 30,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            "${index + 1}",
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isLast ? "+150 Coins" : "+50 Coins",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF475569),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalculationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFBBF24), size: 24),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("450 Coins", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold)),
                  Text("from 9 Gullak", style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const Text("+", style: TextStyle(color: Color(0xFF7C3AED), fontSize: 24, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("150 Coins", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold)),
                  Text("from Offers", style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)),
                    children: const [
                      TextSpan(text: "= "),
                      TextSpan(text: "600 Coins"),
                    ],
                  ),
                ),
                Text("Total Reward", style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayAnyGameSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Play Any Game to Claim Gullak",
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildGameOptionCard(
              context, 
              title: "Treasure Grid", 
              desc: "Tap tiles to find\ncoins & avoid bombs.", 
              icon: Icons.grid_view_rounded, 
              color: const Color(0xFFEF4444), 
              bgColor: const Color(0xFFFEF2F2),
              route: '/games/treasure_grid',
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildGameOptionCard(
              context, 
              title: "Emoji Memory", 
              desc: "Memorize positions\nand find the emoji.", 
              icon: Icons.sentiment_satisfied_alt_rounded, 
              color: const Color(0xFF3B82F6), 
              bgColor: const Color(0xFFEFF6FF),
              route: '/games/emoji_memory',
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildGameOptionCard(
              context, 
              title: "Math Rush", 
              desc: "Solve math equations\nbefore time runs out.", 
              icon: Icons.calculate_rounded, 
              color: const Color(0xFF10B981), 
              bgColor: const Color(0xFFECFDF5),
              route: '/games/math_rush',
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildGameOptionCard(BuildContext context, {required String title, required String desc, required IconData icon, required Color color, required Color bgColor, required String route}) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold, height: 1.1),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push(route),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Play Now", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Complete games, claim all gullak and\nearn 600 coins in just 10 minutes!",
              style: GoogleFonts.outfit(color: const Color(0xFF4C1D95), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Image.asset(
            'assets/images/games_hub/rocket.png',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.rocket_launch_rounded, color: Color(0xFF8B5CF6), size: 30),
          ),
        ],
      ),
    );
  }
}
