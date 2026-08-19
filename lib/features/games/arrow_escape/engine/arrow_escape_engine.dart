import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_escape_models.dart';

class ArrowEscapeEngine {
  static final List<Color> arrowColors = [
    const Color(0xFF76ED12), // Neon Lime
    const Color(0xFF00E5FF), // Electric Cyan
    const Color(0xFFE040FB), // Neon Purple
    const Color(0xFFFF9100), // Bright Orange
    const Color(0xFFFFEA00), // Vibrant Yellow
    const Color(0xFFFF1744), // Crimson Red
    const Color(0xFF00E676), // Spring Green
  ];

  /// Check if a specific arrow can escape freely without colliding with other remaining arrows
  static bool canArrowEscape(ArrowSnakeModel target, List<ArrowSnakeModel> allArrows, int gridSize) {
    final head = target.head;
    final dir = target.escapeDirection;

    // Collect all occupied points by OTHER active non-escaping arrows
    final occupied = <Point2D>{};
    for (final arrow in allArrows) {
      if (arrow.id == target.id || arrow.isEscaping) continue;
      occupied.addAll(arrow.pathPoints);
    }

    // Raycast from head + 1 in escapeDirection to outer boundary
    int currX = head.x;
    int currY = head.y;

    int dx = 0;
    int dy = 0;

    switch (dir) {
      case ArrowDirection.up:
        dy = -1;
        break;
      case ArrowDirection.down:
        dy = 1;
        break;
      case ArrowDirection.left:
        dx = -1;
        break;
      case ArrowDirection.right:
        dx = 1;
        break;
    }

    currX += dx;
    currY += dy;

    while (currX >= 0 && currX < gridSize && currY >= 0 && currY < gridSize) {
      if (occupied.contains(Point2D(currX, currY))) {
        return false; // Collision detected!
      }
      currX += dx;
      currY += dy;
    }

    return true; // Path is completely clear to boundary!
  }

  /// Finds any arrow that is currently solvable/escapable to give a Hint
  static ArrowSnakeModel? findSolvableArrow(List<ArrowSnakeModel> arrows, int gridSize) {
    for (final arrow in arrows) {
      if (!arrow.isEscaping && canArrowEscape(arrow, arrows, gridSize)) {
        return arrow;
      }
    }
    return null;
  }

  /// Generate a guaranteed solvable level for a given level number
  static ArrowLevelModel generateLevel(int levelNumber) {
    final random = Random(levelNumber * 1000 + 42);

    int gridSize = 5;
    int arrowCount = 4 + (levelNumber ~/ 10);
    if (arrowCount > 14) arrowCount = 14;

    if (levelNumber > 15) gridSize = 6;
    if (levelNumber > 40) gridSize = 7;
    if (levelNumber > 80) gridSize = 8;

    final arrows = <ArrowSnakeModel>[];
    final occupied = <Point2D>{};

    int attempts = 0;

    while (arrows.length < arrowCount && attempts < 400) {
      attempts++;

      // Pick a random head position
      int hX = random.nextInt(gridSize);
      int hY = random.nextInt(gridSize);
      final head = Point2D(hX, hY);

      if (occupied.contains(head)) continue;

      // Choose escape direction pointing outward or free
      final dirs = [
        ArrowDirection.up,
        ArrowDirection.down,
        ArrowDirection.left,
        ArrowDirection.right,
      ]..shuffle(random);

      ArrowDirection? chosenDir;
      for (final d in dirs) {
        // Ensure path to boundary in direction `d` is clear
        int cX = hX;
        int cY = hY;
        int dx = (d == ArrowDirection.right) ? 1 : (d == ArrowDirection.left ? -1 : 0);
        int dy = (d == ArrowDirection.down) ? 1 : (d == ArrowDirection.up ? -1 : 0);
        
        bool clear = true;
        cX += dx;
        cY += dy;
        while (cX >= 0 && cX < gridSize && cY >= 0 && cY < gridSize) {
          if (occupied.contains(Point2D(cX, cY))) {
            clear = false;
            break;
          }
          cX += dx;
          cY += dy;
        }

        if (clear) {
          chosenDir = d;
          break;
        }
      }

      if (chosenDir == null) continue;

      // Build winding body backwards from head (opposite of escape direction)
      final pathPoints = <Point2D>[head];
      occupied.add(head);

      int length = 2 + random.nextInt(3); // length 2 to 4 segments
      Point2D curr = head;

      // Backwards direction for neck
      int bDx = (chosenDir == ArrowDirection.right) ? -1 : (chosenDir == ArrowDirection.left ? 1 : 0);
      int bDy = (chosenDir == ArrowDirection.down) ? -1 : (chosenDir == ArrowDirection.up ? 1 : 0);

      Point2D neck = Point2D(curr.x + bDx, curr.y + bDy);
      if (neck.x >= 0 && neck.x < gridSize && neck.y >= 0 && neck.y < gridSize && !occupied.contains(neck)) {
        pathPoints.add(neck);
        occupied.add(neck);
        curr = neck;

        // Optionally add turns
        for (int i = 2; i < length; i++) {
          final nextNeighbors = [
            Point2D(curr.x + 1, curr.y),
            Point2D(curr.x - 1, curr.y),
            Point2D(curr.x, curr.y + 1),
            Point2D(curr.x, curr.y - 1),
          ]..shuffle(random);

          Point2D? validNext;
          for (final n in nextNeighbors) {
            if (n.x >= 0 && n.x < gridSize && n.y >= 0 && n.y < gridSize && !occupied.contains(n)) {
              validNext = n;
              break;
            }
          }

          if (validNext != null) {
            pathPoints.add(validNext);
            occupied.add(validNext);
            curr = validNext;
          } else {
            break;
          }
        }
      } else {
        occupied.remove(head);
        continue;
      }

      final color = arrowColors[arrows.length % arrowColors.length];
      arrows.add(ArrowSnakeModel(
        id: 'arrow_${levelNumber}_${arrows.length}',
        pathPoints: pathPoints,
        color: color,
      ));
    }

    return ArrowLevelModel(
      levelNumber: levelNumber,
      gridSize: gridSize,
      arrows: arrows,
      maxTimeSeconds: levelNumber > 100 ? 45 : 0,
    );
  }
}
