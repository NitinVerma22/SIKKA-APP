import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sikkaplay/features/tournaments/models/tournament_models.dart';

/// Clean, responsive Prize Distribution Table UI matching the modern design
/// with 3D gift icon, soft lavender table header, medal laurel badges for Top 3,
/// and coin stack icons with formatted reward amounts.
class PrizeDistributionTable extends StatelessWidget {
  final Tournament tournament;

  const PrizeDistributionTable({
    super.key,
    required this.tournament,
  });

  String _formatNumber(num value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      // 1,000 comma separated format
      final str = value.toInt().toString();
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final tiers = (tournament.prizeStructure.isNotEmpty)
        ? tournament.prizeStructure
        : [
            PrizeTier(rankMin: 1, rankMax: 1, prize: (tournament.prizePool * 0.35).round(), prizeRupees: 0),
            PrizeTier(rankMin: 2, rankMax: 2, prize: (tournament.prizePool * 0.20).round(), prizeRupees: 0),
            PrizeTier(rankMin: 3, rankMax: 3, prize: (tournament.prizePool * 0.10).round(), prizeRupees: 0),
            PrizeTier(rankMin: 4, rankMax: 10, prize: (tournament.prizePool * 0.03).round(), prizeRupees: 0),
            PrizeTier(rankMin: 11, rankMax: 50, prize: (tournament.prizePool * 0.0035).round(), prizeRupees: 0),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (3D Gift Container + Title + Subtitle)
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/games_hub/banner_gift.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('🎁', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prize Distribution',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rank higher and win exciting coin rewards!',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Clean Table Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9EDF5), width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Table Header
                Container(
                  color: const Color(0xFFEEEDFB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: Text(
                          'Rank',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1B4B),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 18,
                        color: const Color(0xFFD8D5F5),
                      ),
                      Expanded(
                        flex: 10,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            'Reward (Coins)',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E1B4B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: tiers.length,
                  separatorBuilder: (_, __) => Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final tier = tiers[index];
                    final isTop1 = tier.rankMin == 1 && tier.rankMax == 1;
                    final isTop2 = tier.rankMin == 2 && tier.rankMax == 2;
                    final isTop3 = tier.rankMin == 3 && tier.rankMax == 3;
                    final isTop3Rank = isTop1 || isTop2 || isTop3;
                    final rankNum = isTop1 ? 1 : (isTop2 ? 2 : 3);

                    final String rankText = isTop1
                        ? 'Rank #1'
                        : (isTop2
                            ? 'Rank #2'
                            : (isTop3
                                ? 'Rank #3'
                                : (tier.rankMin == tier.rankMax
                                    ? 'Rank #${tier.rankMin}'
                                    : '#${tier.rankMin} – #${tier.rankMax}')));

                    final cashRupees = tier.getCalculatedRupees(tournament.prizePool, tournament.prizePoolRupees);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Left Column: Rank
                          Expanded(
                            flex: 11,
                            child: Row(
                              children: [
                                if (isTop3Rank) ...[
                                  LaurelMedalWidget(rank: rankNum),
                                  const SizedBox(width: 10),
                                  Text(
                                    rankText,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ] else ...[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      rankText,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Vertical divider
                          Container(
                            width: 1,
                            height: 28,
                            color: const Color(0xFFF1F5F9),
                          ),

                          // Right Column: Reward (Coins)
                          Expanded(
                            flex: 10,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/games_hub/coins_stack.png',
                                    width: 26,
                                    height: 26,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.monetization_on_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          _formatNumber(tier.prize),
                                          style: GoogleFonts.outfit(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (cashRupees > 0) ...[
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '+₹$cashRupees',
                                              style: GoogleFonts.outfit(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF15803D),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Laurel wreath medal badge for Rank 1 (Gold), Rank 2 (Silver), Rank 3 (Bronze)
class LaurelMedalWidget extends StatelessWidget {
  final int rank;
  const LaurelMedalWidget({super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 32),
      painter: _LaurelMedalPainter(rank: rank),
    );
  }
}

class _LaurelMedalPainter extends CustomPainter {
  final int rank;
  _LaurelMedalPainter({required this.rank});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    Color stemColor;
    Color leafColor;
    Color discOuter;
    Color discInner;

    switch (rank) {
      case 1:
        stemColor = const Color(0xFFF59E0B);
        leafColor = const Color(0xFFFBBF24);
        discOuter = const Color(0xFFD97706);
        discInner = const Color(0xFFF59E0B);
        break;
      case 2:
        stemColor = const Color(0xFF94A3B8);
        leafColor = const Color(0xFFCBD5E1);
        discOuter = const Color(0xFF64748B);
        discInner = const Color(0xFF94A3B8);
        break;
      case 3:
      default:
        stemColor = const Color(0xFFEA580C);
        leafColor = const Color(0xFFFDBA74);
        discOuter = const Color(0xFFC2410C);
        discInner = const Color(0xFFEA580C);
        break;
    }

    final stemPaint = Paint()
      ..color = stemColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.fill;

    // Draw Left Laurel Arc
    final leftArcPath = Path()
      ..moveTo(cx - 10, cy + 9)
      ..cubicTo(cx - 14, cy + 5, cx - 14, cy - 6, cx - 9, cy - 9);
    canvas.drawPath(leftArcPath, stemPaint);

    // Left leaves (curving outward)
    _drawLeaf(canvas, cx - 12, cy + 6, -0.6, leafPaint);
    _drawLeaf(canvas, cx - 14, cy, -0.2, leafPaint);
    _drawLeaf(canvas, cx - 13, cy - 6, 0.3, leafPaint);
    _drawLeaf(canvas, cx - 9, cy - 10, 0.7, leafPaint);

    // Draw Right Laurel Arc
    final rightArcPath = Path()
      ..moveTo(cx + 10, cy + 9)
      ..cubicTo(cx + 15, cy + 5, cx + 15, cy - 6, cx + 9, cy - 9);
    canvas.drawPath(rightArcPath, stemPaint);

    // Right leaves (symmetric)
    _drawLeaf(canvas, cx + 12, cy + 6, 0.6, leafPaint);
    _drawLeaf(canvas, cx + 14, cy, 0.2, leafPaint);
    _drawLeaf(canvas, cx + 13, cy - 6, -0.3, leafPaint);
    _drawLeaf(canvas, cx + 9, cy - 10, -0.7, leafPaint);

    // Center disc (outer rim)
    const discRadius = 10.0;
    final discPaint = Paint()
      ..color = discOuter
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), discRadius, discPaint);

    // Center disc (inner gradient)
    final innerDiscPaint = Paint()
      ..shader = LinearGradient(
        colors: [discInner, leafColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: discRadius - 1.2));
    canvas.drawCircle(Offset(cx, cy), discRadius - 1.2, innerDiscPaint);

    // Draw Rank Number Text
    final textSpan = TextSpan(
      text: '$rank',
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        shadows: [
          Shadow(
            color: discOuter.withValues(alpha: 0.6),
            offset: const Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - (textPainter.width / 2), cy - (textPainter.height / 2)),
    );
  }

  void _drawLeaf(Canvas canvas, double x, double y, double angle, Paint paint) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    final leafPath = Path()
      ..moveTo(0, -4)
      ..cubicTo(2.2, -1.8, 2.2, 1.8, 0, 4)
      ..cubicTo(-2.2, 1.8, -2.2, -1.8, 0, -4)
      ..close();
    canvas.drawPath(leafPath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LaurelMedalPainter oldDelegate) => oldDelegate.rank != rank;
}
