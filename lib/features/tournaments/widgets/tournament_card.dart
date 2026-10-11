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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isLive ? const Color(0xFFE9E4FF) : const Color(0xFFEFF1F7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFF6D3CF0).withValues(alpha: 0.08)
                : const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Header (Tag Pill + Live Status)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tag Pill (🏆 MEGA)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B1FE6), Color(0xFF7A2CE8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B1FE6).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            (t.tag != null && t.tag!.isNotEmpty ? t.tag! : 'MEGA')
                                .replaceAll('⚡', '')
                                .replaceAll('🔥', '')
                                .replaceAll('🏆', '')
                                .trim()
                                .toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Pill (🔴 LIVE / ⏰ UPCOMING / ENDED)
                    _buildStateTag(isLive, isUpcoming, isCompleted),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. Tournament Title
                Text(
                  t.title,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // 3. Golden Prize Pool Stage
                _buildPrizeStage(t),

                const SizedBox(height: 12),

                // 4. Progress / Spots Row
                _buildProgressRow(currentJoined, maxCap, spotsLeft, progressPct, hasCap),

                const SizedBox(height: 14),

                // 5. Footer (Timer & Action CTA)
                _buildFooter(isLive, isUpcoming, isCompleted, isJoined, t, hasCap, spotsLeft),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _blinkController,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE11D48),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'LIVE',
              style: GoogleFonts.outfit(
                color: const Color(0xFFE11D48),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    if (isUpcoming) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏰', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 5),
            Text(
              'UPCOMING',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2563EB),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
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

  Widget _buildPrizeStage(Tournament t) {
    final int cashRupees = t.prizePoolRupees > 0
        ? t.prizePoolRupees
        : (t.prizePool / 20).round();

    return Container(
      height: 116,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8D6),
            Color(0xFFFFE885),
            Color(0xFFFFD43F),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE066), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB800).withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Coins Stack
            SizedBox(
              width: 78,
              child: Image.asset(
                'assets/images/games_hub/coins_stack.png',
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/water_sort/coin_pile.png',
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🪙', style: TextStyle(fontSize: 40)),
                  ),
                ),
              ),
            ),

            // Center Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🏆 PRIZE POOL pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          'PRIZE POOL',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF78350F),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 10,000 COINS
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${_formatNumber(t.prizePool)} ',
                            style: GoogleFonts.outfit(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF3F1D0B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'COINS',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF5A2A0C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // ≈ ₹500 (Mint green pill)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '≈ ',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF78350F),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA7F3D0), width: 1.0),
                        ),
                        child: Text(
                          '₹${_formatNumber(cashRupees)}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Golden Trophy
            SizedBox(
              width: 78,
              child: Image.asset(
                'assets/images/water_sort/trophy_gold.png',
                height: 76,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 42)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(
    int currentJoined,
    int? maxCap,
    int spotsLeft,
    double progressPct,
    bool hasCap,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF5B1FE6)),
                const SizedBox(width: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$currentJoined',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF151B33),
                        ),
                      ),
                      TextSpan(
                        text: hasCap ? ' / $maxCap joined' : ' joined',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              hasCap
                  ? (spotsLeft <= 0 ? 'Full' : '$spotsLeft spots left')
                  : 'Unlimited spots',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 6,
            color: const Color(0xFFECEEF7),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: hasCap ? progressPct : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasCap && spotsLeft <= 0
                          ? const [Color(0xFFEF4444), Color(0xFFDC2626)]
                          : const [Color(0xFF5B1FE6), Color(0xFF7A2CE8)],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(
    bool isLive,
    bool isUpcoming,
    bool isCompleted,
    bool isJoined,
    Tournament t,
    bool hasCap,
    int spotsLeft,
  ) {
    return Row(
      children: [
        // Left Timer block
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLive ? 'Ends in' : (isUpcoming ? 'Starts in' : 'Ended'),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTimerDigits(_remainingTime),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),

        // Vertical separator
        Container(
          height: 34,
          width: 1.5,
          color: const Color(0xFFF1F5F9),
          margin: const EdgeInsets.symmetric(horizontal: 14),
        ),

        // Right CTA Button
        Expanded(
          child: _buildCtaButton(
            isLive,
            isUpcoming,
            isCompleted,
            isJoined,
            t,
            hasCap,
            spotsLeft,
          ),
        ),
      ],
    );
  }

  Widget _buildCtaButton(
    bool isLive,
    bool isUpcoming,
    bool isCompleted,
    bool isJoined,
    Tournament t,
    bool hasCap,
    int spotsLeft,
  ) {
    if (isCompleted) {
      return OutlinedButton(
        onPressed: widget.onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5B1FE6),
          side: const BorderSide(color: Color(0xFFD9CCFB), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          'Results 🏆',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      );
    }

    if (isUpcoming) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'Starts Soon ⏰',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      );
    }

    // When joined: Play Now 🎮 (Vibrant Green)
    if (isJoined) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C06D), Color(0xFF00A859)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C06D).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                'Play Now 🎮',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Live & unjoined
    final isFull = hasCap && spotsLeft <= 0;
    if (isFull) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          'Arena Full 🔒',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
        ),
      );
    }

    final isFree = t.entryType == TournamentEntryType.free;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFree
              ? const [Color(0xFF00C06D), Color(0xFF00A859)]
              : const [Color(0xFF5B1FE6), Color(0xFF7A2CE8)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isFree ? const Color(0xFF00C06D) : const Color(0xFF5B1FE6))
                .withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: widget.onJoinTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFree ? Icons.play_circle_fill_rounded : Icons.flash_on_rounded,
              color: Colors.white,
              size: 19,
            ),
            const SizedBox(width: 6),
            Text(
              isFree ? 'Join Free 🎬' : 'Join • 🪙 ${t.entryFeeCoins}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
