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
                  const SizedBox(height: 20),

                  // 3. Prize Structure Section
                  _buildPrizeStructureSection(tournament),
                  const SizedBox(height: 24),

                  // 4. Allowed Games Overview Card
                  _buildAllowedGamesSummary(tournament),
                  const SizedBox(height: 24),

                  // 5. Rules & Scoring Card
                  _buildRulesCard(),
                  const SizedBox(height: 80), // Padding for bottom sticky bar
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
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // View Leaderboard CTA
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/tournaments/${tournament.id}/leaderboard'),
                          icon: const Icon(Icons.leaderboard_rounded, size: 18),
                          label: Text(
                            'Leaderboard 🏆',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6E5DE7),
                            side: const BorderSide(color: Color(0xFF6E5DE7), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Join, Play, or Upcoming button
                      if (tournament.isJoined) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.push('/tournaments/${tournament.id}/games');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_circle_fill_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Play Now 🎮',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else if (tournament.isUpcoming) ...[
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Upcoming Tournament',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => TournamentJoinDialog.show(
                              context: context,
                              ref: ref,
                              tournament: tournament,
                              onJoinSuccess: () {
                                ref.invalidate(tournamentDetailProvider(widget.tournamentId));
                                ref.invalidate(liveTournamentsProvider);
                                ref.invalidate(myTournamentsProvider);
                              },
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tournament.entryType == TournamentEntryType.free
                                  ? const Color(0xFF6E5DE7)
                                  : const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tournament.entryType == TournamentEntryType.free
                                      ? Icons.ondemand_video_rounded
                                      : Icons.monetization_on_rounded,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tournament.entryType == TournamentEntryType.free
                                      ? 'Join Free'
                                      : 'Join (${tournament.entryFeeCoins}c)',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildPrizeStructureSection(Tournament tournament) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prize Distribution 🏆',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
            ),
            Text(
              'Total: ${tournament.prizePool}c',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tournament.prizeStructure.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final tier = tournament.prizeStructure[idx];
              final isFirst = idx == 0;
              final isSecond = idx == 1;
              final isThird = idx == 2;

              Color bg = Colors.white;
              Color border = const Color(0xFFE2E8F0);
              Color iconColor = const Color(0xFF64748B);

              if (isFirst) {
                bg = const Color(0xFFFEF3C7);
                border = const Color(0xFFFDE68A);
                iconColor = const Color(0xFFD97706);
              } else if (isSecond) {
                bg = const Color(0xFFF1F5F9);
                border = const Color(0xFFCBD5E1);
                iconColor = const Color(0xFF475569);
              } else if (isThird) {
                bg = const Color(0xFFFFEDD5);
                border = const Color(0xFFFED7AA);
                iconColor = const Color(0xFFC2410C);
              }

              return Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events_rounded, color: iconColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          tier.label,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.getCalculatedRupees(tournament.prizePool, tournament.prizePoolRupees) > 0
                          ? '${tier.prize}c (₹${tier.getCalculatedRupees(tournament.prizePool, tournament.prizePoolRupees)})'
                          : '${tier.prize} Coins',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
