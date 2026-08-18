import 'dart:math';
import '../models/bubble_shooter_models.dart';

class BubbleShooterEngine {
  static const int cols = 9;

  /// Generates progressive 3-5 minute levels for Level 1 to 200+
  static BubbleShooterGameState generateLevel(int levelNumber) {
    final Random rng = Random(levelNumber * 104729 + 8831);

    // 1. Color count & Row depth progression
    int colorCount;
    int filledRows;
    int shotsLimit;

    if (levelNumber <= 5) {
      colorCount = 3;
      filledRows = 5;
      shotsLimit = 25;
    } else if (levelNumber <= 10) {
      colorCount = 4;
      filledRows = 8;
      shotsLimit = 22;
    } else if (levelNumber <= 25) {
      colorCount = 4;
      filledRows = 12; // 3-4 Minutes play
      shotsLimit = 20;
    } else if (levelNumber <= 50) {
      colorCount = 5;
      filledRows = 15; // 4-5 Minutes play
      shotsLimit = 18;
    } else if (levelNumber <= 100) {
      colorCount = 6;
      filledRows = 18; // 5+ Minutes play
      shotsLimit = 16;
    } else {
      colorCount = 7;
      filledRows = 22; // 5-8 Minutes play
      shotsLimit = 15;
    }

    const int maxRows = 26;
    List<List<BubbleNode?>> grid = List.generate(
      maxRows,
      (r) => List.generate(cols, (c) => null),
    );

    // 2. Populate top rows with staggered colors & obstacles
    for (int r = 0; r < filledRows; r++) {
      for (int c = 0; c < (r % 2 == 1 ? cols - 1 : cols); c++) {
        // Obstacle injection for level 25+
        BubbleType bType = BubbleType.normal;
        bool isFrozen = false;

        if (levelNumber >= 25 && rng.nextDouble() < 0.08) {
          bType = BubbleType.stone;
        } else if (levelNumber >= 40 && rng.nextDouble() < 0.06) {
          bType = BubbleType.ice;
          isFrozen = true;
        }

        final colorId = rng.nextInt(colorCount);
        grid[r][c] = BubbleNode(
          colorId: colorId,
          row: r,
          col: c,
          type: bType,
          isFrozen: isFrozen,
        );
      }
    }

    final currentShotColor = rng.nextInt(colorCount);
    final nextShotColor = rng.nextInt(colorCount);

    return BubbleShooterGameState(
      levelNumber: levelNumber,
      grid: grid,
      maxRows: maxRows,
      maxCols: cols,
      currentShotColor: currentShotColor,
      nextShotColor: nextShotColor,
      shotsRemaining: shotsLimit,
    );
  }

  /// Get neighboring hex cells for a given (row, col)
  static List<Point<int>> getNeighbors(int r, int c, int maxRows, int maxCols) {
    List<Point<int>> neighbors = [];
    final bool isOdd = (r % 2 == 1);

    // Direct Left & Right
    final offsets = isOdd
        ? [
            const Point(-1, 0), const Point(-1, 1),
            const Point(0, -1), const Point(0, 1),
            const Point(1, 0), const Point(1, 1)
          ]
        : [
            const Point(-1, -1), const Point(-1, 0),
            const Point(0, -1), const Point(0, 1),
            const Point(1, -1), const Point(1, 0)
          ];

    for (final off in offsets) {
      final nr = r + off.x;
      final nc = c + off.y;
      final maxC = (nr % 2 == 1) ? maxCols - 1 : maxCols;

      if (nr >= 0 && nr < maxRows && nc >= 0 && nc < maxC) {
        neighbors.add(Point(nr, nc));
      }
    }

    return neighbors;
  }

  /// Finds all connected matching color bubbles starting from (startR, startC)
  static List<Point<int>> findCluster(BubbleShooterGameState state, int startR, int startC) {
    final startBubble = state.grid[startR][startC];
    if (startBubble == null || startBubble.type == BubbleType.stone) return [];

    final targetColor = startBubble.colorId;
    List<Point<int>> cluster = [];
    Set<String> visited = {};
    List<Point<int>> queue = [Point(startR, startC)];

    visited.add('$startR,$startC');

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      cluster.add(curr);

      for (final n in getNeighbors(curr.x, curr.y, state.maxRows, state.maxCols)) {
        final key = '${n.x},${n.y}';
        if (!visited.contains(key)) {
          final neighborBubble = state.grid[n.x][n.y];
          if (neighborBubble != null &&
              neighborBubble.colorId == targetColor &&
              neighborBubble.type != BubbleType.stone) {
            visited.add(key);
            queue.add(n);
          }
        }
      }
    }

    return cluster;
  }

  /// Finds all un-anchored (orphan) bubbles disconnected from row 0
  static List<Point<int>> findOrphanBubbles(BubbleShooterGameState state) {
    Set<String> anchored = {};
    List<Point<int>> queue = [];

    // Add all non-null bubbles in row 0 as BFS seeds
    for (int c = 0; c < state.maxCols; c++) {
      if (state.grid[0][c] != null) {
        queue.add(Point(0, c));
        anchored.add('0,$c');
      }
    }

    // BFS to mark all connected bubbles to ceiling
    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);

      for (final n in getNeighbors(curr.x, curr.y, state.maxRows, state.maxCols)) {
        final key = '${n.x},${n.y}';
        if (!anchored.contains(key) && state.grid[n.x][n.y] != null) {
          anchored.add(key);
          queue.add(n);
        }
      }
    }

    // All grid bubbles NOT in anchored set are orphans!
    List<Point<int>> orphans = [];
    for (int r = 0; r < state.maxRows; r++) {
      final maxC = (r % 2 == 1) ? state.maxCols - 1 : state.maxCols;
      for (int c = 0; c < maxC; c++) {
        if (state.grid[r][c] != null && !anchored.contains('$r,$c')) {
          orphans.add(Point(r, c));
        }
      }
    }

    return orphans;
  }

  /// Check if the level is won (all non-stone bubbles cleared from grid)
  static bool isLevelWon(BubbleShooterGameState state) {
    for (int r = 0; r < state.maxRows; r++) {
      for (int c = 0; c < state.maxCols; c++) {
        final node = state.grid[r][c];
        if (node != null && node.type != BubbleType.stone) {
          return false;
        }
      }
    }
    return true;
  }
}
