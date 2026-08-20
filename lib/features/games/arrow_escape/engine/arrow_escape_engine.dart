import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_escape_models.dart';

class ArrowEscapeEngine {
  // Single Unified Palette (Neon Cyan) for all arrows!
  static const Color unifiedArrowColor = Color(0xFF00E5FF);

  /// Raycast collision check accounting for deflector dots along the path
  static bool canArrowEscape(
    ArrowSnakeModel target,
    List<ArrowSnakeModel> allArrows,
    List<DeflectorDotModel> deflectors,
    int gridSize,
  ) {
    if (target.isLocked) return false; // Locked arrows cannot escape until unlocked!

    final head = target.head;
    ArrowDirection currDir = target.escapeDirection;

    // Collect all occupied cells by other active (non-escaping) arrows
    final occupied = <Point2D>{};
    for (final arrow in allArrows) {
      if (arrow.id == target.id || arrow.isEscaping) continue;
      occupied.addAll(arrow.pathPoints);
    }

    final deflectorMap = <Point2D, ArrowDirection>{};
    for (final d in deflectors) {
      deflectorMap[d.position] = d.deflectDirection;
    }

    int cX = head.x + currDir.dx;
    int cY = head.y + currDir.dy;
    final visited = <Point2D>{};

    while (cX >= 0 && cX < gridSize && cY >= 0 && cY < gridSize) {
      final currPt = Point2D(cX, cY);
      if (visited.contains(currPt)) break; // Prevent infinite loop
      visited.add(currPt);

      if (occupied.contains(currPt)) {
        return false; // Path blocked by another arrow!
      }

      // Check if deflector dot alters trajectory
      if (deflectorMap.containsKey(currPt)) {
        currDir = deflectorMap[currPt]!;
      }

      cX += currDir.dx;
      cY += currDir.dy;
    }

    return true; // Path clear to boundary!
  }

  /// Find solvable arrow for Hint
  static ArrowSnakeModel? findSolvableArrow(
    List<ArrowSnakeModel> arrows,
    List<DeflectorDotModel> deflectors,
    int gridSize,
  ) {
    for (final arrow in arrows) {
      if (!arrow.isEscaping && !arrow.isLocked && canArrowEscape(arrow, arrows, deflectors, gridSize)) {
        return arrow;
      }
    }
    return null;
  }

  /// Generate Level according to user's exact scaling rules
  static ArrowLevelModel generateLevel(int levelNumber) {
    final random = Random(levelNumber * 1000 + 9999);

    int gridSize = 8;
    int minLen = 4;
    int maxLen = 6;

    if (levelNumber > 10) {
      gridSize = 9;
      minLen = 5;
      maxLen = 7;
    }
    if (levelNumber > 25) {
      gridSize = 10;
      minLen = 5;
      maxLen = 8;
    }
    if (levelNumber > 50) {
      gridSize = 11;
      minLen = 6;
      maxLen = 9;
    }
    if (levelNumber > 90) {
      gridSize = 12;
      minLen = 6;
      maxLen = 10;
    }
    if (levelNumber > 140) {
      gridSize = 13;
      minLen = 7;
      maxLen = 11;
    }

    // Arrow Count (+2 every level with high blockage rate)
    int arrowCount = 14 + (levelNumber * 2);
    final maxAllowed = (gridSize * gridSize * 0.55).toInt();
    if (arrowCount > maxAllowed) {
      arrowCount = maxAllowed;
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

    while (arrows.length < arrowCount && attempts < 1000) {
      attempts++;

      final head = Point2D(random.nextInt(gridSize), random.nextInt(gridSize));
      if (occupied.contains(head)) continue;

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

      final pathPoints = <Point2D>[head];
      occupied.add(head);

      final backDx = -chosenDir.dx;
      final backDy = -chosenDir.dy;

      final neck = Point2D(head.x + backDx, head.y + backDy);
      if (neck.x >= 0 && neck.x < gridSize && neck.y >= 0 && neck.y < gridSize && !occupied.contains(neck)) {
        pathPoints.add(neck);
        occupied.add(neck);

        int targetLen = minLen + random.nextInt(maxLen - minLen + 1);
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

      arrows.add(ArrowSnakeModel(
        id: 'arrow_${levelNumber}_${arrows.length}',
        pathPoints: pathPoints,
        color: unifiedArrowColor, // Single Unified Color
      ));
    }

    // Apply Lock & Key Mechanics (Level 20+)
    if (levelNumber >= 20 && arrows.length >= 4) {
      int pairs = 1 + (levelNumber ~/ 30);
      for (int p = 0; p < pairs && (p * 2 + 1) < arrows.length; p++) {
        final keyIndex = p * 2;
        final lockIndex = p * 2 + 1;

        arrows[lockIndex].isLocked = true;
        arrows[keyIndex].isKey = true;
        arrows[keyIndex].targetLockedId = arrows[lockIndex].id;
      }
    }

    // Apply Deflector Dots Mechanics (Level 30+)
    final deflectors = <DeflectorDotModel>[];
    if (levelNumber >= 30) {
      int deflectorCount = 1 + (levelNumber ~/ 25);
      final emptyCells = <Point2D>[];

      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          final pt = Point2D(c, r);
          if (!occupied.contains(pt)) {
            emptyCells.add(pt);
          }
        }
      }

      emptyCells.shuffle(random);
      for (int d = 0; d < deflectorCount && d < emptyCells.length; d++) {
        final dir = [
          ArrowDirection.up,
          ArrowDirection.down,
          ArrowDirection.left,
          ArrowDirection.right,
        ][random.nextInt(4)];

        deflectors.add(DeflectorDotModel(
          position: emptyCells[d],
          deflectDirection: dir,
        ));
      }
    }

    return ArrowLevelModel(
      levelNumber: levelNumber,
      gridSize: gridSize,
      arrows: arrows,
      deflectors: deflectors,
      mask: mask,
    );
  }
}
