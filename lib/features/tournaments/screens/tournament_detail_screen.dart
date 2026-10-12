import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tournament_models.dart';
import '../providers/tournament_providers.dart';
import '../widgets/tournament_join_dialog.dart';
import '../widgets/prize_distribution_table.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _isJoinedLocally = false;

  void _handleJoinSuccess(Tournament tournament) {
    if (mounted) {
      setState(() {
        _isJoinedLocally = true;
      });
    }
    ref.read(joinedTournamentIdsProvider.notifier).markJoined(widget.tournamentId);
    ref.read(joinedTournamentIdsProvider.notifier).markJoined(tournament.id);
    ref.invalidate(tournamentDetailProvider(widget.tournamentId));
    ref.invalidate(liveTournamentsProvider);
    ref.invalidate(myTournamentsProvider);
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) return '00:00:00';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatTournamentDate(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final isTomorrow = dt.year == now.year && dt.month == now.month && dt.day == now.day + 1;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = months[dt.month - 1];

    if (isToday) {
      return 'Today, ${dt.day} $monthStr';
    } else if (isTomorrow) {
      return 'Tomorrow, ${dt.day} $monthStr';
    } else {
      return '${dt.day} $monthStr';
    }
  }

  String _formatNumber(num value) {
    final str = value.toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(tournamentDetailProvider(widget.tournamentId));
    final joinedIds = ref.watch(joinedTournamentIdsProvider);
    final isOptimisticallyJoined = _isJoinedLocally ||
        joinedIds.any((id) => id.trim().toLowerCase() == widget.tournamentId.trim().toLowerCase());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'Tournament Arena',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Compete in games and win exciting rewards!',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFF5B1FE6), size: 24),
            onPressed: () => context.push('/tournaments/${widget.tournamentId}/leaderboard'),
          ),
        ],
      ),
      body: detailAsync.when(
        skipLoadingOnReload: true,
        data: (tournament) {
          if (tournament == null) {
            return Center(
              child: Text(
                'Tournament not found',
                style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF64748B)),
              ),
            );
          }

          _remaining = tournament.timeRemaining;
          final isJoined = tournament.isJoined || isOptimisticallyJoined;

          return RefreshIndicator(
            color: const Color(0xFF5B1FE6),
            onRefresh: () async {
              ref.invalidate(tournamentDetailProvider(widget.tournamentId));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Card (Deep Purple Banner with Prize Pool & Trophy)
                  _buildHeroCard(tournament, isOptimisticallyJoined),
                  const SizedBox(height: 14),

                  // 2. User Status Bar (Green Entered Pill if joined)
                  _buildUserStatusBar(tournament, isJoined),
                  const SizedBox(height: 16),

                  // 3. Prize Distribution Section (Rank #1, #2, #3, #4-#10, #11-#50)
                  _buildPrizeDistributionSection(tournament),
                  const SizedBox(height: 16),

                  // 4. Allowed Arena Games (2-Column Grid)
                  _buildAllowedGamesSection(tournament, isJoined),
                  const SizedBox(height: 16),

                  // 5. Fair Play & Scoring Rules
                  _buildFairPlayRulesCard(),
                  const SizedBox(height: 100), // Padding for sticky bottom navigation bar
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF5B1FE6)),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: GoogleFonts.outfit(color: Colors.red)),
        ),
      ),
      bottomNavigationBar: () {
        final tournament = detailAsync.valueOrNull;
        if (tournament == null) return const SizedBox.shrink();
        final isJoined = tournament.isJoined || isOptimisticallyJoined;
        return _buildStickyBottomBar(tournament, isJoined);
      }(),
    );
  }

  Widget _buildStickyBottomBar(Tournament tournament, bool isJoined) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // View Leaderboard CTA (White with purple border)
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => context.push('/tournaments/${tournament.id}/leaderboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5B1FE6),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF5B1FE6), width: 1.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Leaderboard',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: const Color(0xFF5B1FE6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Play CTA (Vibrant Green if joined, Purple if not)
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: isJoined
                      ? const LinearGradient(
                          colors: [Color(0xFF00C06D), Color(0xFF00A859)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF5B1FE6), Color(0xFF8B5CF6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: (isJoined ? const Color(0xFF00C06D) : const Color(0xFF5B1FE6))
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (isJoined) {
                      context.push('/tournaments/${tournament.id}/games');
                    } else if (tournament.isUpcoming) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'This tournament starts in ${_formatDuration(_remaining)}! Stay tuned.',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFF5B1FE6),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      final isFull = tournament.maxParticipants != null &&
                          tournament.maxParticipants! > 0 &&
                          tournament.currentParticipants >= tournament.maxParticipants!;
                      if (isFull) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'This tournament arena is full! No more spots available.',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      TournamentJoinDialog.show(
                        context: context,
                        ref: ref,
                        tournament: tournament,
                        onJoinSuccess: () => _handleJoinSuccess(tournament),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isJoined ? Icons.play_circle_fill_rounded : Icons.sports_esports_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isJoined
                            ? 'Play Now 🎮'
                            : (tournament.maxParticipants != null &&
                                    tournament.maxParticipants! > 0 &&
                                    tournament.currentParticipants >= tournament.maxParticipants!
                                ? 'Arena Full 🔒'
                                : (tournament.isUpcoming ? 'Starts Soon ⏰' : 'Join Now ⚔️')),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Hero Card
  Widget _buildHeroCard(Tournament tournament, bool isOptimisticallyJoined) {
    final int cashRupees = tournament.prizePoolRupees > 0
        ? tournament.prizePoolRupees
        : (tournament.prizePool / 20).round();
    final maxCap = tournament.maxParticipants;
    final hasCap = maxCap != null && maxCap > 0;
    final effectiveJoined = (hasCap && isOptimisticallyJoined && !tournament.isJoined)
        ? tournament.currentParticipants + 1
        : tournament.currentParticipants;
    final spotsLeft = hasCap ? (maxCap - effectiveJoined).clamp(0, maxCap) : 0;
    final progressPct = hasCap ? (effectiveJoined / maxCap).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF281366),
            Color(0xFF1E0E52),
            Color(0xFF140838),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF281366).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Tag pill (MEGA 🏆) + Live pill (🔴 LIVE)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tag pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (tournament.tag != null && tournament.tag!.isNotEmpty
                                ? tournament.tag!
                                : 'MEGA')
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
                      const SizedBox(width: 5),
                      const Text('🏆', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),

                // Status pill
                if (tournament.isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE11D48),
                            shape: BoxShape.circle,
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
                  )
                else if (tournament.isUpcoming)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ENDED',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Tournament Title
            Text(
              tournament.title,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.4,
                height: 1.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Date and Remaining Timer Info Row
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white70),
                const SizedBox(width: 5),
                Text(
                  _formatTournamentDate(tournament.startTime),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 10),
                Text('|', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
                const SizedBox(width: 10),
                const Icon(Icons.access_time_rounded, size: 13, color: Colors.white70),
                const SizedBox(width: 5),
                Text(
                  tournament.isLive
                      ? 'Ends in ${_formatDuration(_remaining)}'
                      : (tournament.isUpcoming
                          ? 'Starts in ${_formatDuration(_remaining)}'
                          : 'Ended'),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Prize Pool Box + 3D Golden Trophy
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Prize Pool Box
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              'TOTAL PRIZE POOL',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF78350F),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/games_hub/coins_stack.png',
                                height: 26,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Text('🪙', style: TextStyle(fontSize: 18)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatNumber(tournament.prizePool),
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF3F1D0B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Coins',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF5A2A0C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🪙 ≈ ', style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                              Text(
                                '₹${_formatNumber(cashRupees)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Right 3D Trophy + Sparkles
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 105,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFB800).withValues(alpha: 0.22),
                          ),
                        ),
                        Image.asset(
                          'assets/images/games_hub/levelrewards.png',
                          height: 95,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/water_sort/trophy_gold.png',
                            height: 95,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text('🏆', style: TextStyle(fontSize: 60)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Registered Players & Spots Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      hasCap
                          ? '$effectiveJoined / ${tournament.maxParticipants} Joined'
                          : '$effectiveJoined Joined',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  hasCap
                      ? (spotsLeft <= 0 ? 'Full' : '$spotsLeft spots left')
                      : 'Unlimited spots',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 6,
                color: Colors.white.withValues(alpha: 0.2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: hasCap ? progressPct : 1.0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFA855F7), Color(0xFFC084FC)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. User Status Bar (Green Entered Pill if joined)
  Widget _buildUserStatusBar(Tournament tournament, bool isJoined) {
    if (!isJoined) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_esports_rounded, color: Color(0xFF5B1FE6), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join Tournament Arena ⚔️',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Compete in games and climb the leaderboard for rewards!',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final p = tournament.userParticipation;
    final rankText = (p != null && p.rank != null) ? 'Rank #${p.rank}' : 'Rank #1';
    final score = p?.score ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDFCF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'You are Entered!',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('🎉', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Current Score: $score Points',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C06D), Color(0xFF16A34A)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👑', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text(
                  rankText,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Prize Distribution Section (Rank #1, #2, #3, #4-#10, #11-#50)
  Widget _buildPrizeDistributionSection(Tournament tournament) {
    return PrizeDistributionTable(tournament: tournament);
  }

  // 4. Allowed Arena Games (2-Column Grid)
  Widget _buildAllowedGamesSection(Tournament tournament, bool isJoined) {
    final gameInfoMap = {
      'treasure_grid': {'title': 'Treasure Grid', 'icon': '💎', 'bg': const Color(0xFFE0F2FE)},
      'emoji_memory': {'title': 'Emoji Memory', 'icon': '😃', 'bg': const Color(0xFFFEF3C7)},
      'math_rush': {'title': 'Math Rush', 'icon': '➕', 'bg': const Color(0xFFDCFCE7)},
      'water_sort': {'title': 'Colour Sort', 'icon': '🧪', 'bg': const Color(0xFFF3E8FF)},
      'bubble_shooter': {'title': 'Bubble Sort', 'icon': '🫧', 'bg': const Color(0xFFE0E7FF)},
      'arrow_escape': {'title': 'Arrow Escape', 'icon': '🏹', 'bg': const Color(0xFFFFEDD5)},
    };

    final games = tournament.allowedGames.isNotEmpty
        ? tournament.allowedGames
        : gameInfoMap.keys.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.sports_esports_rounded, color: Color(0xFF5B1FE6), size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Allowed Arena Games',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${games.length} casual games available to score points',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2-Column Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: games.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.7,
            ),
            itemBuilder: (context, index) {
              final gameId = games[index];
              final info = gameInfoMap[gameId] ?? {
                'title': gameId.replaceAll('_', ' ').toUpperCase(),
                'icon': '🎮',
                'bg': const Color(0xFFF1F5F9),
              };

              return InkWell(
                onTap: () {
                  if (isJoined) {
                    context.push('/tournaments/${tournament.id}/games');
                  } else {
                    TournamentJoinDialog.show(
                      context: context,
                      ref: ref,
                      tournament: tournament,
                      onJoinSuccess: () => _handleJoinSuccess(tournament),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: info['bg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            info['icon'] as String,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          info['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. Fair Play & Scoring Rules
  Widget _buildFairPlayRulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.shield_rounded, color: Color(0xFF5B1FE6), size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Fair Play & Scoring Rules',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Single-column Checkmark List (1 per row)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleCheckItem('1 Coin = 1 Tournament Point'),
              const SizedBox(height: 10),
              _buildRuleCheckItem('Instant score update'),
              const SizedBox(height: 10),
              _buildRuleCheckItem('Prizes credited to wallet directly'),
              const SizedBox(height: 10),
              _buildRuleCheckItem("Daily bonuses don't count towards tournament score"),
              const SizedBox(height: 10),
              _buildRuleCheckItem('In case of tie, player reaching score earlier wins'),
              const SizedBox(height: 10),
              _buildRuleCheckItem('Fair play strictly enforced • Anti-cheat active'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF5B1FE6), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
