import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tournament_models.dart';
import '../providers/tournament_providers.dart';

class TournamentGamesScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentGamesScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentGamesScreen> createState() => _TournamentGamesScreenState();
}

class _TournamentGamesScreenState extends ConsumerState<TournamentGamesScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds > 0) {
        setState(() {
          _remaining = _remaining - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return '00:00:00';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _launchGame(BuildContext context, String gameType, Tournament tournament) {
    // Set active tournament ID so score increment is attributed to this tournament
    ref.read(activeTournamentIdProvider.notifier).setActive(tournament.id);

    switch (gameType) {
      case 'arrow_escape':
        context.push('/games/arrow_escape');
        break;
      case 'water_sort':
        context.push('/games/water_sort');
        break;
      case 'bubble_shooter':
        context.push('/games/bubble_shooter');
        break;
      case 'math_rush':
        context.push('/games/math_rush');
        break;
      case 'emoji_memory':
        context.push('/games/emoji_memory');
        break;
      case 'treasure_grid':
        context.push('/games/treasure_grid');
        break;
      default:
        context.push('/games/arrow_escape');
        break;
    }
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
          'Arena Games 🎮',
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

          if (_remaining.inSeconds == 0) {
            _remaining = tournament.timeRemaining;
          }

          final p = tournament.userParticipation;
          final gameConfigs = [
            {
              'id': 'arrow_escape',
              'title': 'Arrow Escape',
              'subtitle': 'Directional Puzzle',
              'color': const Color(0xFFF64D67),
              'bg': const Color(0xFFFEF6F7),
              'icon': Icons.navigation_rounded,
            },
            {
              'id': 'water_sort',
              'title': 'Colour Sort',
              'subtitle': 'Liquid Tube Sort',
              'color': const Color(0xFF3B82F6),
              'bg': const Color(0xFFEFF6FF),
              'icon': Icons.science_rounded,
            },
            {
              'id': 'bubble_shooter',
              'title': 'Bubble Sort',
              'subtitle': 'Bubble Match 3',
              'color': const Color(0xFF10B981),
              'bg': const Color(0xFFECFDF5),
              'icon': Icons.bubble_chart_rounded,
            },
            {
              'id': 'treasure_grid',
              'title': 'Treasure Grid',
              'subtitle': 'Mine & Gem Hunt',
              'color': const Color(0xFFF59E0B),
              'bg': const Color(0xFFFFFBEB),
              'icon': Icons.grid_view_rounded,
            },
            {
              'id': 'math_rush',
              'title': 'Math Rush',
              'subtitle': 'Speed Arithmetic',
              'color': const Color(0xFF8B5CF6),
              'bg': const Color(0xFFF5F3FF),
              'icon': Icons.calculate_rounded,
            },
            {
              'id': 'emoji_memory',
              'title': 'Emoji Memory',
              'subtitle': 'Card Flip & Match',
              'color': const Color(0xFFEC4899),
              'bg': const Color(0xFFFDF2F8),
              'icon': Icons.sentiment_very_satisfied_rounded,
            },
          ];

          final activeGames = gameConfigs.where((g) => tournament.allowedGames.contains(g['id'])).toList();

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
                  // 1. Standing & Timer Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4338CA), Color(0xFF6E5DE7), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6E5DE7).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                tournament.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_rounded, color: Color(0xFFFFD43B), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(_remaining),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Score & Rank Cards Row
                        Row(
                          children: [
                            // Current Score
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'YOUR SCORE',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(alpha: 0.75),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p?.score ?? 0} pts',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFFFD43B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Current Rank
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CURRENT RANK',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(alpha: 0.75),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p?.rank != null ? '#${p!.rank}' : 'Rank -',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
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

                  const SizedBox(height: 20),

                  // 2. Select Game Title & Subtitle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select a Game to Play 🎯',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF8E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '1 Coin = 1 Point',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Play as many rounds as you like to climb the leaderboard!',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Games Grid (2x3)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: activeGames.length,
                    itemBuilder: (context, idx) {
                      final game = activeGames[idx];
                      final Color primaryColor = game['color'] as Color;
                      final Color bgColor = game['bg'] as Color;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(game['icon'] as IconData, color: primaryColor, size: 24),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'POINTS',
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game['title'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  game['subtitle'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _launchGame(context, game['id'] as String, tournament),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_arrow_rounded, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Play Arena',
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // 4. Fair Play & Scoring Note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Scores update instantly upon game completion. Play anytime before the timer ends!',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/tournaments/${widget.tournamentId}/leaderboard'),
              icon: const Icon(Icons.leaderboard_rounded, size: 18),
              label: Text(
                'View Leaderboard 🏆',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E5DE7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
