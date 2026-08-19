import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:sikkaplay/features/games/arrow_escape/core/constants.dart';
import 'package:sikkaplay/features/games/arrow_escape/data/models/level.dart';
import 'components/grid_component.dart';
import 'game_state.dart';

class ArrowPuzzleGame extends FlameGame {
  
  final LevelModel level;
  final GameState gameState;
  GridComponent? gridComponent;

  final void Function() onLevelComplete;
  final void Function() onGameOver;
  final void Function() onLifeLost;

  ArrowPuzzleGame({
    required this.level,
    required this.gameState,
    required this.onLevelComplete,
    required this.onGameOver,
    required this.onLifeLost,
  });

  @override
  Color backgroundColor() => Colors.transparent;

  double get _safeMinDim {
    double minDim = size.x < size.y ? size.x : size.y;
    if (minDim <= 0) minDim = 360.0;
    return minDim;
  }

  @override
  Future<void> onLoad() async {
    final levelType = AppConstants.levelTypeFor(level.levelNumber);
    final scale = AppConstants.canvasScaleForType(levelType);

    final minDim = _safeMinDim;
    final gridSize = minDim * scale;
    final effSx = size.x <= 0 ? 360.0 : size.x;
    final effSy = size.y <= 0 ? 600.0 : size.y;

    final gridX = (effSx - gridSize) / 2;
    final gridY = (effSy - gridSize) / 2;

    gridComponent = GridComponent(
      gameState: gameState,
      gridPixelSize: gridSize <= 0 ? 300.0 : gridSize,
      position: Vector2(gridX + gridSize / 2, gridY + gridSize / 2),
    )..anchor = Anchor.center;

    add(gridComponent!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    final levelType = AppConstants.levelTypeFor(level.levelNumber);
    final scale = AppConstants.canvasScaleForType(levelType);

    final minDim = _safeMinDim;
    final gridSize = minDim * scale;
    final effSx = size.x <= 0 ? 360.0 : size.x;
    final effSy = size.y <= 0 ? 600.0 : size.y;

    final gridX = (effSx - gridSize) / 2;
    final gridY = (effSy - gridSize) / 2;

    if (gridComponent != null) {
      gridComponent!.position = Vector2(gridX + gridSize / 2, gridY + gridSize / 2);
      gridComponent!.resize(gridSize <= 0 ? 300.0 : gridSize);
    }
  }

  void resetLevel() {
    gameState.resetLevel();
    gridComponent?.rebuild();
  }
}