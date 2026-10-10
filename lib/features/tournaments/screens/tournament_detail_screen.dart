import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tournament_models.dart';
import '../providers/tournament_providers.dart';
import '../widgets/tournament_join_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(tournamentDetailProvider(widget.tournamentId));

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
        title: Text(
          'Tournament Arena',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded, color: Color(0xFF6E5DE7)),
            onPressed: () => context.push('/tournaments/${widget.tournamentId}/leaderboard'),
          ),
        ],
      ),
      body: detailAsync.when(
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

          return RefreshIndicator(
            color: const Color(0xFF6E5DE7),
            onRefresh: () async {
              ref.invalidate(tournamentDetailProvider(widget.tournamentId));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Card (Timer, Title, Prize Pool)
                  _buildHeroCard(tournament),
                  const SizedBox(height: 16),

                  // 2. User Status & Participation Bar
                  _buildUserStatusBar(tournament),
                  const SizedBox(height: 22),

                  // 3. Rewards Header
                  _buildRewardsHeader(),
                  const SizedBox(height: 14),

                  // 4. 3D Podium Stage
                  _buildPodiumStage(tournament),
                  const SizedBox(height: 16),

                  // 5. Prize Distribution Card
                  _buildPrizeDistributionCard(tournament),
                  const SizedBox(height: 24),

                  // 6. Allowed Games Overview Card
                  _buildAllowedGamesSummary(tournament),
                  const SizedBox(height: 24),

                  // 7. Rules & Scoring Card
                  _buildRulesCard(),
                  const SizedBox(height: 90), // Padding for bottom sticky bar
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6E5DE7)),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: GoogleFonts.outfit(color: Colors.red)),
        ),
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (tournament) => tournament != null
            ? Container(
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
                              foregroundColor: const Color(0xFF6D3CF0),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF6D3CF0), width: 1.8),
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
                                const SizedBox(width: 6),
                                Text(
                                  'Leaderboard',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: const Color(0xFF6D3CF0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Play CTA (Vibrant Purple Gradient)
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6D3CF0), Color(0xFF8B5CF6)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6D3CF0).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (tournament.isJoined) {
                                context.push('/tournaments/${tournament.id}/games');
                              } else if (tournament.isUpcoming) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'This tournament starts in ${_formatDuration(_remaining)}! Stay tuned.',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: const Color(0xFF6D3CF0),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                TournamentJoinDialog.show(
                                  context: context,
                                  ref: ref,
                                  tournament: tournament,
                                  onJoinSuccess: () {
                                    ref.invalidate(tournamentDetailProvider(widget.tournamentId));
                                    ref.invalidate(liveTournamentsProvider);
                                    ref.invalidate(myTournamentsProvider);
                                  },
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
                                const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'Play >',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
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
              )
            : const SizedBox.shrink(),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHeroCard(Tournament tournament) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6E5DE7), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E5DE7).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Tag & Live Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (tournament.tag != null && tournament.tag!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tournament.tag!.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

              // Countdown Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tournament.isLive ? Icons.timer_rounded : Icons.access_time_rounded,
                      color: const Color(0xFFFFD43B),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tournament.isLive ? 'Ends in ${_formatDuration(_remaining)}' : 'Starts in ${_formatDuration(_remaining)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            tournament.title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
          ),

          if (tournament.description != null && tournament.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tournament.description!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Prize Pool and Players Stats Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Prize Pool
                Column(
                  children: [
                    Text(
                      'TOTAL PRIZE POOL',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD43B), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          tournament.prizePoolRupees > 0
                              ? '${tournament.prizePool} Coins (₹${tournament.prizePoolRupees})'
                              : '${tournament.prizePool} Coins',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFD43B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),

                // Total Players
                Column(
                  children: [
                    Text(
                      'REGISTERED PLAYERS',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${tournament.currentParticipants} Players',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatusBar(Tournament tournament) {
    if (!tournament.isJoined) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_esports_rounded, color: Color(0xFF6E5DE7), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You Haven\'t Joined Yet',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                  ),
                  Text(
                    tournament.entryType == TournamentEntryType.free
                        ? 'Watch 1 rewarded video to enter free!'
                        : 'Entry fee: ${tournament.entryFeeCoins} Coins',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final p = tournament.userParticipation!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are Entered! 🎉',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF166534)),
                  ),
                  Text(
                    'Current Score: ${p.score} Points',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                  ),
                ],
              ),
            ],
          ),
          if (p.rank != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Rank #${p.rank}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatNumber(num value) {
    final str = value.toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  Widget _buildRewardsHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Text('👑', style: TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Tournament ',
                      style: TextStyle(color: Color(0xFF0F172A)),
                    ),
                    TextSpan(
                      text: 'Rewards',
                      style: TextStyle(color: Color(0xFF6D3CF0)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Top players win bigger rewards!',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                'Prize Distribution',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6D3CF0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PrizeTier? _findTierForRank(Tournament tournament, int rank) {
    for (final t in tournament.prizeStructure) {
      if (rank >= t.rankMin && rank <= t.rankMax) return t;
    }
    if (tournament.prizeStructure.length >= rank) {
      return tournament.prizeStructure[rank - 1];
    }
    return null;
  }

  Widget _buildPodiumStage(Tournament tournament) {
    final t1 = _findTierForRank(tournament, 1);
    final t2 = _findTierForRank(tournament, 2);
    final t3 = _findTierForRank(tournament, 3);

    final coins1 = t1?.prize ?? (tournament.prizePool * 0.5).round();
    final rupees1 = t1?.getCalculatedRupees(tournament.prizePool, tournament.prizePoolRupees) ??
        (tournament.prizePoolRupees > 0 ? (tournament.prizePoolRupees * 0.5).round() : 0);

    final coins2 = t2?.prize ?? (tournament.prizePool * 0.3).round();
    final rupees2 = t2?.getCalculatedRupees(tournament.prizePool, tournament.prizePoolRupees) ??
        (tournament.prizePoolRupees > 0 ? (tournament.prizePoolRupees * 0.3).round() : 0);

    final coins3 = t3?.prize ?? (tournament.prizePool * 0.2).round();
    final rupees3 = t3?.getCalculatedRupees(tournament.prizePool, tournament.prizePoolRupees) ??
        (tournament.prizePoolRupees > 0 ? (tournament.prizePoolRupees * 0.2).round() : 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAF5FF),
            Color(0xFFF3E8FF),
            Color(0xFFEDE9FE),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D3CF0).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative background sparkles & confetti
          const Positioned(top: 6, left: 14, child: Text('✨', style: TextStyle(fontSize: 16))),
          const Positioned(top: 18, right: 16, child: Text('🪙', style: TextStyle(fontSize: 16))),
          const Positioned(bottom: 75, left: 12, child: Text('🪙', style: TextStyle(fontSize: 14))),
          const Positioned(bottom: 85, right: 14, child: Text('✨', style: TextStyle(fontSize: 14))),
          const Positioned(top: 8, left: 110, child: Text('🎉', style: TextStyle(fontSize: 12))),

          // 3 Podiums Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Left)
              Expanded(
                flex: 10,
                child: _buildPodiumColumn(
                  place: 2,
                  placeLabel: '2nd Place',
                  coins: coins2,
                  rupees: rupees2,
                  pedestalHeight: 88,
                  gradientColors: const [Color(0xFFF1F5F9), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
                  topFaceColor: const Color(0xFFF8FAFC),
                  badgeColor: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),

              // 1st Place (Center - Tallest)
              Expanded(
                flex: 12,
                child: _buildPodiumColumn(
                  place: 1,
                  placeLabel: '1st Place',
                  coins: coins1,
                  rupees: rupees1,
                  pedestalHeight: 124,
                  gradientColors: const [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFD97706)],
                  topFaceColor: const Color(0xFFFEF3C7),
                  badgeColor: const Color(0xFFD97706),
                  isFirst: true,
                ),
              ),
              const SizedBox(width: 8),

              // 3rd Place (Right - Shortest)
              Expanded(
                flex: 10,
                child: _buildPodiumColumn(
                  place: 3,
                  placeLabel: '3rd Place',
                  coins: coins3,
                  rupees: rupees3,
                  pedestalHeight: 64,
                  gradientColors: const [Color(0xFFFFEDD5), Color(0xFFFB923C), Color(0xFFC2410C)],
                  topFaceColor: const Color(0xFFFFF7ED),
                  badgeColor: const Color(0xFFC2410C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required int place,
    required String placeLabel,
    required int coins,
    required int rupees,
    required double pedestalHeight,
    required List<Color> gradientColors,
    required Color topFaceColor,
    required Color badgeColor,
    bool isFirst = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Trophy & Crown
        _buildTrophyWidget(place: place, isFirst: isFirst),
        const SizedBox(height: 6),

        // 3D Pedestal
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Face (3D bevel)
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: topFaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            // Front Face
            Container(
              height: pedestalHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      placeLabel,
                      style: GoogleFonts.outfit(
                        fontSize: isFirst ? 11 : 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Base shadow
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Coin Amount Pill
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 3),
              Text(
                '${_formatNumber(coins)} Coins',
                style: GoogleFonts.outfit(
                  fontSize: isFirst ? 12 : 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),

        // Rupees Badge
        if (rupees > 0) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Text(
              '₹$rupees',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF15803D),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrophyWidget({required int place, required bool isFirst}) {
    if (isFirst) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👑', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '1',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 22,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      );
    } else if (place == 2) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '2',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 20,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF64748B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 18),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFEDD5), Color(0xFFFB923C), Color(0xFFC2410C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '3',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 18,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF9A3412),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPrizeDistributionCard(Tournament tournament) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🎁', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prize Distribution',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Rank higher and win exciting coin rewards!',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tiers
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tournament.prizeStructure.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final tier = tournament.prizeStructure[idx];
              return _buildPrizeTierRow(tournament, tier);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeTierRow(Tournament tournament, PrizeTier tier) {
    final isRank1 = tier.rankMin == 1 && tier.rankMax == 1;
    final isRank2 = tier.rankMin == 2 && tier.rankMax == 2;
    final isRank3 = tier.rankMin == 3 && tier.rankMax == 3;

    Color bg;
    Color border;
    Color labelColor;
    Color amountColor;
    String iconEmoji;

    if (isRank1) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      labelColor = const Color(0xFFB45309);
      amountColor = const Color(0xFF92400E);
      iconEmoji = '👑';
    } else if (isRank2) {
      bg = const Color(0xFFF5F3FF);
      border = const Color(0xFFDDD6FE);
      labelColor = const Color(0xFF6D28D9);
      amountColor = const Color(0xFF5B21B6);
      iconEmoji = '👑';
    } else if (isRank3) {
      bg = const Color(0xFFFFF7ED);
      border = const Color(0xFFFED7AA);
      labelColor = const Color(0xFFC2410C);
      amountColor = const Color(0xFF9A3412);
      iconEmoji = '👑';
    } else {
      bg = const Color(0xFFF8FAFC);
      border = const Color(0xFFE2E8F0);
      labelColor = const Color(0xFF334155);
      amountColor = const Color(0xFF1E293B);
      iconEmoji = '🎖️';
    }

    final rupees = tier.getCalculatedRupees(tournament.prizePool, tournament.prizePoolRupees);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: isRank1 || isRank2 || isRank3 ? 1.5 : 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(iconEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Rank ${tier.label}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: labelColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text(
                '${_formatNumber(tier.prize)} Coins',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: amountColor,
                ),
              ),
              if (rupees > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    '₹$rupees',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllowedGamesSummary(Tournament tournament) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sports_esports_rounded, color: Color(0xFF6E5DE7), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allowed Arena Games 🎮',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${tournament.allowedGames.length} casual games available to score',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (tournament.isJoined)
                TextButton(
                  onPressed: () => context.push('/tournaments/${tournament.id}/games'),
                  child: Text(
                    'Play Games →',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12, color: const Color(0xFF6E5DE7)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tournament.allowedGames.map((gameId) {
              final gameNames = {
                'arrow_escape': '🏹 Arrow Escape',
                'water_sort': '🧪 Colour Sort',
                'bubble_shooter': '🫧 Bubble Sort',
                'treasure_grid': '💎 Treasure Grid',
                'math_rush': '➗ Math Rush',
                'emoji_memory': '🃏 Emoji Memory',
              };
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  gameNames[gameId] ?? gameId,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
              );
            }).toList(),
          ),
          if (!tournament.isJoined) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Join the tournament using the button below to start playing games and scoring points!',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF6E5DE7), size: 18),
              const SizedBox(width: 8),
              Text(
                'Fair Play & Scoring Rules',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildBullet('1 Coin Earned in Casual Games = 1 Tournament Point.'),
          _buildBullet('Scores are updated instantly after completing each level/session.'),
          _buildBullet('Daily bonuses, spin wheel, and surveys do NOT count towards tournament score.'),
          _buildBullet('In case of a tie, the player who reached the score first ranks higher.'),
          _buildBullet('Prizes are credited automatically to wallet when tournament ends.'),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF6E5DE7), fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
