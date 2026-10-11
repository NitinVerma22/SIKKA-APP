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
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFF5B1FE6), size: 24),
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

          final allGames = [
            {
              'id': 'treasure_grid',
              'title': 'Treasure Grid',
              'desc': 'Tap tiles to find coins & avoid bombs.',
              'icon': '💎',
              'leftImage': 'assets/images/games_hub/treasure_grid_left.webp',
              'rightImage': 'assets/images/games_hub/treasure_grid_right.webp',
              'gradient': [const Color(0xFFFFEDD5), const Color(0xFFFFF1F2)],
              'borderColor': const Color(0xFFFED7AA),
              'buttonColor': const Color(0xFFEF4444),
            },
            {
              'id': 'emoji_memory',
              'title': 'Emoji Memory',
              'desc': 'Memorize positions and find the target emoji.',
              'icon': '😃',
              'leftImage': 'assets/images/games_hub/emoji_memory_left.webp',
              'rightImage': 'assets/images/games_hub/emoji_memory_right.webp',
              'gradient': [const Color(0xFFE0F2FE), const Color(0xFFEDE9FE)],
              'borderColor': const Color(0xFFBAE6FD),
              'buttonColor': const Color(0xFF2563EB),
            },
            {
              'id': 'math_rush',
              'title': 'Math Rush',
              'desc': 'Solve math equations before time runs out.',
              'icon': '➕',
              'leftImage': 'assets/images/games_hub/math_rush_left.webp',
              'rightImage': 'assets/images/games_hub/math_rush_right.webp',
              'gradient': [const Color(0xFFDCFCE7), const Color(0xFFF0FDF4)],
              'borderColor': const Color(0xFFBBF7D0),
              'buttonColor': const Color(0xFF059669),
            },
            {
              'id': 'water_sort',
              'title': 'Colour Sort',
              'desc': 'Pour and sort colored liquids in tubes.',
              'icon': '🧪',
              'leftImage': 'assets/images/games_hub/water_left.png',
              'rightImage': 'assets/images/games_hub/water_right.png',
              'gradient': [const Color(0xFFF3E8FF), const Color(0xFFEDE9FE)],
              'borderColor': const Color(0xFFE9D5FF),
              'buttonColor': const Color(0xFF7C3AED),
            },
            {
              'id': 'bubble_shooter',
              'title': 'Bubble Sort',
              'desc': 'Aim, shoot and pop matching color bubbles.',
              'icon': '🫧',
              'leftImage': 'assets/images/games_hub/buble_left.png',
              'rightImage': 'assets/images/games_hub/buble_right.png',
              'gradient': [const Color(0xFFE0E7FF), const Color(0xFFEEF2FF)],
              'borderColor': const Color(0xFFC7D2FE),
              'buttonColor': const Color(0xFF4F46E5),
            },
            {
              'id': 'arrow_escape',
              'title': 'Arrow Escape',
              'desc': 'Tap arrows to navigate and escape the maze.',
              'icon': '🏹',
              'leftImage': 'assets/images/games_hub/arrow left.png',
              'rightImage': 'assets/images/games_hub/arrow_right.png',
              'gradient': [const Color(0xFFFFEDD5), const Color(0xFFFEF3C7)],
              'borderColor': const Color(0xFFFDE68A),
              'buttonColor': const Color(0xFFEA580C),
            },
          ];

          // Filter to only the games allowed for this tournament
          final activeGames = tournament.allowedGames.isNotEmpty
              ? allGames.where((g) => tournament.allowedGames.contains(g['id'])).toList()
              : allGames;

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
                  // 1. Concise Header (Tournament Title, Countdown, Score & Rank)
                  _buildConciseHeader(tournament),

                  const SizedBox(height: 18),

                  // Section Title
                  Row(
                    children: [
                      Text(
                        'Allowed Games',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('✨', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Text(
                        '${activeGames.length} available',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 2. Games List Cards
                  if (activeGames.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'No games assigned to this tournament yet.',
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ...activeGames.map((game) => _buildGameCard(game, tournament)),

                  const SizedBox(height: 30),
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
    );
  }

  // Concise Top Banner (Title, Countdown, Your Score, Current Rank)
  Widget _buildConciseHeader(Tournament tournament) {
    final p = tournament.userParticipation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF281366), Color(0xFF1E0E52), Color(0xFF140838)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF281366).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Tournament Title + Countdown Timer Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tournament.title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_rounded, color: Color(0xFFFFD43B), size: 13),
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

          const SizedBox(height: 10),

          // Row 2: Your Score & Current Rank (Compact Inline Pills)
          Row(
            children: [
              // Score Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR SCORE',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${p?.score ?? 0} pts',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFFD43B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Rank Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('👑', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT RANK',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            p?.rank != null ? '#${p!.rank}' : 'Rank #1',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF4ADE80),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Game Card matching the design image
  Widget _buildGameCard(Map<String, dynamic> game, Tournament tournament) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: game['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (game['borderColor'] as Color).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (game['buttonColor'] as Color).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _launchGame(context, game['id'] as String, tournament),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left 3D Pedestal Icon
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Image.asset(
                    game['leftImage'] as String,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(game['icon'] as String, style: const TextStyle(fontSize: 34)),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Middle Details (Title, Description, Click to Play button)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game['title'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        game['desc'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Pill Button: Click to Play →
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: game['buttonColor'] as Color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (game['buttonColor'] as Color).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Click to Play',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('→', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Right 3D Illustration
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Image.asset(
                    game['rightImage'] as String,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(game['icon'] as String, style: const TextStyle(fontSize: 34)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
