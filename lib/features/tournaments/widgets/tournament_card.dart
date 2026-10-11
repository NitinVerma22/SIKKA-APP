import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tournament_models.dart';

class TournamentCard extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback onTap;
  final VoidCallback onJoinTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
    required this.onJoinTap,
  });

  @override
  State<TournamentCard> createState() => _TournamentCardState();
}

class _TournamentCardState extends State<TournamentCard> with SingleTickerProviderStateMixin {
  late Duration _remainingTime;
  Timer? _countdownTimer;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.tournament.timeRemaining;
    _startTimer();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    if (_remainingTime.inSeconds > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
          } else {
            _countdownTimer?.cancel();
          }
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant TournamentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournament.id != widget.tournament.id ||
        oldWidget.tournament.status != widget.tournament.status) {
      _remainingTime = widget.tournament.timeRemaining;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  String _formatTimerDigits(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    // Indian formatting helper or comma separation
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
      } else if (count > 3 && (count - 3) % 2 == 0 && i > 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final isLive = t.isLive;
    final isUpcoming = t.isUpcoming;
    final isCompleted = t.isCompleted;
    final isJoined = t.isJoined;

    final maxCap = t.maxParticipants;
    final currentJoined = t.currentParticipants;
    final hasCap = maxCap != null && maxCap > 0;
    final spotsLeft = hasCap ? (maxCap - currentJoined).clamp(0, maxCap) : 0;
    final progressPct = hasCap ? (currentJoined / maxCap).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLive ? const Color(0xFFE3D8FF) : const Color(0xFFE6E8F2),
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFF6D3CF0).withValues(alpha: 0.14)
                : const Color(0xFF3C3278).withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tags Header Row
                Row(
                  children: [
                    // Flash / Custom Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6D3CF0), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (t.tag != null && t.tag!.isNotEmpty ? t.tag! : 'FLASH ⚡').toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // State Tag
                    _buildStateTag(isLive, isUpcoming, isCompleted),

                    const Spacer(),

                    // Entry Tag (FREE / PAID)
                    _buildEntryTag(t),
                  ],
                ),

                const SizedBox(height: 12),

                // 2. Tournament Title
                Text(
                  t.title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF151B33),
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                if (t.description != null && t.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    t.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7390),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // 3. Prize Stage (Golden Trophy + Huge Coins + Real Cash Value Badge)
                _buildPrizeStage(t),

                const SizedBox(height: 12),

                // 4. Top Winners Podium (1st, 2nd, 3rd place preview)
                _buildTopWinnersPodium(t),

                const SizedBox(height: 14),

                // 5. Progress Bar Row
                _buildProgressRow(currentJoined, maxCap, spotsLeft, progressPct, hasCap),

                const SizedBox(height: 14),

                // 6. Footer (Countdown Timer & Main Action CTA)
                _buildFooter(isLive, isUpcoming, isCompleted, isJoined, t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateTag(bool isLive, bool isUpcoming, bool isCompleted) {
    if (isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8E8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _blinkController,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'LIVE',
              style: GoogleFonts.outfit(
                color: const Color(0xFFC62828),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (isUpcoming) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF0F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'UPCOMING',
          style: GoogleFonts.outfit(
            color: const Color(0xFF4B5575),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'ENDED',
        style: GoogleFonts.outfit(
          color: const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEntryTag(Tournament t) {
    if (t.entryType == TournamentEntryType.free) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFDDF8E6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '🎬 FREE (Watch Ad)',
          style: GoogleFonts.outfit(
            color: const Color(0xFF15803D),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1CC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '🪙 ${t.entryFeeCoins} Coins',
        style: GoogleFonts.outfit(
          color: const Color(0xFFC2650A),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPrizeStage(Tournament t) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3D1), Color(0xFFFFD98A), Color(0xFFFFC45C)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE3A3), width: 1.2),
      ),
      child: Stack(
        children: [
          // Background Trophy illustration
          const Positioned(
            right: 8,
            bottom: 4,
            child: Opacity(
              opacity: 0.28,
              child: Icon(
                Icons.emoji_events_rounded,
                size: 96,
                color: Color(0xFFD97706),
              ),
            ),
          ),

          // Foreground Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PRIZE POOL pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '🏆 PRIZE POOL',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A4B08),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Coins Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: const Text('🪙', style: TextStyle(fontSize: 24)),
                    ),
                    Text(
                      _formatNumber(t.prizePool),
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF7C3A00),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'COINS',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF7C3A00),
                      ),
                    ),
                  ],
                ),

                // Real Cash Value Pill (Rupees)
                if (t.prizePoolRupees > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF15803D).withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          child: const Center(
                            child: Text(
                              '₹',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${t.prizePoolRupees}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'real cash\nvalue',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopWinnersPodium(Tournament t) {
    // Determine Top 3 prizes (Rupees and Coins)
    final tiers = t.prizeStructure;
    final medals = ['🥇', '🥈', '🥉'];
    final places = ['1st place', '2nd place', '3rd place'];

    return Row(
      children: List.generate(3, (idx) {
        String prizeDisplay = '';
        if (idx < tiers.length) {
          final tier = tiers[idx];
          final rupees = tier.getCalculatedRupees(t.prizePool, t.prizePoolRupees);
          if (rupees > 0) {
            prizeDisplay = '₹$rupees';
          } else {
            prizeDisplay = '${_formatNumber(tier.prize)}c';
          }
        } else {
          // Standard proportional fallback
          if (t.prizePoolRupees > 0) {
            final fallbackRupees = [
              (t.prizePoolRupees * 0.5).round(),
              (t.prizePoolRupees * 0.3).round(),
              (t.prizePoolRupees * 0.2).round(),
            ];
            prizeDisplay = '₹${fallbackRupees[idx]}';
          } else {
            final fallbackCoins = [
              (t.prizePool * 0.5).round(),
              (t.prizePool * 0.3).round(),
              (t.prizePool * 0.2).round(),
            ];
            prizeDisplay = '${_formatNumber(fallbackCoins[idx])}c';
          }
        }

        final isGold = idx == 0;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: idx < 2 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isGold ? const Color(0xFFFFF8E6) : const Color(0xFFFAFAFE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isGold ? const Color(0xFFFFE3A3) : const Color(0xFFE6E8F2),
              ),
            ),
            child: Column(
              children: [
                Text(medals[idx], style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 3),
                Text(
                  prizeDisplay,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF15803D),
                  ),
                ),
                Text(
                  places[idx],
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7390),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProgressRow(int currentJoined, int? maxCap, int spotsLeft, double progressPct, bool hasCap) {
    if (hasCap && maxCap != null) {
      final isFull = spotsLeft <= 0;
      final isHot = spotsLeft <= (maxCap * 0.35).round() || spotsLeft <= 25;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$currentJoined',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF151B33),
                      ),
                    ),
                    TextSpan(
                      text: ' / $maxCap joined',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7390),
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                isFull
                    ? '🔒 Full'
                    : (isHot ? '🔥 $spotsLeft spots left' : '$spotsLeft spots left'),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isFull
                      ? const Color(0xFFDC2626)
                      : (isHot ? const Color(0xFFD9480F) : const Color(0xFF6B7390)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 8,
              color: const Color(0xFFECEEF7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progressPct,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFull
                            ? const [Color(0xFFEF4444), Color(0xFFDC2626)]
                            : const [Color(0xFF6D3CF0), Color(0xFF8B5CF6)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Unlimited capacity
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$currentJoined',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF151B33),
                      ),
                    ),
                    TextSpan(
                      text: ' players joined',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7390),
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '✨ Open Arena',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFooter(bool isLive, bool isUpcoming, bool isCompleted, bool isJoined, Tournament t) {
    return Row(
      children: [
        // Left Timer block
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLive ? 'Ends in' : 'Starts in',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7390),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTimerDigits(_remainingTime),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF151B33),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),

        // Right CTA Button
        Expanded(
          child: _buildCtaButton(isLive, isUpcoming, isCompleted, isJoined, t),
        ),
      ],
    );
  }

  Widget _buildCtaButton(bool isLive, bool isUpcoming, bool isCompleted, bool isJoined, Tournament t) {
    if (isCompleted) {
      return OutlinedButton(
        onPressed: widget.onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6D3CF0),
          side: const BorderSide(color: Color(0xFFD9CCFB), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        child: Text(
          'Results 🏆',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      );
    }

    if (isUpcoming) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'Upcoming • ${_formatUpcomingTime(t.startTime)}',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (isJoined) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF15803D), Color(0xFF22C55E)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15803D).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill_rounded, size: 18),
              const SizedBox(width: 6),
              Text(
                'Play Now 🎮',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Live and unjoined: CTA Button
    final bool hasCap = t.maxParticipants != null && t.maxParticipants! > 0;
    final bool isFull = hasCap && t.currentParticipants >= t.maxParticipants!;

    if (isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Center(
          child: Text(
            'Arena Full 🔒',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
      );
    }

    final bool isFree = t.entryType == TournamentEntryType.free;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D3CF0), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D3CF0).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: widget.onJoinTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isFree
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Join Free',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  Text(
                    '• watch ad 🎬',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Join Tournament',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  Text(
                    '• ${t.entryFeeCoins} Coins',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatUpcomingTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final isTomorrow = dt.year == now.year && dt.month == now.month && dt.day == now.day + 1;

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $ampm';

    if (isToday) {
      return 'Today, $timeStr';
    } else if (isTomorrow) {
      return 'Tomorrow, $timeStr';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthStr = months[dt.month - 1];
      return '${dt.day} $monthStr, $timeStr';
    }
  }
}
