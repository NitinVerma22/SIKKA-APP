import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/user/user_service.dart';

class BubbleShooterProgress {
  final int maxUnlockedLevel;
  final Map<int, int> starsMap;
  final int multiplier;

  BubbleShooterProgress({
    required this.maxUnlockedLevel,
    required this.starsMap,
    required this.multiplier,
  });
}

class BubbleShooterService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String get _bubbleShooterUrl => AuthService.baseUrl.replaceAll('/auth', '/v1/bubble-shooter');

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };
  }

  Future<BubbleShooterProgress> loadProgress() async {
    int maxLevel = 1;
    Map<int, int> stars = {};
    int multiplier = 2;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('sikkaplay_bubble_shooter_progress');
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

      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$_bubbleShooterUrl/progress'),
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
          await saveLocalProgress(maxLevel, stars);
        }
      }
    } catch (e) {
      debugPrint('[BubbleShooterService] Load progress fallback: $e');
    }

    return BubbleShooterProgress(
      maxUnlockedLevel: maxLevel,
      starsMap: stars,
      multiplier: multiplier,
    );
  }

  Future<void> saveLocalProgress(int maxLevel, Map<int, int> stars) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {
        'maxUnlockedLevel': maxLevel,
        'stars': stars.map((k, v) => MapEntry(k.toString(), v)),
      };
      await prefs.setString('sikkaplay_bubble_shooter_progress', json.encode(data));
    } catch (e) {
      debugPrint('Error saving local bubble shooter progress: $e');
    }
  }

  Future<Map<String, dynamic>> claimLevelReward({
    required int levelNumber,
    required int stars,
    required int score,
    String? sessionId,
  }) async {
    final int coinsEarned = levelNumber <= 25 ? levelNumber * 2 : levelNumber + 25;
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$_bubbleShooterUrl/complete-level'),
        headers: headers,
        body: json.encode({
          'levelNumber': levelNumber,
          'stars': stars,
          'score': score,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error claiming bubble shooter reward via v1: $e');
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
