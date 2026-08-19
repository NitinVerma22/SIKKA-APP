import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_escape_models.dart';

class ArrowEscapeEngine {
  static const List<Color> themePalette = [
    Color(0xFF76ED12), // Neon Lime
    Color(0xFF00E5FF), // Electric Cyan
    Color(0xFFE040FB), // Neon Purple
    Color(0xFFFF9100), // Bright Orange
    Color(0xFFFFEA00), // Vibrant Yellow
    Color(0xFFFF1744), // Crimson Red
    Color(0xFF00E676), // Spring Green
    Color(0xFF2979FF), // Royal Blue
  ];

  /// Check if a target arrow can escape to the grid boundary without colliding with other arrows
  static bool canArrowEscape(ArrowSnakeModel target, List<ArrowSnakeModel> allArrows, int gridSize) {
    final head = target.head;
    final dir = target.escapeDirection;

    // Collect all occupied cells by other active (non-escaping) arrows
    final occupied = <Point2D>{};
    for (final arrow in allArrows) {
      if (arrow.id == target.id || arrow.isEscaping) continue;
      occupied.addAll(arrow.pathPoints);
    }

    int cX = head.x + dir.dx;
    int cY = head.y + dir.dy;

    while (cX >= 0 && cX < gridSize && cY >= 0 && cY < gridSize) {
      if (occupied.contains(Point2D(cX, cY))) {
        return false; // Path blocked!
      }
      cX += dir.dx;
      cY += dir.dy;
    }

    return true; // Path is 100% clear to grid boundary!
  }

  /// Find a solvable arrow for Hint
  static ArrowSnakeModel? findSolvableArrow(List<ArrowSnakeModel> arrows, int gridSize) {
    for (final arrow in arrows) {
      if (!arrow.isEscaping && canArrowEscape(arrow, arrows, gridSize)) {
        return arrow;
      }
    }
    return null;
  }

  /// Generate a guaranteed solvable level with difficulty scaling matching levelNumber
  static ArrowLevelModel generateLevel(int levelNumber) {
    final random = Random(levelNumber * 1000 + 1337);

    // Difficulty Grid Size Scaling
    int gridSize = 5;
    int arrowCount = 5 + (levelNumber ~/ 8);
    int maxLen = 3;

    if (levelNumber > 10) {
      gridSize = 6;
      maxLen = 3;
    }
    if (levelNumber > 25) {
      gridSize = 7;
      maxLen = 4;
    }
    if (levelNumber > 50) {
      gridSize = 8;
      maxLen = 4;
    }
    if (levelNumber > 90) {
      gridSize = 9;
      maxLen = 5;
    }
    if (levelNumber > 140) {
      gridSize = 10;
      maxLen = 5;
    }

    if (arrowCount > (gridSize * gridSize * 0.45).toInt()) {
      arrowCount = (gridSize * gridSize * 0.45).toInt();
    }

    final mask = <Point2D>{};
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        mask.add(Point2D(c, r));
      }
    }

    final arrows = <ArrowSnakeModel>[];
    final occupied = <Point2D>{};
    int attempts = 0;

    while (arrows.length < arrowCount && attempts < 500) {
      attempts++;

      final head = Point2D(random.nextInt(gridSize), random.nextInt(gridSize));
      if (occupied.contains(head)) continue;

      // Pick escape direction where path to boundary is currently clear
      final directions = [
        ArrowDirection.up,
        ArrowDirection.down,
        ArrowDirection.left,
        ArrowDirection.right,
      ]..shuffle(random);

      ArrowDirection? chosenDir;
      for (final dir in directions) {
        int cX = head.x + dir.dx;
        int cY = head.y + dir.dy;
        bool clear = true;

        while (cX >= 0 && cX < gridSize && cY >= 0 && cY < gridSize) {
          if (occupied.contains(Point2D(cX, cY))) {
            clear = false;
            break;
          }
          cX += dir.dx;
          cY += dir.dy;
        }

        if (clear) {
          chosenDir = dir;
          break;
        }
      }

      if (chosenDir == null) continue;

      // Build winding polyline body backwards from head
      final pathPoints = <Point2D>[head];
      occupied.add(head);

      final backDx = -chosenDir.dx;
      final backDy = -chosenDir.dy;

      final neck = Point2D(head.x + backDx, head.y + backDy);
      if (neck.x >= 0 && neck.x < gridSize && neck.y >= 0 && neck.y < gridSize && !occupied.contains(neck)) {
        pathPoints.add(neck);
        occupied.add(neck);

        int targetLen = 2 + random.nextInt(maxLen - 1);
        Point2D curr = neck;

        for (int i = 2; i < targetLen; i++) {
          final neighbors = [
            Point2D(curr.x + 1, curr.y),
            Point2D(curr.x - 1, curr.y),
            Point2D(curr.x, curr.y + 1),
            Point2D(curr.x, curr.y - 1),
          ]..shuffle(random);

          Point2D? nextPt;
          for (final n in neighbors) {
            if (n.x >= 0 && n.x < gridSize && n.y >= 0 && n.y < gridSize && !occupied.contains(n)) {
              nextPt = n;
              break;
            }
          }

          if (nextPt != null) {
            pathPoints.add(nextPt);
            occupied.add(nextPt);
            curr = nextPt;
          } else {
            break;
          }
        }
      } else {
        occupied.remove(head);
        continue;
      }

      final color = themePalette[arrows.length % themePalette.length];
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
      mask: mask,
    );
  }
}
