import 'dart:math' as math;
import '../models/arrow_escape_models.dart';

class ArrowEscapeEngine {
  /// Generates progressive guaranteed solvable arrow puzzle levels
  static ArrowEscapeGameState generateLevel(int levelNumber) {
    final rng = math.Random(levelNumber * 10007 + 7919);

    int rows = 4;
    int cols = 4;

    if (levelNumber <= 5) {
      rows = 4;
      cols = 4;
    } else if (levelNumber <= 20) {
      rows = 5;
      cols = 4;
    } else if (levelNumber <= 50) {
      rows = 5;
      cols = 5;
    } else if (levelNumber <= 100) {
      rows = 6;
      cols = 5;
    } else {
      rows = 6;
      cols = 6;
    }

    final grid = List.generate(
      rows,
      (r) => List<ArrowNode?>.filled(cols, null),
    );

    final List<ArrowDir> dirs = [
      ArrowDir.up,
      ArrowDir.down,
      ArrowDir.left,
      ArrowDir.right,
    ];

    // Guaranteed Solvable Reverse-Placement Simulation
    final int targetCount = (rows * cols * 0.75).round();
    int placed = 0;
    int attempts = 0;

    while (placed < targetCount && attempts < 250) {
      attempts++;
      final r = rng.nextInt(rows);
      final c = rng.nextInt(cols);

      if (grid[r][c] != null) continue;

      // Pick a direction that has a clear path out of the current grid state
      final shuffledDirs = List<ArrowDir>.from(dirs)..shuffle(rng);
      ArrowDir? validDir;

      for (final dir in shuffledDirs) {
        if (_canEscapeInCurrentGrid(grid, rows, cols, r, c, dir)) {
          validDir = dir;
          break;
        }
      }

      if (validDir != null) {
        final color = ArrowEscapeColors.getColor((r * cols + c) % ArrowEscapeColors.arrowColors.length);
        grid[r][c] = ArrowNode(
          id: 'node_${r}_${c}_$placed',
          row: r,
          col: c,
          dir: validDir,
          color: color,
        );
        placed++;
      }
    }

    return ArrowEscapeGameState(
      levelNumber: levelNumber,
      grid: grid,
      rows: rows,
      cols: cols,
      livesCount: 3,
    );
  }

  static bool _canEscapeInCurrentGrid(
    List<List<ArrowNode?>> grid,
    int maxRows,
    int maxCols,
    int r,
    int c,
    ArrowDir dir,
  ) {
    final vec = dir.vector;
    int currR = r + vec.dy.toInt();
    int currC = c + vec.dx.toInt();

    while (currR >= 0 && currR < maxRows && currC >= 0 && currC < maxCols) {
      if (grid[currR][currC] != null) {
        return false; // Path currently blocked by existing node
      }
      currR += vec.dy.toInt();
      currC += vec.dx.toInt();
    }

    return true; // Path is completely clear to grid edge!
  }

  /// Checks if an arrow at (row, col) has an unblocked path to escape off the board
  static bool isPathClear(ArrowEscapeGameState state, int row, int col) {
    final arrow = state.grid[row][col];
    if (arrow == null || arrow.isEscaping) return false;

    final vec = arrow.dir.vector;
    int currR = row + vec.dy.toInt();
    int currC = col + vec.dx.toInt();

    while (currR >= 0 && currR < state.rows && currC >= 0 && currC < state.cols) {
      final blockingNode = state.grid[currR][currC];
      if (blockingNode != null && !blockingNode.isEscaping) {
        return false; // Blocked by another un-escaped arrow!
      }
      currR += vec.dy.toInt();
      currC += vec.dx.toInt();
    }

    return true; // Unblocked path!
  }

  /// Finds a valid unblocked arrow that can escape immediately (Hint)
  static ArrowNode? findHint(ArrowEscapeGameState state) {
    for (int r = 0; r < state.rows; r++) {
      for (int c = 0; c < state.cols; c++) {
        final node = state.grid[r][c];
        if (node != null && !node.isEscaping && isPathClear(state, r, c)) {
          return node;
        }
      }
    }
    return null;
  }

  /// Checks if all arrows have escaped
  static bool isLevelWon(ArrowEscapeGameState state) {
    for (int r = 0; r < state.rows; r++) {
      for (int c = 0; c < state.cols; c++) {
        final node = state.grid[r][c];
        if (node != null && !node.isEscaping) {
          return false;
        }
      }
    }
    return true;
  }
}
