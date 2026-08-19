import 'dart:math' as math;
import '../models/arrow_escape_models.dart';

class ArrowEscapeEngine {
  /// Generates progressive guaranteed solvable winding snake arrow levels
  static ArrowEscapeGameState generateLevel(int levelNumber) {
    final rng = math.Random(levelNumber * 7919 + 313);

    int gridSize = 5;
    if (levelNumber <= 10) {
      gridSize = 5;
    } else if (levelNumber <= 40) {
      gridSize = 6;
    } else if (levelNumber <= 100) {
      gridSize = 7;
    } else {
      gridSize = 8;
    }

    final List<ArrowModel> arrows = [];
    final board = List.generate(gridSize, (_) => List<int>.filled(gridSize, 0));

    final List<ArrowDirection> dirs = [
      ArrowDirection.up,
      ArrowDirection.down,
      ArrowDirection.left,
      ArrowDirection.right,
    ];

    int arrowCounter = 0;
    int targetArrows = (gridSize * gridSize * 0.45).round();
    int attempts = 0;

    while (arrows.length < targetArrows && attempts < 350) {
      attempts++;
      final hr = rng.nextInt(gridSize);
      final hc = rng.nextInt(gridSize);

      if (board[hr][hc] != 0) continue;

      final shuffledDirs = List<ArrowDirection>.from(dirs)..shuffle(rng);
      ArrowDirection? chosenDir;
      List<List<int>>? chosenPath;

      for (final dir in shuffledDirs) {
        final path = _generateWindingPath(board, gridSize, hr, hc, dir, rng);
        if (path != null && path.length >= 2) {
          chosenDir = dir;
          chosenPath = path;
          break;
        }
      }

      if (chosenDir != null && chosenPath != null) {
        arrowCounter++;
        for (final pt in chosenPath) {
          board[pt[0]][pt[1]] = arrowCounter;
        }

        arrows.add(ArrowModel(
          id: 'arrow_$arrowCounter',
          path: chosenPath,
          direction: chosenDir,
        ));
      }
    }

    return ArrowEscapeGameState(
      levelNumber: levelNumber,
      gridSize: gridSize,
      arrows: arrows,
      livesCount: 3,
      totalTimeSeconds: 60 + (levelNumber ~/ 5) * 5,
      remainingTimeSeconds: 60 + (levelNumber ~/ 5) * 5,
    );
  }

  /// Generates a winding path starting from head (hr, hc) turning 90 degrees
  static List<List<int>>? _generateWindingPath(
    List<List<int>> board,
    int size,
    int hr,
    int hc,
    ArrowDirection dir,
    math.Random rng,
  ) {
    // Escape check from head (hr, hc) pointing in dir
    if (!_canHeadEscapeToEdge(board, size, hr, hc, dir)) {
      return null;
    }

    final path = <List<int>>[
      [hr, hc]
    ];

    // Grow tail with 90-degree turns
    int currR = hr;
    int currC = hc;
    int tailLen = rng.nextInt(3) + 2; // 2 to 4 segments long

    List<ArrowDirection> growDirs = [
      dir.opposite,
      dir.turnLeft,
      dir.turnRight,
    ];

    for (int i = 0; i < tailLen - 1; i++) {
      growDirs.shuffle(rng);
      bool grown = false;

      for (final gdir in growDirs) {
        final nr = currR + gdir.delta.dx.toInt();
        final nc = currC + gdir.delta.dy.toInt();

        if (nr >= 0 && nr < size && nc >= 0 && nc < size && board[nr][nc] == 0) {
          if (!path.any((pt) => pt[0] == nr && pt[1] == nc)) {
            currR = nr;
            currC = nc;
            path.add([currR, currC]);
            grown = true;
            break;
          }
        }
      }

      if (!grown) break;
    }

    return path;
  }

  static bool _canHeadEscapeToEdge(
    List<List<int>> board,
    int size,
    int hr,
    int hc,
    ArrowDirection dir,
  ) {
    int r = hr + dir.delta.dx.toInt();
    int c = hc + dir.delta.dy.toInt();

    while (r >= 0 && r < size && c >= 0 && c < size) {
      if (board[r][c] != 0) return false;
      r += dir.delta.dx.toInt();
      c += dir.delta.dy.toInt();
    }
    return true;
  }

  /// Checks if launching targetArrow is unblocked by any other active arrow
  static bool isPathClear(ArrowEscapeGameState state, ArrowModel targetArrow) {
    if (targetArrow.isEscaping) return false;

    final head = targetArrow.head;
    final dir = targetArrow.direction;

    int r = head[0] + dir.delta.dx.toInt();
    int c = head[1] + dir.delta.dy.toInt();

    while (r >= 0 && r < state.gridSize && c >= 0 && c < state.gridSize) {
      for (final other in state.arrows) {
        if (other.id != targetArrow.id && !other.isEscaping) {
          if (other.path.any((pt) => pt[0] == r && pt[1] == c)) {
            return false; // Path blocked!
          }
        }
      }
      r += dir.delta.dx.toInt();
      c += dir.delta.dy.toInt();
    }

    return true; // Path clear to edge!
  }

  /// Finds a valid unblocked arrow that can escape immediately (Hint)
  static ArrowModel? findHint(ArrowEscapeGameState state) {
    for (final arrow in state.arrows) {
      if (!arrow.isEscaping && isPathClear(state, arrow)) {
        return arrow;
      }
    }
    return null;
  }

  /// Checks if all arrows have escaped
  static bool isLevelWon(ArrowEscapeGameState state) {
    return state.arrows.every((a) => a.isEscaping);
  }
}

extension ArrowDirectionHelper on ArrowDirection {
  ArrowDirection get opposite {
    switch (this) {
      case ArrowDirection.up:
        return ArrowDirection.down;
      case ArrowDirection.down:
        return ArrowDirection.up;
      case ArrowDirection.left:
        return ArrowDirection.right;
      case ArrowDirection.right:
        return ArrowDirection.left;
    }
  }

  ArrowDirection get turnLeft {
    switch (this) {
      case ArrowDirection.up:
        return ArrowDirection.left;
      case ArrowDirection.left:
        return ArrowDirection.down;
      case ArrowDirection.down:
        return ArrowDirection.right;
      case ArrowDirection.right:
        return ArrowDirection.up;
    }
  }

  ArrowDirection get turnRight {
    switch (this) {
      case ArrowDirection.up:
        return ArrowDirection.right;
      case ArrowDirection.right:
        return ArrowDirection.down;
      case ArrowDirection.down:
        return ArrowDirection.left;
      case ArrowDirection.left:
        return ArrowDirection.up;
    }
  }
}
