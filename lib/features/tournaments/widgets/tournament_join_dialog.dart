import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/providers/wallet_provider.dart';
import '../models/tournament_models.dart';
import '../providers/tournament_providers.dart';

class TournamentJoinDialog {
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required Tournament tournament,
    required VoidCallback onJoinSuccess,
  }) async {
    if (tournament.entryType == TournamentEntryType.free) {
      _showFreeRewardedDialog(context, ref, tournament, onJoinSuccess);
    } else {
      _showPaidConfirmationDialog(context, ref, tournament, onJoinSuccess);
    }
  }

  static void _showFreeRewardedDialog(
    BuildContext context,
    WidgetRef ref,
    Tournament tournament,
    VoidCallback onJoinSuccess,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.ondemand_video_rounded, color: Color(0xFF6E5DE7), size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                'Join Tournament Free',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Watch a quick rewarded video to get FREE entry into "${tournament.title}" and compete for the ${tournament.prizePool} Coins prize pool!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '100% Free • Safe & Fair Play Arena',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogCtx).pop();
                      _playRewardedAdAndJoin(context, ref, tournament, onJoinSuccess);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E5DE7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 18),
                        const SizedBox(width: 4),
                        Text('Watch & Join', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void _playRewardedAdAndJoin(
    BuildContext context,
    WidgetRef ref,
    Tournament tournament,
    VoidCallback onJoinSuccess,
  ) {
    bool rewardEarned = false;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loading video ad for free entry...'),
        duration: Duration(seconds: 2),
      ),
    );

    AdService.instance.showRewardedAd(
      context: context,
      userId: 'tournament_join_${tournament.id}',
      onUserEarnedReward: (reward) {
        rewardEarned = true;
      },
      onAdDismissed: () async {
        if (!context.mounted) return;

        if (rewardEarned || !AdService.instance.isRewardedAdLoaded()) {
          // Join the tournament via backend
          final result = await ref.read(tournamentServiceProvider).joinTournament(tournament.id);
          if (!context.mounted) return;

          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            onJoinSuccess();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad was closed early. Please watch full video to join.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      },
    );
  }

  static void _showPaidConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    Tournament tournament,
    VoidCallback onJoinSuccess,
  ) {
    final userCoins = ref.read(walletProvider);
    final hasEnoughCoins = userCoins >= tournament.entryFeeCoins;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFD97706), size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirm Entry Fee',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Joining "${tournament.title}" requires an entry fee of:',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '${tournament.entryFeeCoins} Coins',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Balance:',
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    '$userCoins Coins',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: hasEnoughCoins ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              if (!hasEnoughCoins) ...[
                const SizedBox(height: 10),
                Text(
                  'You don\'t have enough coins. Earn coins by playing casual games or daily tasks!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasEnoughCoins
                        ? () async {
                            Navigator.of(dialogCtx).pop();
                            final result = await ref
                                .read(tournamentServiceProvider)
                                .joinTournament(tournament.id);

                            if (!context.mounted) return;

                            if (result.success) {
                              ref
                                  .read(syncCoordinatorProvider)
                                  .triggerSync([SyncEvent.balanceChanged]);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                              onJoinSuccess();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Confirm & Join', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
