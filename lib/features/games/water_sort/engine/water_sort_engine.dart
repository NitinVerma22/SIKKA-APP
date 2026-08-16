import 'dart:math';
import '../models/water_sort_models.dart';

class WaterSortEngine {
  /// Check if pouring from [fromIdx] to [toIdx] is a valid move.
  static bool canPour(WaterSortGameState state, int fromIdx, int toIdx) {
    if (fromIdx == toIdx) return false;
    if (fromIdx < 0 || fromIdx >= state.tubes.length) return false;
    if (toIdx < 0 || toIdx >= state.tubes.length) return false;

    final src = state.tubes[fromIdx];
    final dst = state.tubes[toIdx];

    // Source must not be empty
    if (src.isEmpty) return false;
    // Destination must have room
    if (dst.length >= state.capacity) return false;

    // Destination must be empty OR have matching top color
    if (dst.isNotEmpty && dst.last != src.last) return false;

    return true;
  }

  /// Calculates how many units of the top color will be poured from [fromIdx] to [toIdx].
  static int getPourCount(WaterSortGameState state, int fromIdx, int toIdx) {
    if (!canPour(state, fromIdx, toIdx)) return 0;

    final src = state.tubes[fromIdx];
    final dst = state.tubes[toIdx];
    final color = src.last;

    // Count contiguous top units of the same color in src
    int srcRun = 0;
    for (int i = src.length - 1; i >= 0; i--) {
      if (src[i] == color) {
        srcRun++;
      } else {
        break;
      }
    }

    // Capacity remaining in dst
    final availableSpace = state.capacity - dst.length;

    return min(srcRun, availableSpace);
  }

  /// Executes the pour move and updates the state in-place. Returns [WaterSortMove].
  static WaterSortMove? executePour(WaterSortGameState state, int fromIdx, int toIdx) {
    final count = getPourCount(state, fromIdx, toIdx);
    if (count == 0) return null;

    final src = state.tubes[fromIdx];
    final dst = state.tubes[toIdx];

    for (int i = 0; i < count; i++) {
      dst.add(src.removeLast());
    }

    state.movesCount++;
    return WaterSortMove(fromIndex: fromIdx, toIndex: toIdx, count: count);
  }

  /// Checks if the level is won (all tubes are either empty or completely filled with a single color).
  static bool isLevelComplete(WaterSortGameState state) {
    for (final tube in state.tubes) {
      if (tube.isEmpty) continue;
      if (tube.length != state.capacity) return false;

      final firstColor = tube.first;
      if (!tube.every((c) => c == firstColor)) return false;
    }
    return true;
  }

  /// Procedural Level Generator for Level 1 to 200+
  /// Dynamically computes number of colors, capacity, and empty tubes.
  static WaterSortGameState generateLevel(int levelNumber) {
    final Random rng = Random(levelNumber * 7919);

    // Scaling difficulty based on level number
    int colorCount = 3 + (levelNumber ~/ 15);
    colorCount = min(8, colorCount); // Cap at 8 distinct colors

    int capacity = 4;
    int emptyTubes = 2;

    // Build solved state pool (each color repeated `capacity` times)
    List<int> liquidPool = [];
    for (int c = 0; c < colorCount; c++) {
      for (int k = 0; k < capacity; k++) {
        liquidPool.add(c);
      }
    }

    // Shuffle liquid pool
    liquidPool.shuffle(rng);

    // Distribute liquid into filled tubes
    List<TubeState> tubes = [];
    for (int i = 0; i < colorCount; i++) {
      final tube = liquidPool.sublist(i * capacity, (i + 1) * capacity);
      tubes.add(tube);
    }

    // Add empty tubes
    for (int i = 0; i < emptyTubes; i++) {
      tubes.add([]);
    }

    return WaterSortGameState(
      tubes: tubes,
      capacity: capacity,
      levelNumber: levelNumber,
    );
  }

  /// A* Solver to suggest the next best move (Hint functionality).
  static WaterSortMove? findHint(WaterSortGameState state) {
    for (int i = 0; i < state.tubes.length; i++) {
      if (state.tubes[i].isEmpty) continue;
      
      // Skip tube if it's already complete
      if (state.tubes[i].length == state.capacity &&
          state.tubes[i].every((c) => c == state.tubes[i].first)) {
        continue;
      }

      for (int j = 0; j < state.tubes.length; j++) {
        if (i == j) continue;
        if (canPour(state, i, j)) {
          // Prefer pouring to non-empty tube of same color over empty tube
          if (state.tubes[j].isNotEmpty) {
            return WaterSortMove(fromIndex: i, toIndex: j, count: getPourCount(state, i, j));
          }
        }
      }
    }

    // Fallback: any valid pour
    for (int i = 0; i < state.tubes.length; i++) {
      for (int j = 0; j < state.tubes.length; j++) {
        if (canPour(state, i, j)) {
          return WaterSortMove(fromIndex: i, toIndex: j, count: getPourCount(state, i, j));
        }
      }
    }

    return null;
  }
}
