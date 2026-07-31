import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:sikkaplay/main.dart';
import 'package:sikkaplay/routes/app_router.dart';

class UserService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Centralized request wrapper to handle auth headers & check account suspensions (403)
  Future<http.Response> _sendRequest(String method, String path, {Map<String, dynamic>? body, Map<String, String>? extraHeaders, String? overrideUrl}) async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) throw Exception('No token found');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    final urlStr = overrideUrl ?? '${AuthService.baseUrl.replaceAll('/auth', '/user')}$path';
    final uri = Uri.parse(urlStr);
    
    http.Response response;
    if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    } else if (method == 'PUT') {
      response = await http.put(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    } else {
      response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
    }

    if (response.statusCode == 403) {
      try {
        final Map<String, dynamic> bodyJson = jsonDecode(response.body);
        if (bodyJson['isVpnBlocked'] == true) {
          rootNavigatorKey.currentState?.context.go('/vpn_blocked');
          return response;
        }
      } catch (_) {}
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      // Clear token to log the user out
      await AuthService().logout();
      
      // Dismiss all dialogs/overlays first to prevent overlay stack locks
      final navigator = rootNavigatorKey.currentState;
      if (navigator != null) {
        while (navigator.canPop()) {
          navigator.pop();
        }
      }

      String errorMessage = response.statusCode == 403
          ? 'Your account has been suspended.'
          : 'Session expired. Please log in again.';
      try {
        errorMessage = jsonDecode(response.body)['error'] ?? errorMessage;
      } catch (_) {}

      // Display SnackBar
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                response.statusCode == 403 ? Icons.block_rounded : Icons.logout_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Force navigate back to Login
      rootNavigatorKey.currentState?.context.go('/login');
    }

    return response;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _sendRequest('GET', '/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'];
      }
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<String?> updateProfilePicture(String base64Image) async {
    try {
      final response = await _sendRequest(
        'PUT',
        '/avatar',
        body: {'imageBase64': base64Image},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['avatarUrl'] as String?;
      }
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Error updating profile picture: $e');
      throw Exception(e.toString());
    }
  }

  Future<String?> startGameSession(String gameType) async {
    try {
      final response = await _sendRequest(
        'POST',
        '/start',
        body: {'gameType': gameType},
        overrideUrl: '${AuthService.baseUrl.replaceAll('/auth', '/game')}/start',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['sessionId'] as String?;
      }
      return null;
    } catch (e) {
      print('Error starting game session: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> startSpinSession() async {
    try {
      final response = await _sendRequest(
        'POST',
        '/start',
        body: {'gameType': 'spin'},
        overrideUrl: '${AuthService.baseUrl.replaceAll('/auth', '/game')}/start',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error starting spin session: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> spinWheel(String sessionId) async {
    try {
      final response = await _sendRequest(
        'POST',
        '/spin',
        body: {'sessionId': sessionId},
        overrideUrl: '${AuthService.baseUrl.replaceAll('/auth', '/game')}/spin',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error spinning wheel: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> recordSpinAd(String sessionId) async {
    try {
      final response = await _sendRequest(
        'POST',
        '/spin-ad',
        body: {'sessionId': sessionId},
        overrideUrl: '${AuthService.baseUrl.replaceAll('/auth', '/game')}/spin-ad',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error recording spin ad: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> endGameSession(String sessionId, {int coinsEarned = 0, int bypassFee = 0}) async {
    try {
      final response = await _sendRequest(
        'POST',
        '/end',
        body: {
          'sessionId': sessionId,
          'coinsEarned': coinsEarned,
          if (bypassFee > 0) 'bypassFee': bypassFee,
        },
        overrideUrl: '${AuthService.baseUrl.replaceAll('/auth', '/game')}/end',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error ending game session: $e');
      return null;
    }
  }

  Future<bool> claimDailyStreak() async {
    try {
      final response = await _sendRequest('POST', '/earn/daily-streak', body: {});
      return response.statusCode == 200;
    } catch (e) {
      print('Error claiming daily streak: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> resumeDailyStreak() async {
    try {
      final response = await _sendRequest('POST', '/earn/daily-streak/resume', body: {});
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error resuming daily streak: $e');
      return null;
    }
  }

  Future<bool> claimSocialTask(String platform) async {
    try {
      final response = await _sendRequest('POST', '/earn/social-task', body: {'platform': platform});
      return response.statusCode == 200;
    } catch (e) {
      print('Error claiming social task: $e');
      return false;
    }
  }

  Future<bool> claimDynamicSocialTask(String taskId) async {
    try {
      final response = await _sendRequest('POST', '/social-tasks/$taskId/claim', body: {});
      return response.statusCode == 200;
    } catch (e) {
      print('Error claiming dynamic social task: $e');
      return false;
    }
  }

  Future<bool> claimSurvey(String title, String provider) async {
    try {
      final response = await _sendRequest('POST', '/earn/survey', body: {'title': title, 'provider': provider});
      return response.statusCode == 200;
    } catch (e) {
      print('Error claiming survey: $e');
      return false;
    }
  }

  Future<bool> claimAppInstall(String offerId) async {
    try {
      final response = await _sendRequest('POST', '/earn/app-install', body: {'offerId': offerId});
      return response.statusCode == 200;
    } catch (e) {
      print('Error claiming app install: $e');
      return false;
    }
  }

  Future<bool> claimMilestone(String type, int minutes) async {
    try {
      final response = await _sendRequest('POST', '/earn/milestone', body: {'type': type, 'minutes': minutes});
      return response.statusCode == 200;
    } catch (e) {
      print('Error claiming milestone: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getHomeState() async {
    try {
      final response = await _sendRequest('GET', '/home');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching home state: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMyNetwork() async {
    try {
      final response = await _sendRequest('GET', '/network');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching my network: $e');
      return null;
    }
  }

  Future<bool> logUsage(int minutes, {String type = 'reels'}) async {
    try {
      final response = await _sendRequest('POST', '/usage', body: {
        'minutes': minutes,
        'type': type,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('Error logging usage: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getWalletStats() async {
    try {
      final response = await _sendRequest('GET', '/wallet');
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['stats'];
      }
      return null;
    } catch (e) {
      print('Error fetching wallet stats: $e');
      return null;
    }
  }

  Future<bool> updateFcmToken(String token) async {
    try {
      final response = await _sendRequest('POST', '/fcm-token', body: {
        'token': token,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getTransactions(int page, {int limit = 20}) async {
    try {
      final response = await _sendRequest('GET', '/transactions?page=$page&limit=$limit');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching transactions: $e');
      return null;
    }
  }

  Future<bool> updateUpi(String upiId) async {
    try {
      final response = await _sendRequest('PUT', '/upi', body: {
        'upiId': upiId,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating UPI: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> updateProfileDetails({String? name, String? username, String? gender, String? city}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (username != null) body['username'] = username;
      if (gender != null) body['gender'] = gender;
      if (city != null) body['city'] = city;
      final response = await _sendRequest('PUT', '/update-details', body: body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, ...data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> requestWithdrawal(int coinsAmount, String upiId, {String earningType = 'self'}) async {
    final response = await _sendRequest('POST', '/withdraw', body: {
      'amount': coinsAmount,
      'upiId': upiId,
      'earningType': earningType,
    });
    
    if (response.statusCode == 200) {
      return true;
    } else {
      try {
        final data = jsonDecode(response.body);
        if (data['error'] == 'PHONE_VERIFICATION_REQUIRED') {
          throw Exception('PHONE_VERIFICATION_REQUIRED');
        }
      } catch (e) {
        if (e.toString().contains('PHONE_VERIFICATION_REQUIRED')) rethrow;
      }
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getVisitLinks() async {
    try {
      final response = await _sendRequest('GET', '/visit-links');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['links'] != null) {
          return List<Map<String, dynamic>>.from(data['links']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching visit links: $e');
      return null;
    }
  }

  Future<bool> claimVisitLink(String linkId) async {
    try {
      final response = await _sendRequest('POST', '/visit-links/claim', body: {
        'linkId': linkId,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('Error claiming visit link: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLeaderboard() async {
    try {
      final response = await _sendRequest('GET', '/leaderboard');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return null;
    }
  }

  Future<bool> recordAdImpression(String adType, String adNetwork, {int coinsAwarded = 0, String? externalTxId}) async {
    try {
      final response = await _sendRequest(
        'POST',
        '/ad-impression',
        body: {
          'adType': adType,
          'adNetwork': adNetwork,
          'coinsAwarded': coinsAwarded,
          if (externalTxId != null) 'externalTxId': externalTxId,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error recording ad impression: $e');
      return false;
    }
  }
}

