import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/ads/ad_service.dart';
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
  String _formatNumber(num value) {
    if (value >= 1000) {
      final str = value.toInt().toString();
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    }
    return value.toInt().toString();
  }
  bool _isExiting = false;

  void _openUserProfile(LeaderboardEntry entry) {
    final target = (entry.username != null && entry.username!.trim().isNotEmpty)
        ? entry.username!.trim()
        : (entry.userId.trim().isNotEmpty ? entry.userId.trim() : entry.userName.trim());

    if (target.isEmpty) return;

    context.push('/playground/profile', extra: target);
  }

  @override
  void initState() {
    super.initState();
    // Pre-cache interstitial ad to be ready on screen exit
    AdService.instance.loadInterstitialAd();
  }

  void _handleExit() {
    if (_isExiting) return;
    _isExiting = true;

    void performPop() {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/tournaments/${widget.tournamentId}');
      }
    }

    // Show Interstitial Ad on exit
    AdService.instance.showInterstitialAd(
      onAdDismissed: performPop,
      allowFastDismiss: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lbAsync = ref.watch(tournamentLeaderboardProvider(widget.tournamentId));
    final detailAsync = ref.watch(tournamentDetailProvider(widget.tournamentId));
    final detailTournament = detailAsync.valueOrNull;

    final isJoined = (detailTournament?.isJoined == true) ||
        ref.watch(joinedTournamentIdsProvider).any((id) => id.trim().toLowerCase() == widget.tournamentId.trim().toLowerCase());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
            onPressed: _handleExit,
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
              ref.invalidate(tournamentDetailProvider(widget.tournamentId));
            },
          ),
        ],
      ),
      body: lbAsync.when(
        skipLoadingOnReload: true,
        data: (lbData) {
          final data = lbData ?? (detailTournament != null
              ? TournamentLeaderboardData(
                  tournamentId: detailTournament.id,
                  title: detailTournament.title,
                  prizePool: detailTournament.prizePool,
                  status: detailTournament.status,
                  endTime: detailTournament.endTime,
                  allowedGames: detailTournament.allowedGames,
                  leaderboard: const [],
                  userRank: detailTournament.userParticipation != null
                      ? LeaderboardEntry(
                          rank: detailTournament.userParticipation!.rank ?? 1,
                          userId: detailTournament.userParticipation!.id,
                          userName: 'You',
                          score: detailTournament.userParticipation!.score,
                          prize: 0,
                        )
                      : null,
                  totalParticipants: detailTournament.currentParticipants,
                  isLive: detailTournament.isLive,
                )
              : null);

          if (data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 54, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 12),
                  Text(
                    'No leaderboard data available',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(tournamentLeaderboardProvider(widget.tournamentId));
                      ref.invalidate(tournamentDetailProvider(widget.tournamentId));
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E5DE7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
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
                  ref.invalidate(tournamentDetailProvider(widget.tournamentId));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Live Status & Tournament Header banner
                      _buildStatusHeader(data, detailTournament),
                      const SizedBox(height: 18),

                      // Top 3 Podium
                      if (leaderboard.isNotEmpty) ...[
                        _buildPodium(top1, top2, top3),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildEmptyPodium(isJoined),
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
              if (data.userRank != null || isJoined)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildPinnedUserBar(
                    userRank: data.userRank,
                    isJoined: isJoined,
                    tournament: detailTournament,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6E5DE7)),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 10),
              Text(
                'Failed to load leaderboard',
                style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(tournamentLeaderboardProvider(widget.tournamentId));
                  ref.invalidate(tournamentDetailProvider(widget.tournamentId));
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E5DE7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStatusHeader(TournamentLeaderboardData data, Tournament? detailTournament) {
    final title = data.title.isNotEmpty && data.title != 'Tournament Leaderboard'
        ? data.title
        : (detailTournament?.title ?? 'Tournament Arena');
    final prize = data.prizePool > 0 ? data.prizePool : (detailTournament?.prizePool ?? 0);
    final participantsCount = data.totalParticipants > 0
        ? data.totalParticipants
        : (detailTournament?.currentParticipants ?? 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: data.isLive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data.isLive ? 'LIVE SCORES 🔴' : 'FINAL RESULTS 🏁',
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
                    '$participantsCount Participants',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (prize > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        '$prize Coins',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if ((detailTournament?.minPointsToWin ?? 1000) > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA), width: 1),
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Score min. ${_formatNumber(detailTournament?.minPointsToWin ?? 1000)} points to qualify for prizes (even if Rank #1).',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFDC2626), // Eye-catching Red
                      ),
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

        // Avatar (Clickable to open user's public profile)
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => _openUserProfile(entry),
              child: _buildUserAvatar(
                entry,
                size: isFirst ? 64 : 52,
                borderColor: avatarBorder,
                borderWidth: isFirst ? 3 : 2,
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

        // User Name (Clickable to open user's public profile)
        GestureDetector(
          onTap: () => _openUserProfile(entry),
          child: SizedBox(
            width: 85,
            child: Text(
              entry.userName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
            ),
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
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/games_hub/coins_stack.png',
                  width: 15,
                  height: 15,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('🪙', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 4),
                Text(
                  '+${entry.prize}',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFB45309),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUserAvatar(LeaderboardEntry entry, {required double size, Color? borderColor, double borderWidth = 0}) {
    final avatar = entry.userAvatar;
    Widget imageWidget;

    if (avatar != null && avatar.isNotEmpty) {
      if (avatar.startsWith('assets/')) {
        imageWidget = Image.asset(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(entry.userName, size: size),
        );
      } else if (avatar.startsWith('data:image')) {
        try {
          final base64Str = avatar.split(',').last;
          imageWidget = Image.memory(
            base64Decode(base64Str),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _avatarFallback(entry.userName, size: size),
          );
        } catch (_) {
          imageWidget = _avatarFallback(entry.userName, size: size);
        }
      } else {
        imageWidget = Image.network(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(entry.userName, size: size),
        );
      }
    } else {
      imageWidget = _avatarFallback(entry.userName, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: ClipOval(child: imageWidget),
    );
  }

  Widget _avatarFallback(String name, {double size = 36}) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF6E5DE7),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }

  Widget _buildEmptyPodium(bool isJoined) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 48, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 14),
          Text(
            'Leaderboard is Open!',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            'No scores have been posted yet. Play casual games now to claim Rank #1 👑',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              if (isJoined) {
                context.push('/tournaments/${widget.tournamentId}/games');
              } else {
                context.push('/tournaments/${widget.tournamentId}');
              }
            },
            icon: Icon(isJoined ? Icons.play_arrow_rounded : Icons.flash_on_rounded, size: 20),
            label: Text(
              isJoined ? 'Play Casual Games Now 🎮' : 'Join Tournament ⚔️',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E5DE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openUserProfile(entry),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

                // Avatar (Tap to open public profile)
                _buildUserAvatar(
                  entry,
                  size: 38,
                  borderColor: const Color(0xFFE2E8F0),
                  borderWidth: 1.5,
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
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedUserBar({
    LeaderboardEntry? userRank,
    required bool isJoined,
    Tournament? tournament,
  }) {
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
                userRank != null ? '#${userRank.rank}' : '# -',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: userRank != null ? () => _openUserProfile(userRank) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userRank != null ? 'Your Current Rank (Tap for profile)' : 'Your Tournament Status',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      userRank?.userName ?? (isJoined ? 'Enrolled (Score: 0 pts)' : 'Not Joined Yet'),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (userRank != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_formatNumber(userRank.score)} pts',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFFD43B),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (userRank.prize > 0)
                    Text(
                      'Prize: +${_formatNumber(userRank.prize)} Coins',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else if (userRank.score < (tournament?.minPointsToWin ?? 1000))
                    Text(
                      'Need ${_formatNumber((tournament?.minPointsToWin ?? 1000) - userRank.score)} more pts',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFF87171),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              )
            else if (isJoined)
              ElevatedButton(
                onPressed: () {
                  if (tournament != null && !tournament.hasStarted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '⏰ Tournament starts soon! Game arena unlocks at start time.',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: const Color(0xFF5B1FE6),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  context.push('/tournaments/${widget.tournamentId}/games');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (tournament != null && !tournament.hasStarted)
                      ? const Color(0xFF5B1FE6)
                      : const Color(0xFF00C06D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  (tournament != null && !tournament.hasStarted)
                      ? 'Starts Soon ⏰'
                      : 'Play Now 🎮',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
