import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_escape_models.dart';

class ParticleModel {
  Offset position;
  Offset velocity;
  Color color;
  double alpha;
  double radius;

  ParticleModel({
    required this.position,
    required this.velocity,
    required this.color,
    this.alpha = 1.0,
    required this.radius,
  });
}

class ArrowEscapePainter extends CustomPainter {
  final ArrowLevelModel level;
  final List<ArrowSnakeModel> arrows;
  final String? highlightedArrowId;
  final List<ParticleModel> particles;

  ArrowEscapePainter({
    required this.level,
    required this.arrows,
    this.highlightedArrowId,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridSize = level.gridSize;
    final cellSize = size.width / gridSize;

    // 1. Draw Dot Matrix Grid & Border
    _drawGridBackground(canvas, size, gridSize, cellSize);

    // 2. Draw Winding Arrows
    for (final arrow in arrows) {
      if (arrow.pathPoints.isEmpty) continue;

      canvas.save();

      // Apply shake offset if blocked
      if (arrow.isBlockedShaking) {
        final shakeDx = sin(arrow.shakeProgress * pi * 4) * (cellSize * 0.15);
        canvas.translate(shakeDx, 0);
      }

      final isHinted = arrow.id == highlightedArrowId;
      _drawSingleArrow(canvas, arrow, cellSize, gridSize, size, isHinted);

      canvas.restore();
    }

    // 3. Draw Particle Burst Effects
    _drawParticles(canvas);
  }

  void _drawGridBackground(Canvas canvas, Size size, int gridSize, double cellSize) {
    final bgPaint = Paint()..color = const Color(0xFF14161C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20)),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF2E323D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20)),
      borderPaint,
    );

    // Dot matrix grid
    final dotPaint = Paint()..color = const Color(0xFF282C38);
    for (int r = 0; r <= gridSize; r++) {
      for (int c = 0; c <= gridSize; c++) {
        canvas.drawCircle(Offset(c * cellSize, r * cellSize), 1.8, dotPaint);
      }
    }
  }

  void _drawSingleArrow(
    Canvas canvas,
    ArrowSnakeModel arrow,
    double cellSize,
    int gridSize,
    Size size,
    bool isHinted,
  ) {
    final pathPts = arrow.pathPoints;
    if (pathPts.isEmpty) return;

    List<Offset> pxPoints;

    if (arrow.isEscaping) {
      // Build continuous polyline track slicing along exact path & exit extension
      pxPoints = _buildSlidingPolylineTrack(arrow, cellSize, gridSize);
    } else {
      pxPoints = pathPts.map((pt) {
        return Offset((pt.x + 0.5) * cellSize, (pt.y + 0.5) * cellSize);
      }).toList();
    }

    if (pxPoints.isEmpty) return;

    final mainColor = isHinted ? const Color(0xFFFFEA00) : arrow.color;
    final sw = cellSize * 0.14;

    final bodyPath = Path()..moveTo(pxPoints.first.dx, pxPoints.first.dy);
    for (int i = 1; i < pxPoints.length; i++) {
      bodyPath.lineTo(pxPoints[i].dx, pxPoints[i].dy);
    }

    // 1. Radial Glow
    if (isHinted) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFEA00).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawPath(bodyPath, glowPaint);
    } else {
      final glowPaint = Paint()
        ..color = mainColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(bodyPath, glowPaint);
    }

    // 2. Motion Trail when escaping
    if (arrow.isEscaping) {
      final trailPaint = Paint()
        ..color = mainColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(bodyPath, trailPaint);
    }

    // 3. Arrow Body Polyline
    final bodyPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, bodyPaint);

    // 4. Caret Arrow Head at Head Point (pxPoints.first)
    _drawCaretHead(canvas, pxPoints, arrow.escapeDirection, mainColor, cellSize, sw);
  }

  /// Construct continuous segment-by-segment polyline track slicing along exact path turns
  List<Offset> _buildSlidingPolylineTrack(ArrowSnakeModel arrow, double cellSize, int gridSize) {
    final dir = arrow.escapeDirection;

    // Convert pathPoints (head at 0, tail at end) to pixel coordinates
    final basePts = arrow.pathPoints.map((pt) {
      return Offset((pt.x + 0.5) * cellSize, (pt.y + 0.5) * cellSize);
    }).toList();

    // Create exit extension points extending straight from head (basePts[0]) out past board boundary
    final extCount = gridSize + 5;
    final headPx = basePts.first;

    final track = <Offset>[];
    for (int i = extCount; i >= 1; i--) {
      track.add(headPx + Offset(dir.dx * i * cellSize, dir.dy * i * cellSize));
    }
    track.addAll(basePts); // track: [Ext_M, ..., Ext_1, Head(P0), P1, P2, ..., Tail(Pk)]

    // Compute cumulative arc-length distances along track from Tail (track.last) to Ext_M (track.first)
    final dist = <double>[0.0];
    final revTrack = track.reversed.toList(); // revTrack[0] is Tail, revTrack.last is Ext_M
    for (int i = 1; i < revTrack.length; i++) {
      dist.add(dist[i - 1] + (revTrack[i] - revTrack[i - 1]).distance);
    }

    // Body length is distance from Tail (revTrack[0]) to Head (revTrack[basePts.length - 1])
    final bodyLen = dist[basePts.length - 1];
    final totalTrackDist = dist.last;

    // As escapeProgress t goes 0 -> 1:
    // head moves from bodyLen to totalTrackDist
    // tail moves from 0 to (totalTrackDist - bodyLen)
    final progress = arrow.escapeProgress.clamp(0.0, 1.0);
    final maxTravel = totalTrackDist - bodyLen;
    final currentTailDist = progress * maxTravel;
    final currentHeadDist = currentTailDist + bodyLen;

    // Sample polyline between currentTailDist and currentHeadDist
    return _sliceTrackByDistance(revTrack, dist, currentTailDist, currentHeadDist);
  }

  /// Slice polyline track between distanceStart (tail) and distanceEnd (head)
  List<Offset> _sliceTrackByDistance(
    List<Offset> track,
    List<double> dist,
    double startDist,
    double endDist,
  ) {
    if (track.isEmpty || startDist >= endDist) return [];

    // Find tail position (startDist)
    final tailPt = _getPointAtDistance(track, dist, startDist);
    // Find head position (endDist)
    final headPt = _getPointAtDistance(track, dist, endDist);

    final sliced = <Offset>[headPt];

    // Add all intermediate track vertices between startDist and endDist (in reverse order from head to tail)
    for (int i = track.length - 1; i >= 0; i--) {
      if (dist[i] > startDist && dist[i] < endDist) {
        sliced.add(track[i]);
      }
    }

    sliced.add(tailPt);
    return sliced;
  }

  Offset _getPointAtDistance(List<Offset> track, List<double> dist, double targetDist) {
    if (targetDist <= 0) return track.first;
    if (targetDist >= dist.last) return track.last;

    for (int i = 0; i < dist.length - 1; i++) {
      if (targetDist >= dist[i] && targetDist <= dist[i + 1]) {
        final segLen = dist[i + 1] - dist[i];
        if (segLen <= 0.001) return track[i];
        final t = (targetDist - dist[i]) / segLen;
        return Offset.lerp(track[i], track[i + 1], t)!;
      }
    }
    return track.last;
  }

  void _drawCaretHead(
    Canvas canvas,
    List<Offset> pxPoints,
    ArrowDirection dir,
    Color mainColor,
    double cellSize,
    double sw,
  ) {
    final head = pxPoints.first;
    final prev = pxPoints.length > 1 ? pxPoints[1] : head;
    final dv = head - prev;
    final len = dv.distance;

    final dx = len > 0.01 ? dv.dx / len : dir.dx.toDouble();
    final dy = len > 0.01 ? dv.dy / len : dir.dy.toDouble();

    final tip = head + Offset(dx * cellSize * 0.3, dy * cellSize * 0.3);
    final hd = cellSize * 0.26;
    final hw = cellSize * 0.18;

    final base = tip - Offset(dx * hd, dy * hd);
    final px = -dy;
    final py = dx;

    final caretPath = Path()
      ..moveTo(base.dx + px * hw, base.dy + py * hw)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(base.dx - px * hw, base.dy - py * hw);

    final caretPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(caretPath, caretPaint);
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.radius, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ArrowEscapePainter oldDelegate) => true;
}
