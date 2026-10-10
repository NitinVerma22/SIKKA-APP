import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tournament_models.dart';

class TournamentCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isLive = tournament.isLive;
    final isUpcoming = tournament.isUpcoming;
    final isCompleted = tournament.isCompleted;
    final isJoined = tournament.isJoined;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive ? const Color(0xFF6E5DE7).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFF6E5DE7).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badges & Status
                Row(
                  children: [
                    if (tournament.tag != null && tournament.tag!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6E5DE7), Color(0xFF8F00FF)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tournament.tag!.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    
                    // Status Badge
                    _buildStatusBadge(isLive, isUpcoming, isCompleted),

                    const Spacer(),

                    // Entry Type
                    _buildEntryBadge(),
                  ],
                ),

                const SizedBox(height: 12),

                // Tournament Title & Description
                Text(
                  tournament.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    height: 1.2,
                  ),
                ),
                if (tournament.description != null && tournament.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tournament.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Stats Bar (Prize Pool + Participants + Time remaining)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Prize Pool
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 16),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRIZE POOL',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '${tournament.prizePool} Coins',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Participants
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.people_alt_rounded, color: Color(0xFF4F46E5), size: 16),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PLAYERS',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '${tournament.currentParticipants}${tournament.maxParticipants != null ? "/${tournament.maxParticipants}" : ""}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom Action & User Status Row
                Row(
                  children: [
                    // Allowed Games pill summary
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.videogame_asset_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${tournament.allowedGames.length} Casual Games',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Primary Action Button
                    if (isCompleted) ...[
                      OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: Text(
                          'Results 🏆',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ] else if (isJoined) ...[
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle_fill_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Play Arena',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: onJoinTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tournament.entryType == TournamentEntryType.free
                              ? const Color(0xFF6E5DE7)
                              : const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tournament.entryType == TournamentEntryType.free) ...[
                              const Icon(Icons.ondemand_video_rounded, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Join Free',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ] else ...[
                              const Icon(Icons.monetization_on_rounded, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Join (${tournament.entryFeeCoins}c)',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isLive, bool isUpcoming, bool isCompleted) {
    if (isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'LIVE NOW',
              style: GoogleFonts.outfit(
                color: const Color(0xFFDC2626),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (isUpcoming) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD97706).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 10, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Text(
              'UPCOMING',
              style: GoogleFonts.outfit(
                color: const Color(0xFFD97706),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF64748B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'ENDED',
        style: GoogleFonts.outfit(
          color: const Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEntryBadge() {
    if (tournament.entryType == TournamentEntryType.free) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ondemand_video_rounded, color: Color(0xFF16A34A), size: 12),
            const SizedBox(width: 4),
            Text(
              'FREE (Watch Ad)',
              style: GoogleFonts.outfit(
                color: const Color(0xFF16A34A),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, color: Color(0xFFD97706), size: 12),
          const SizedBox(width: 4),
          Text(
            '${tournament.entryFeeCoins} Coins',
            style: GoogleFonts.outfit(
              color: const Color(0xFFD97706),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
