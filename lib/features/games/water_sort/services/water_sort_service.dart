import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/user/user_service.dart';

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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String get _waterSortUrl => AuthService.baseUrl.replaceAll('/auth', '/v1/water-sort');

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };
  }

  /// Loads current user level progress and Admin coin multiplier N
  Future<WaterSortProgress> loadProgress() async {
    int maxLevel = 1;
    Map<int, int> stars = {};
    int multiplier = 2; // Default multiplier

    try {
      // 1. Try local storage first for offline/instant load
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('sikkaplay_water_sort_progress');
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
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$_waterSortUrl/progress'),
        headers: headers,
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
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
      await prefs.setString('sikkaplay_water_sort_progress', json.encode(data));
    } catch (e) {
      debugPrint('Error saving local water sort progress: $e');
    }
  }

  /// Claims reward from backend for completing a level
  Future<Map<String, dynamic>> claimLevelReward({
    required int levelNumber,
    required int stars,
    required int movesCount,
    required int multiplier,
    String? sessionId,
  }) async {
    final int coinsEarned = levelNumber * multiplier;
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$_waterSortUrl/complete-level'),
        headers: headers,
        body: json.encode({
          'levelNumber': levelNumber,
          'stars': stars,
          'movesCount': movesCount,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error claiming water sort level reward via v1: $e');
    }

    try {
      if (sessionId != null && sessionId.isNotEmpty) {
        await UserService().endGameSession(sessionId, coinsEarned: coinsEarned);
      }
    } catch (e) {
      debugPrint('Error ending game session fallback: $e');
    }

    return {
      'success': true,
      'coinsEarned': coinsEarned,
      'newUnlockedLevel': levelNumber + 1,
    };
  }

  int max(int a, int b) => a > b ? a : b;
}
