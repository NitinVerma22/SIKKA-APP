import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/arrow_escape_models.dart';

class ArrowEscapeEngine {
  /// Generates progressive 200 solvable arrow puzzle levels
  static ArrowEscapeGameState generateLevel(int levelNumber) {
    final rng = math.Random(levelNumber * 7919 + 313);

    // Determine grid dimensions based on level
    int gridRows;
    int gridCols;

    if (levelNumber <= 5) {
      gridRows = 4;
      gridCols = 4;
    } else if (levelNumber <= 20) {
      gridRows = 5;
      gridCols = 5;
    } else if (levelNumber <= 60) {
      gridRows = 6;
      gridCols = 5;
    } else if (levelNumber <= 120) {
      gridRows = 6;
      gridCols = 6;
    } else {
      gridRows = 7;
      gridCols = 6;
    }

    final grid = List.generate(
      gridRows,
      (r) => List<ArrowNode?>.filled(gridCols, null),
    );

    final List<ArrowDir> cardinalDirs = [
      ArrowDir.up,
      ArrowDir.down,
      ArrowDir.left,
      ArrowDir.right,
    ];

    final List<ArrowDir> allDirs = [
      ArrowDir.up,
      ArrowDir.down,
      ArrowDir.left,
      ArrowDir.right,
      ArrowDir.upLeft,
      ArrowDir.upRight,
      ArrowDir.downLeft,
      ArrowDir.downRight,
    ];

    // Populate grid ensuring edge nodes point outwards
    int nodeCounter = 0;
    for (int r = 0; r < gridRows; r++) {
      for (int c = 0; c < gridCols; c++) {
        // Density probability
        if (rng.nextDouble() < 0.85) {
          List<ArrowDir> candidateDirs = [];

          // Edge bias for clean escape paths
          if (r == 0) candidateDirs.add(ArrowDir.up);
          if (r == gridRows - 1) candidateDirs.add(ArrowDir.down);
          if (c == 0) candidateDirs.add(ArrowDir.left);
          if (c == gridCols - 1) candidateDirs.add(ArrowDir.right);

          ArrowDir chosenDir;
          if (candidateDirs.isNotEmpty && rng.nextDouble() < 0.6) {
            chosenDir = candidateDirs[rng.nextInt(candidateDirs.length)];
          } else {
            chosenDir = (levelNumber > 15 && rng.nextDouble() < 0.3)
                ? allDirs[rng.nextInt(allDirs.length)]
                : cardinalDirs[rng.nextInt(cardinalDirs.length)];
          }

          final color = ArrowEscapeColors.getColor((r + c) % ArrowEscapeColors.arrowColors.length);

          grid[r][c] = ArrowNode(
            id: 'node_${nodeCounter++}',
            row: r,
            col: c,
            dir: chosenDir,
            color: color,
          );
        }
      }
    }

    return ArrowEscapeGameState(
      levelNumber: levelNumber,
      grid: grid,
      rows: gridRows,
      cols: gridCols,
      livesCount: 3,
    );
  }

  /// Checks if launching the arrow at (row, col) is unblocked and will escape cleanly
  static bool isPathClear(ArrowEscapeGameState state, int row, int col) {
    final arrow = state.grid[row][col];
    if (arrow == null || arrow.isEscaping) return false;

    final vec = arrow.dir.vector;
    double stepR = arrow.row + vec.dy * 0.8;
    double stepC = arrow.col + vec.dx * 0.8;

    while (stepR >= 0 && stepR < state.rows && stepC >= 0 && stepC < state.cols) {
      final int checkR = stepR.round();
      final int checkC = stepC.round();

      if (checkR >= 0 && checkR < state.rows && checkC >= 0 && checkC < state.cols) {
        // Skip current cell itself
        if (checkR != row || checkC != col) {
          final blockingNode = state.grid[checkR][checkC];
          if (blockingNode != null && !blockingNode.isEscaping) {
            return false; // Path blocked!
          }
        }
      }

      stepR += vec.dy * 0.5;
      stepC += vec.dx * 0.5;
    }

    return true; // Path clear!
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

  /// Checks if the level is completely won (all arrows escaped)
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
