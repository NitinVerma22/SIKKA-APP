import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/win_600_provider.dart';
import '../../../../core/ads/ad_service.dart';
import '../../../../core/providers/wallet_provider.dart';
import '../../../../core/user/user_service.dart';

class Win600CoinsScreen extends ConsumerStatefulWidget {
  const Win600CoinsScreen({super.key});

  @override
  ConsumerState<Win600CoinsScreen> createState() => _Win600CoinsScreenState();
}

class _Win600CoinsScreenState extends ConsumerState<Win600CoinsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E1E)),
          onPressed: () => context.pop(),
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
            _buildPlayAnyGameSection(context),
            const SizedBox(height: 24),
            _buildCalculationCard(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 2),
        Text(
          "Play any game and claim each gullak!",
          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final win600State = ref.watch(win600Provider);
            return GridView.builder(
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
                bool isUnlocked = index < win600State.unlockedGullaks;
                bool canClaimFinal = win600State.unlockedGullaks >= 9;
                bool isFinalClaimed = win600State.isClaimed;

                return GestureDetector(
                  onTap: () {
                    if (isLast) {
                      if (!canClaimFinal) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text("Unlock Gullaks", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                            content: Text("Play games to unlock all gullaks first!", style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("OK", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                              ),
                            ],
                          ),
                        );
                      } else if (!isFinalClaimed) {
                        // Claim final reward via Ad
                        AdService.instance.showRewardedAd(
                          context: context,
                          userId: 'guest',
                          onAdDismissed: () {},
                          onUserEarnedReward: (_) {
                            ref.read(walletProvider.notifier).addCoins(150);
                            ref.read(win600Provider.notifier).claimFinalReward();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("150 Coins Added!")));
                          },
                        );
                      }
                    }
                  },
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLast 
                                  ? (isFinalClaimed ? Colors.grey.shade300 : const Color(0xFFFEF08A))
                                  : (isUnlocked ? const Color(0xFFEDE9FE) : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset(
                              isLast ? 'assets/images/games_hub/banner_gift.png' : 'assets/images/games_hub/gullak.png',
                              width: 45,
                              height: 45,
                              fit: BoxFit.contain,
                              color: (!isLast && !isUnlocked) ? Colors.grey : null,
                              colorBlendMode: (!isLast && !isUnlocked) ? BlendMode.saturation : null,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                isLast ? Icons.card_giftcard : Icons.savings_rounded,
                                color: isLast ? const Color(0xFFB45309) : const Color(0xFFF472B6),
                                size: 30,
                              ),
                            ),
                          ),
                          // Number Bubble or 150 text
                          if (isLast)
                            Positioned(
                              top: -14,
                              child: Text(
                                isFinalClaimed ? "Claimed" : (canClaimFinal ? "Claim!" : "+\$150"),
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFEF4444), // Red
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [
                                    Shadow(color: Color(0xFF16A34A), offset: Offset(0, 2), blurRadius: 0), // Green
                                    Shadow(color: Color(0x6616A34A), offset: Offset(0, 4), blurRadius: 4), // Green blur
                                  ],
                                ),
                              ),
                            )
                          else
                            Positioned(
                              top: -8,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isUnlocked ? const Color(0xFF10B981) : const Color(0xFF7C3AED),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Icon(
                                    isUnlocked ? Icons.check_rounded : Icons.lock_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (!isLast)
                        Text(
                          "+50 Coins",
                          style: GoogleFonts.outfit(
                            color: isUnlocked ? const Color(0xFF10B981) : const Color(0xFF475569),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFBBF24), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("450 Coins", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
                      Text("from 9 Gullak", style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text("+", style: TextStyle(color: Color(0xFF7C3AED), fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("150 Coins", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
                      Text("from Offers", style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
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
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
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
              Container(
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
            ],
          ),
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
