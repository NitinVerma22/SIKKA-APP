import 'package:flutter/material.dart';

/// Representation of a single tube containing liquid units (Color IDs).
/// Index 0 = bottom of tube, last element = top of tube.
typedef TubeState = List<int>;

/// Color Palette for Liquid Units (8 distinct, vibrant liquid colors)
class WaterSortColors {
  static const List<Color> palette = [
    Color(0xFFFF3B30), // 0: Crimson Red
    Color(0xFF007AFF), // 1: Ocean Blue
    Color(0xFF34C759), // 2: Emerald Green
    Color(0xFFFFCC00), // 3: Golden Yellow
    Color(0xFFAF52DE), // 4: Royal Purple
    Color(0xFFFF9500), // 5: Sunset Orange
    Color(0xFF00C7BE), // 6: Cyan Teal
    Color(0xFFFF2D55), // 7: Rose Pink
    Color(0xFF8E8E93), // 8: Charcoal Gray
  ];

  static Color getColor(int colorId) {
    if (colorId < 0 || colorId >= palette.length) {
      return Colors.blueAccent;
    }
    return palette[colorId];
  }
}

/// Represents a single Pour move from [fromIndex] tube to [toIndex] tube.
class WaterSortMove {
  final int fromIndex;
  final int toIndex;
  final int count;

  const WaterSortMove({
    required this.fromIndex,
    required this.toIndex,
    required this.count,
  });
}

/// Data class for a Water Sort Game Level State
class WaterSortGameState {
  final List<TubeState> tubes;
  final int capacity;
  final int levelNumber;
  int movesCount;

  WaterSortGameState({
    required this.tubes,
    this.capacity = 4,
    required this.levelNumber,
    this.movesCount = 0,
  });

  WaterSortGameState clone() {
    return WaterSortGameState(
      tubes: tubes.map((t) => List<int>.from(t)).toList(),
      capacity: capacity,
      levelNumber: levelNumber,
      movesCount: movesCount,
    );
  }
}
