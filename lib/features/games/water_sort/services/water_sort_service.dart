import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';

class WaterSortProgress {
  final int maxUnlockedLevel;
  final Map<int, int> starsMap; // levelNumber -> stars (1-3)
  final int multiplier; // Admin configured coin multiplier N

  WaterSortProgress({
    required this.maxUnlockedLevel,
    required this.starsMap,
    required this.multiplier,
  });
}

class WaterSortService {
  final ApiService _api = ApiService();
  static const String _localProgressKey = 'sikkaplay_water_sort_progress';

  /// Loads current user level progress and Admin coin multiplier N
  Future<WaterSortProgress> loadProgress() async {
    int maxLevel = 1;
    Map<int, int> stars = {};
    int multiplier = 2; // Default multiplier

    try {
      // 1. Try local storage first for offline/instant load
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localProgressKey);
      if (raw != null) {
        final data = json.decode(raw);
        maxLevel = data['maxUnlockedLevel'] ?? 1;
        if (data['stars'] != null) {
          (data['stars'] as Map<String, dynamic>).forEach((k, v) {
            final lvl = int.tryParse(k);
            if (lvl != null) stars[lvl] = (v as num).toInt();
          });
        }
      }

      // 2. Fetch latest from Backend API if connected
      final res = await _api.get('/water-sort/progress');
      if (res.statusCode == 200 && res.data != null) {
        final body = res.data;
        if (body['success'] == true) {
          maxLevel = max(maxLevel, (body['maxUnlockedLevel'] ?? 1) as int);
          multiplier = (body['multiplier'] ?? 2) as int;
          if (body['stars'] != null) {
            (body['stars'] as Map<String, dynamic>).forEach((k, v) {
              final lvl = int.tryParse(k);
              if (lvl != null) stars[lvl] = (v as num).toInt();
            });
          }

          // Update local cache
          await saveLocalProgress(maxLevel, stars);
        }
      }
    } catch (e) {
      debugPrint('[WaterSortService] Load progress fallback: $e');
    }

    return WaterSortProgress(
      maxUnlockedLevel: maxLevel,
      starsMap: stars,
      multiplier: multiplier,
    );
  }

  /// Saves progress locally
  Future<void> saveLocalProgress(int maxLevel, Map<int, int> stars) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {
        'maxUnlockedLevel': maxLevel,
        'stars': stars.map((k, v) => MapEntry(k.toString(), v)),
      };
      await prefs.setString(_localProgressKey, json.encode(data));
    } catch (e) {
      debugPrint('Error saving local water sort progress: $e');
    }
  }

  /// Claims reward from backend for completing a level
  Future<Map<String, dynamic>> claimLevelReward({
    required int levelNumber,
    required int stars,
    required int movesCount,
  }) async {
    try {
      final res = await _api.post('/water-sort/complete-level', {
        'levelNumber': levelNumber,
        'stars': stars,
        'movesCount': movesCount,
      });

      if (res.statusCode == 200 && res.data != null) {
        return res.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error claiming water sort level reward: $e');
    }

    // Offline fallback estimation
    return {
      'success': true,
      'coinsEarned': levelNumber * 2,
      'newUnlockedLevel': levelNumber + 1,
    };
  }

  int max(int a, int b) => a > b ? a : b;
}
