import 'package:flutter/material.dart';

enum ArrowDirection {
  up(0, -1),
  right(1, 0),
  down(0, 1),
  left(-1, 0);

  final int dx;
  final int dy;
  const ArrowDirection(this.dx, this.dy);
}

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
}

class DeflectorDotModel {
  final Point2D position;
  final ArrowDirection deflectDirection;

  const DeflectorDotModel({
    required this.position,
    required this.deflectDirection,
  });
}

class ArrowSnakeModel {
  final String id;
  final List<Point2D> pathPoints; // Index 0 is head, last is tail
  final Color color;
  
  bool isLocked;
  bool isKey;
  String? targetLockedId;

  bool isEscaping;
  double escapeProgress; // 0.0 to 1.0
  
  bool isBlockedShaking;
  double shakeProgress; // -1.0 to 1.0

  ArrowSnakeModel({
    required this.id,
    required this.pathPoints,
    required this.color,
    this.isLocked = false,
    this.isKey = false,
    this.targetLockedId,
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
    bool? isLocked,
    bool? isKey,
    String? targetLockedId,
    bool? isEscaping,
    double? escapeProgress,
    bool? isBlockedShaking,
    double? shakeProgress,
  }) {
    return ArrowSnakeModel(
      id: id ?? this.id,
      pathPoints: pathPoints ?? List.from(this.pathPoints),
      color: color ?? this.color,
      isLocked: isLocked ?? this.isLocked,
      isKey: isKey ?? this.isKey,
      targetLockedId: targetLockedId ?? this.targetLockedId,
      isEscaping: isEscaping ?? this.isEscaping,
      escapeProgress: escapeProgress ?? this.escapeProgress,
      isBlockedShaking: isBlockedShaking ?? this.isBlockedShaking,
      shakeProgress: shakeProgress ?? this.shakeProgress,
    );
  }
}

class ArrowLevelModel {
  final int levelNumber;
  final int gridSize;
  final List<ArrowSnakeModel> arrows;
  final List<DeflectorDotModel> deflectors;
  final Set<Point2D> mask;

  const ArrowLevelModel({
    required this.levelNumber,
    required this.gridSize,
    required this.arrows,
    required this.deflectors,
    required this.mask,
  });
}
