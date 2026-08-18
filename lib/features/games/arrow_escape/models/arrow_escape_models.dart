import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ArrowDir { up, down, left, right }

extension ArrowDirExtension on ArrowDir {
  Offset get vector {
    switch (this) {
      case ArrowDir.up:
        return const Offset(0, -1);
      case ArrowDir.down:
        return const Offset(0, 1);
      case ArrowDir.left:
        return const Offset(-1, 0);
      case ArrowDir.right:
        return const Offset(1, 0);
    }
  }

  double get angleRadians {
    switch (this) {
      case ArrowDir.up:
        return -math.pi / 2;
      case ArrowDir.down:
        return math.pi / 2;
      case ArrowDir.left:
        return math.pi;
      case ArrowDir.right:
        return 0.0;
    }
  }
}

class ArrowNode {
  final String id;
  final int row;
  final int col;
  final ArrowDir dir;
  final Color color;
  bool isEscaping;
  Offset flightOffset;

  ArrowNode({
    required this.id,
    required this.row,
    required this.col,
    required this.dir,
    required this.color,
    this.isEscaping = false,
    this.flightOffset = Offset.zero,
  });

  ArrowNode clone() {
    return ArrowNode(
      id: id,
      row: row,
      col: col,
      dir: dir,
      color: color,
      isEscaping: isEscaping,
      flightOffset: flightOffset,
    );
  }
}

class ArrowEscapeGameState {
  final int levelNumber;
  final List<List<ArrowNode?>> grid;
  final int rows;
  final int cols;
  int movesCount;
  int livesCount;
  int score;

  ArrowEscapeGameState({
    required this.levelNumber,
    required this.grid,
    required this.rows,
    required this.cols,
    this.movesCount = 0,
    this.livesCount = 3,
    this.score = 0,
  });

  ArrowEscapeGameState clone() {
    final newGrid = List.generate(
      rows,
      (r) => List.generate(
        cols,
        (c) => grid[r][c]?.clone(),
      ),
    );

    return ArrowEscapeGameState(
      levelNumber: levelNumber,
      grid: newGrid,
      rows: rows,
      cols: cols,
      movesCount: movesCount,
      livesCount: livesCount,
      score: score,
    );
  }
}

class ArrowEscapeColors {
  static const List<Color> arrowColors = [
    Color(0xFF38BDF8), // Cyan Blue
    Color(0xFFF43F5E), // Rose Pink
    Color(0xFF10B981), // Emerald Green
    Color(0xFFF59E0B), // Amber Gold
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Hot Pink
  ];

  static Color getColor(int index) {
    return arrowColors[index % arrowColors.length];
  }
}
