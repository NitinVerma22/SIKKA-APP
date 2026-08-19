import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ArrowDirection {
  up,
  down,
  left,
  right;

  Offset get delta {
    switch (this) {
      case ArrowDirection.up:
        return const Offset(-1, 0);
      case ArrowDirection.down:
        return const Offset(1, 0);
      case ArrowDirection.left:
        return const Offset(0, -1);
      case ArrowDirection.right:
        return const Offset(0, 1);
    }
  }

  double get rotationRadians {
    switch (this) {
      case ArrowDirection.right:
        return 0.0;
      case ArrowDirection.down:
        return math.pi / 2;
      case ArrowDirection.left:
        return math.pi;
      case ArrowDirection.up:
        return -math.pi / 2;
    }
  }
}

class ArrowModel {
  final String id;
  final List<List<int>> path; // Winding polyline path: [[r0, c0], [r1, c1], ...]
  final ArrowDirection direction;
  final Color color;
  bool isEscaping;
  bool isColliding;
  double animProgress; // 0.0 to 1.0 along the path

  ArrowModel({
    required this.id,
    required this.path,
    required this.direction,
    this.color = Colors.white,
    this.isEscaping = false,
    this.isColliding = false,
    this.animProgress = 0.0,
  });

  List<int> get head => path.first;

  ArrowModel clone() {
    return ArrowModel(
      id: id,
      path: path.map((pt) => List<int>.from(pt)).toList(),
      direction: direction,
      color: color,
      isEscaping: isEscaping,
      isColliding: isColliding,
      animProgress: animProgress,
    );
  }
}

class ArrowEscapeGameState {
  final int levelNumber;
  final int gridSize;
  final List<ArrowModel> arrows;
  int livesCount;
  int score;
  int totalTimeSeconds;
  int remainingTimeSeconds;

  ArrowEscapeGameState({
    required this.levelNumber,
    required this.gridSize,
    required this.arrows,
    this.livesCount = 3,
    this.score = 0,
    this.totalTimeSeconds = 60,
    this.remainingTimeSeconds = 60,
  });

  ArrowEscapeGameState clone() {
    return ArrowEscapeGameState(
      levelNumber: levelNumber,
      gridSize: gridSize,
      arrows: arrows.map((a) => a.clone()).toList(),
      livesCount: livesCount,
      score: score,
      totalTimeSeconds: totalTimeSeconds,
      remainingTimeSeconds: remainingTimeSeconds,
    );
  }
}
