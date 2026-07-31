import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';

final globalFriendsListProvider = StateProvider<List<dynamic>>((ref) => []);
final globalPendingRequestsProvider = StateProvider<List<dynamic>>((ref) => []);

class PlaygroundService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Helper to extract playground baseUrl
  String get _playgroundUrl => AuthService.baseUrl.replaceAll('/auth', '/playground');

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };
  }

  // GET Request Wrapper
  Future<http.Response> _get(String path) async {
    final uri = Uri.parse('$_playgroundUrl$path');
    final headers = await _getHeaders();
    return http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
  }

  // POST Request Wrapper
  Future<http.Response> _post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_playgroundUrl$path');
    final headers = await _getHeaders();
    return http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 10));
  }

  // 1. Fetch Lobby details
  Future<Map<String, dynamic>> getLobbyData() async {
    try {
      final res = await _get('/lobby');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 2. Swap Sikka Coins for minutes
  Future<Map<String, dynamic>> swapCoinsForMinutes(int minutes) async {
    try {
      final res = await _post('/swap-minutes', body: {'minutes': minutes});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 3. Check Username Uniqueness
  Future<Map<String, dynamic>> checkUsernameUnique(String username) async {
    try {
      final res = await _post('/username/check', body: {'username': username});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 4. Set unique username
  Future<Map<String, dynamic>> setUsername(String username) async {
    try {
      final res = await _post('/username/set', body: {'username': username});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 6. Claim playtime crate
  Future<Map<String, dynamic>> claimCrate(String crateLevel) async {
    try {
      final res = await _post('/crates/claim', body: {'crateLevel': crateLevel});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 7. Matchmaking join
  Future<Map<String, dynamic>> joinMatchmaking(String filter, String gender) async {
    try {
      final res = await _post('/matchmaking/join', body: {'filter': filter, 'gender': gender});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 8. Matchmaking status check
  Future<Map<String, dynamic>> checkMatchmakingStatus() async {
    try {
      final res = await _post('/matchmaking/status');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 9. Fetch Friends list
  Future<Map<String, dynamic>> getFriendsList() async {
    try {
      final res = await _get('/friends');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 10. Friends lookup search
  Future<Map<String, dynamic>> searchFriends(String query) async {
    try {
      final res = await _get('/friends/search?query=$query');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 11. Send Friend Request
  Future<Map<String, dynamic>> sendFriendRequest(String targetUserId) async {
    try {
      final res = await _post('/friends/request', body: {'targetUserId': targetUserId});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 12. Accept Friend Request
  Future<Map<String, dynamic>> acceptFriendRequest(String friendshipId) async {
    try {
      final res = await _post('/friends/accept', body: {'friendshipId': friendshipId});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 13. Send Virtual Gift
  Future<Map<String, dynamic>> sendVirtualGift(String receiverId, String giftName) async {
    try {
      final res = await _post('/gifts/send', body: {'receiverId': receiverId, 'giftName': giftName});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 14. Sell Virtual Gift
  Future<Map<String, dynamic>> sellVirtualGift(String giftId) async {
    try {
      final res = await _post('/gifts/sell', body: {'giftId': giftId});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 15. Submit Report
  Future<Map<String, dynamic>> reportUser(String reportedUserId, String reason) async {
    try {
      final res = await _post('/report', body: {'reportedUserId': reportedUserId, 'reason': reason});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 16. Send Chat Message
  Future<Map<String, dynamic>> sendPlaygroundMessage(String channelName, String text, {String? recipientId}) async {
    try {
      final res = await _post('/chat/send', body: {
        'channelName': channelName,
        'text': text,
        if (recipientId != null) 'recipientId': recipientId,
      });
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 17. Sync Chat Messages
  Future<Map<String, dynamic>> syncPlaygroundMessages(String channelName, {String? recipientId, bool history = false}) async {
    try {
      final recipientParam = recipientId != null ? '&recipientId=$recipientId' : '';
      final historyParam = history ? '&history=true' : '';
      final res = await _get('/chat/sync?channelName=$channelName$recipientParam$historyParam');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 18. Update Bio
  Future<Map<String, dynamic>> updateBio(String bio) async {
    try {
      final res = await _post('/profile/bio', body: {'bio': bio});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 19. Get Public Profile
  Future<Map<String, dynamic>> getPublicProfile(String username) async {
    try {
      final res = await _get('/profile/search?username=$username');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 20. Update Active Channel Heartbeat
  Future<Map<String, dynamic>> updateActiveChannel(String? channelName, {String? recipientId}) async {
    try {
      final res = await _post('/chat/active', body: {
        'channelName': channelName,
        if (recipientId != null) 'recipientId': recipientId,
      });
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 21. Unfriend User
  Future<Map<String, dynamic>> unfriendUser(String targetUserId) async {
    try {
      final res = await _post('/friends/unfriend', body: {'targetUserId': targetUserId});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 22. Clear Chat History
  Future<Map<String, dynamic>> clearChatHistory(String recipientId) async {
    try {
      final res = await _post('/chat/clear', body: {'recipientId': recipientId});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 23. Set typing status
  Future<Map<String, dynamic>> setTypingStatus(String channelName, bool isTyping, {String? recipientId}) async {
    try {
      final res = await _post('/chat/typing', body: {
        'channelName': channelName,
        'isTyping': isTyping,
        if (recipientId != null) 'recipientId': recipientId,
      });
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': jsonDecode(res.body)['error'] ?? 'Server error'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Block User APIs ---
  Future<Map<String, dynamic>> blockUser(String targetUserId) async {
    try {
      final res = await _post('/block', body: {'targetUserId': targetUserId});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': (jsonDecode(res.body)['error'] ?? 'Server error')};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> unblockUser(String targetUserId) async {
    try {
      final res = await _post('/unblock', body: {'targetUserId': targetUserId});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': (jsonDecode(res.body)['error'] ?? 'Server error')};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBlockedUsers() async {
    try {
      final res = await _get('/blocked');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'error': (jsonDecode(res.body)['error'] ?? 'Server error')};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }



}
