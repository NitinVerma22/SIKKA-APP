import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tournament_models.dart';
import '../providers/tournament_providers.dart';

class TournamentLeaderboardScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentLeaderboardScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentLeaderboardScreen> createState() => _TournamentLeaderboardScreenState();
}

class _TournamentLeaderboardScreenState extends ConsumerState<TournamentLeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final lbAsync = ref.watch(tournamentLeaderboardProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tournaments/${widget.tournamentId}');
            }
          },
        ),
          title: Text(
            'Leaderboard 🏆',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6E5DE7)),
              onPressed: () {
                ref.invalidate(tournamentLeaderboardProvider(widget.tournamentId));
              },
            ),
          ],
        ),
        body: lbAsync.when(
          data: (data) {
            if (data == null) {
              return Center(
                child: Text(
                  'No leaderboard data available.',
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                ),
              );
            }

            final leaderboard = data.leaderboard;
            final top1 = leaderboard.isNotEmpty ? leaderboard[0] : null;
            final top2 = leaderboard.length > 1 ? leaderboard[1] : null;
            final top3 = leaderboard.length > 2 ? leaderboard[2] : null;
            final remainingList = leaderboard.length > 3 ? leaderboard.sublist(3) : <LeaderboardEntry>[];

            return Stack(
              children: [
                RefreshIndicator(
                  color: const Color(0xFF6E5DE7),
                  onRefresh: () async {
                    ref.invalidate(tournamentLeaderboardProvider(widget.tournamentId));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Live Status banner
                        _buildStatusHeader(data),
                        const SizedBox(height: 20),

                        // Top 3 Podium
                        if (leaderboard.isNotEmpty) ...[
                          _buildPodium(top1, top2, top3),
                          const SizedBox(height: 24),
                        ] else ...[
                          _buildEmptyPodium(),
                          const SizedBox(height: 24),
                        ],

                        // Ranks 4+ List
                        if (remainingList.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rankings',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: remainingList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final entry = remainingList[idx];
                              return _buildLeaderboardTile(entry);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Pinned User Rank Bar at bottom
                if (data.userRank != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildPinnedUserBar(data.userRank!),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6E5DE7)),
          ),
          error: (err, _) => Center(
            child: Text('Error: $err', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ),
      );
  }

  Widget _buildStatusHeader(TournamentLeaderboardData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: data.isLive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                data.isLive ? 'LIVE SCORES' : 'FINAL RESULTS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: data.isLive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                '${data.totalParticipants} Participants',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(LeaderboardEntry? top1, LeaderboardEntry? top2, LeaderboardEntry? top3) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rank 2 (Silver)
          if (top2 != null)
            _buildPodiumColumn(
              entry: top2,
              rank: 2,
              height: 120,
              badgeColor: const Color(0xFF94A3B8),
              avatarBorder: const Color(0xFFCBD5E1),
            )
          else
            const SizedBox(width: 80),

          // Rank 1 (Gold)
          if (top1 != null)
            _buildPodiumColumn(
              entry: top1,
              rank: 1,
              height: 155,
              badgeColor: const Color(0xFFF59E0B),
              avatarBorder: const Color(0xFFFCD34D),
              isFirst: true,
            )
          else
            const SizedBox(width: 80),

          // Rank 3 (Bronze)
          if (top3 != null)
            _buildPodiumColumn(
              entry: top3,
              rank: 3,
              height: 100,
              badgeColor: const Color(0xFFD97706),
              avatarBorder: const Color(0xFFFDBA74),
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required LeaderboardEntry entry,
    required int rank,
    required double height,
    required Color badgeColor,
    required Color avatarBorder,
    bool isFirst = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst)
          const Text('👑', style: TextStyle(fontSize: 24)),

        // Avatar
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: isFirst ? 64 : 52,
              height: isFirst ? 64 : 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: avatarBorder, width: isFirst ? 3 : 2),
                color: Colors.white,
              ),
              child: ClipOval(
                child: entry.userAvatar != null && entry.userAvatar!.isNotEmpty
                    ? Image.network(entry.userAvatar!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(entry.userName))
                    : _avatarFallback(entry.userName),
              ),
            ),
            Positioned(
              bottom: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: badgeColor.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Text(
                  '#$rank',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // User Name
        SizedBox(
          width: 85,
          child: Text(
            entry.userName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
          ),
        ),

        // Points
        Text(
          '${entry.score} pts',
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6E5DE7)),
        ),

        // Prize
        if (entry.prize > 0)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${entry.prize}c',
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFFD97706)),
            ),
          ),
      ],
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Container(
      color: const Color(0xFF6E5DE7),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
      ),
    );
  }

  Widget _buildEmptyPodium() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.military_tech_rounded, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 8),
          Text(
            'Leaderboard is Open!',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            'Play casual games to score points and take the #1 spot!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: entry.userAvatar != null && entry.userAvatar!.isNotEmpty
                  ? Image.network(entry.userAvatar!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(entry.userName))
                  : _avatarFallback(entry.userName),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              entry.userName,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score} pts',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF6E5DE7),
                ),
              ),
              if (entry.prize > 0)
                Text(
                  '+${entry.prize} Coins',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedUserBar(LeaderboardEntry userRank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6E5DE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${userRank.rank}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your Current Rank',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    userRank.userName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${userRank.score} pts',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFFD43B),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (userRank.prize > 0)
                  Text(
                    'Prize: +${userRank.prize} Coins',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
