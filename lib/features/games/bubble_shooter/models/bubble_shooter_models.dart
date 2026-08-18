import 'package:flutter/material.dart';

enum BubbleType { normal, stone, ice, bomb }

class BubbleNode {
  final int colorId; // 0 to 6
  final int row;
  final int col;
  final BubbleType type;
  bool isFrozen;

  BubbleNode({
    required this.colorId,
    required this.row,
    required this.col,
    this.type = BubbleType.normal,
    this.isFrozen = false,
  });

  BubbleNode clone() {
    return BubbleNode(
      colorId: colorId,
      row: row,
      col: col,
      type: type,
      isFrozen: isFrozen,
    );
  }
}

class BubbleShooterGameState {
  final int levelNumber;
  final List<List<BubbleNode?>> grid; // rows x cols hex grid
  final int maxRows;
  final int maxCols;
  int currentShotColor;
  List<int> upcomingShotColors; // 3 upcoming shot colors for user preview & swap!
  double cannonAngle; // radians (-1.2 to 1.2)
  int shotsRemaining;
  int score;
  int movesCount;

  BubbleShooterGameState({
    required this.levelNumber,
    required this.grid,
    required this.maxRows,
    required this.maxCols,
    required this.currentShotColor,
    required this.upcomingShotColors,
    this.cannonAngle = 0.0,
    required this.shotsRemaining,
    this.score = 0,
    this.movesCount = 0,
  });

  BubbleShooterGameState clone() {
    final newGrid = List.generate(
      maxRows,
      (r) => List.generate(
        maxCols,
        (c) => grid[r][c]?.clone(),
      ),
    );

    return BubbleShooterGameState(
      levelNumber: levelNumber,
      grid: newGrid,
      maxRows: maxRows,
      maxCols: maxCols,
      currentShotColor: currentShotColor,
      upcomingShotColors: List<int>.from(upcomingShotColors),
      cannonAngle: cannonAngle,
      shotsRemaining: shotsRemaining,
      score: score,
      movesCount: movesCount,
    );
  }
}

class BubbleShooterColors {
  static const List<List<Color>> palettes = [
    [Color(0xFFEF4444), Color(0xFFB91C1C)], // 0: Vibrant Red 🔴
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // 1: Ocean Blue 🔵
    [Color(0xFF10B981), Color(0xFF047857)], // 2: Emerald Green 🟢
    [Color(0xFFF59E0B), Color(0xFFB45309)], // 3: Amber Yellow 🟡
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // 4: Royal Purple 🟣
    [Color(0xFFF97316), Color(0xFFC2410C)], // 5: Neon Orange 🟠
    [Color(0xFFEC4899), Color(0xFFBE185D)], // 6: Hot Pink 🌸
  ];

  static List<Color> getPalette(int colorId) {
    return palettes[colorId % palettes.length];
  }

  static Color getPrimary(int colorId) {
    return palettes[colorId % palettes.length].first;
  }
}
