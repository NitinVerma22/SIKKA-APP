import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tournament_models.dart';
import '../providers/tournament_providers.dart';

class TournamentCardTheme {
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;

  const TournamentCardTheme({
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
  });

  static TournamentCardTheme forTournament(Tournament t) {
    final tagLower = (t.tag ?? '').toLowerCase().trim();
    if (tagLower.contains('purple') || tagLower.contains('violet')) {
      return purple;
    } else if (tagLower.contains('blue') || tagLower.contains('sky') || tagLower.contains('azure')) {
      return blue;
    } else if (tagLower.contains('green') || tagLower.contains('emerald') || tagLower.contains('mint')) {
      return green;
    } else if (tagLower.contains('amber') || tagLower.contains('orange') || tagLower.contains('gold') || tagLower.contains('sunset') || tagLower.contains('yellow')) {
      return amber;
    } else if (tagLower.contains('rose') || tagLower.contains('pink') || tagLower.contains('red') || tagLower.contains('ruby')) {
      return rose;
    } else if (tagLower.contains('cyan') || tagLower.contains('teal') || tagLower.contains('ice') || tagLower.contains('aqua')) {
      return cyan;
    }

    // Default: deterministically cycle through 6 themes by tournament ID hash
    const themes = [purple, blue, green, amber, rose, cyan];
    final index = t.id.hashCode.abs() % themes.length;
    return themes[index];
  }

  static const purple = TournamentCardTheme(
    gradientColors: [Color(0xFFFCFAFF), Color(0xFFF3EDFF)],
    borderColor: Color(0xFFE4D7FF),
    shadowColor: Color(0x147C3AED),
  );

  static const blue = TournamentCardTheme(
    gradientColors: [Color(0xFFF6FAFF), Color(0xFFEAF3FE)],
    borderColor: Color(0xFFD2E6FE),
    shadowColor: Color(0x142563EB),
  );

  static const green = TournamentCardTheme(
    gradientColors: [Color(0xFFF4FBF7), Color(0xFFE5F7EC)],
    borderColor: Color(0xFFC4F1D4),
    shadowColor: Color(0x14059669),
  );

  static const amber = TournamentCardTheme(
    gradientColors: [Color(0xFFFFFBF3), Color(0xFFFFF1DF)],
    borderColor: Color(0xFFFDE1BF),
    shadowColor: Color(0x14D97706),
  );

  static const rose = TournamentCardTheme(
    gradientColors: [Color(0xFFFFF5F7), Color(0xFFFEE7ED)],
    borderColor: Color(0xFFFDD2DC),
    shadowColor: Color(0x14E11D48),
  );

  static const cyan = TournamentCardTheme(
    gradientColors: [Color(0xFFF2FBFC), Color(0xFFE2F6F9)],
    borderColor: Color(0xFFBFEFF6),
    shadowColor: Color(0x140891B2),
  );
}

class TournamentCard extends ConsumerStatefulWidget {
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
  ConsumerState<TournamentCard> createState() => _TournamentCardState();
}

class _TournamentCardState extends ConsumerState<TournamentCard> with SingleTickerProviderStateMixin {
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
    final isOptimisticallyJoined = ref.watch(joinedTournamentIdsProvider).any((id) => id.trim().toLowerCase() == t.id.trim().toLowerCase());
    final isJoined = t.isJoined || isOptimisticallyJoined;

    final maxCap = t.maxParticipants;
    final hasCap = maxCap != null && maxCap > 0;
    final effectiveJoined = (hasCap && isOptimisticallyJoined && !t.isJoined)
        ? t.currentParticipants + 1
        : t.currentParticipants;
    final spotsLeft = hasCap ? (maxCap - effectiveJoined).clamp(0, maxCap) : 0;
    final progressPct = hasCap ? (effectiveJoined / maxCap).clamp(0.0, 1.0) : 0.0;
    final cardTheme = TournamentCardTheme.forTournament(t);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardTheme.gradientColors,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: cardTheme.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardTheme.shadowColor,
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
                // 1. Header (Tournament Title on left, Status Pill on right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        t.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Pill (🔴 LIVE / ⏰ UPCOMING / ENDED)
                    _buildStateTag(isLive, isUpcoming, isCompleted),
                  ],
                ),

                const SizedBox(height: 12),

                // 2. Golden Prize Pool Stage
                _buildPrizeStage(t),

                const SizedBox(height: 12),

                // 3. Progress / Spots Row
                _buildProgressRow(effectiveJoined, maxCap, spotsLeft, progressPct, hasCap),

                const SizedBox(height: 14),

                // 4. Footer (Timer & Action CTA)
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
