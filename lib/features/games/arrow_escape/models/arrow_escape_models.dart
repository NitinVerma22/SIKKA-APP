import 'package:flutter/material.dart';

enum ArrowDirection { up, right, down, left }

class Point2D {
  final int x;
  final int y;

  const Point2D(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point2D && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Point2D copyWith({int? x, int? y}) => Point2D(x ?? this.x, y ?? this.y);
}

class ArrowSnakeModel {
  final String id;
  final List<Point2D> pathPoints; // Index 0 is head, last is tail
  final Color color;
  bool isEscaping;
  double escapeProgress; // 0.0 to 1.0
  bool isBlockedShaking;
  double shakeProgress; // -1.0 to 1.0

  ArrowSnakeModel({
    required this.id,
    required this.pathPoints,
    required this.color,
    this.isEscaping = false,
    this.escapeProgress = 0.0,
    this.isBlockedShaking = false,
    this.shakeProgress = 0.0,
  });

  Point2D get head => pathPoints.first;
  Point2D get neck => pathPoints.length > 1 ? pathPoints[1] : head;

  ArrowDirection get escapeDirection {
    if (pathPoints.length < 2) return ArrowDirection.up;
    final h = head;
    final n = neck;
    if (h.x > n.x) return ArrowDirection.right;
    if (h.x < n.x) return ArrowDirection.left;
    if (h.y > n.y) return ArrowDirection.down;
    return ArrowDirection.up;
  }

  ArrowSnakeModel copyWith({
    String? id,
    List<Point2D>? pathPoints,
    Color? color,
    bool? isEscaping,
    double? escapeProgress,
    bool? isBlockedShaking,
    double? shakeProgress,
  }) {
    return ArrowSnakeModel(
      id: id ?? this.id,
      pathPoints: pathPoints ?? List.from(this.pathPoints),
      color: color ?? this.color,
      isEscaping: isEscaping ?? this.isEscaping,
      escapeProgress: escapeProgress ?? this.escapeProgress,
      isBlockedShaking: isBlockedShaking ?? this.isBlockedShaking,
      shakeProgress: shakeProgress ?? this.shakeProgress,
    );
  }
}

class ArrowLevelModel {
  final int levelNumber;
  final int gridSize; // e.g. 6x6, 7x7, 8x8
  final List<ArrowSnakeModel> arrows;
  final int maxTimeSeconds;

  const ArrowLevelModel({
    required this.levelNumber,
    required this.gridSize,
    required this.arrows,
    this.maxTimeSeconds = 0,
  });
}
