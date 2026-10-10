import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/auth/auth_service.dart';
import '../models/tournament_models.dart';

class TournamentJoinResult {
  final bool success;
  final String message;
  final UserParticipation? participant;
  final int? remainingCoins;

  const TournamentJoinResult({
    required this.success,
    required this.message,
    this.participant,
    this.remainingCoins,
  });
}

class TournamentService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // In-memory ETag & response cache to conserve client egress & compute
  final Map<String, String> _eTags = {};
  final Map<String, dynamic> _cachedResponses = {};

  String get _baseUrl => AuthService.baseUrl.replaceAll('/auth', '/v1/tournaments');

  Future<Map<String, String>> _getHeaders({String? cacheKey}) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };
    if (cacheKey != null && _eTags.containsKey(cacheKey)) {
      headers['If-None-Match'] = _eTags[cacheKey]!;
    }
    return headers;
  }

  /// Fetches tournaments filtered by status
  Future<List<Tournament>> getTournaments({TournamentStatus? status, int page = 1, int limit = 20}) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) {
        queryParams['status'] = status.toDbString();
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final cacheKey = 'list_${status?.name ?? "all"}_$page';
      final headers = await _getHeaders(cacheKey: cacheKey);

      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 304 && _cachedResponses.containsKey(cacheKey)) {
        final cached = _cachedResponses[cacheKey] as List<Tournament>;
        return cached;
      }

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['tournaments'] is List) {
          final list = (data['tournaments'] as List)
              .map((t) => Tournament.fromJson(t as Map<String, dynamic>))
              .toList();

          if (res.headers['etag'] != null) {
            _eTags[cacheKey] = res.headers['etag']!;
            _cachedResponses[cacheKey] = list;
          }
          return list;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching tournaments: $e');
      return [];
    }
  }

  /// Fetches tournaments the current user has joined
  Future<List<Tournament>> getMyTournaments({int page = 1, int limit = 20}) async {
    try {
      final uri = Uri.parse('$_baseUrl/my').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      final headers = await _getHeaders();

      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['tournaments'] is List) {
          return (data['tournaments'] as List)
              .map((t) => Tournament.fromJson(t as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my tournaments: $e');
      return [];
    }
  }

  /// Fetches single tournament details
  Future<Tournament?> getTournamentDetails(String tournamentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$tournamentId');
      final headers = await _getHeaders();

      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && data['tournament'] != null) {
          return Tournament.fromJson(data['tournament'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching tournament details: $e');
      return null;
    }
  }

  /// Joins a tournament (Ad watched for FREE, Coins deducted for PAID_COINS)
  Future<TournamentJoinResult> joinTournament(String tournamentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$tournamentId/join');
      final headers = await _getHeaders();

      final res = await http.post(uri, headers: headers).timeout(const Duration(seconds: 10));
      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        // Clear caches to force fresh refresh
        _eTags.clear();
        _cachedResponses.clear();

        UserParticipation? p;
        if (data['participant'] != null) {
          p = UserParticipation.fromJson(data['participant'] as Map<String, dynamic>);
        }

        return TournamentJoinResult(
          success: true,
          message: data['message']?.toString() ?? 'Joined tournament successfully!',
          participant: p,
          remainingCoins: (data['remainingCoins'] as num?)?.toInt(),
        );
      } else {
        return TournamentJoinResult(
          success: false,
          message: data['error']?.toString() ?? 'Failed to join tournament.',
        );
      }
    } catch (e) {
      debugPrint('Error joining tournament: $e');
      return const TournamentJoinResult(
        success: false,
        message: 'Network error joining tournament. Please try again.',
      );
    }
  }

  /// Fetches real-time cached leaderboard with pinned user rank
  Future<TournamentLeaderboardData?> getLeaderboard(String tournamentId, {int page = 1, int limit = 50}) async {
    try {
      final uri = Uri.parse('$_baseUrl/$tournamentId/leaderboard').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final cacheKey = 'lb_${tournamentId}_$page';
      final headers = await _getHeaders(cacheKey: cacheKey);

      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 304 && _cachedResponses.containsKey(cacheKey)) {
        return _cachedResponses[cacheKey] as TournamentLeaderboardData;
      }

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final lbData = TournamentLeaderboardData.fromJson(data as Map<String, dynamic>);
          if (res.headers['etag'] != null) {
            _eTags[cacheKey] = res.headers['etag']!;
            _cachedResponses[cacheKey] = lbData;
          }
          return lbData;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return null;
    }
  }
}
