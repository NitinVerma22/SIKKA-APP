import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? bannerUrl;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.bannerUrl,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? '',
      type: json['type'] ?? 'alert',
      isRead: json['isRead'] ?? false,
      bannerUrl: json['bannerUrl'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class NotificationState {
  final List<NotificationItem> notifications;
  final bool isLoading;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  NotificationNotifier() : super(NotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/auth', '')}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> items = data['notifications'];
          final notifications = items.map((e) => NotificationItem.fromJson(e)).toList();
          state = state.copyWith(notifications: notifications, isLoading: false);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await AuthService().logout();
        state = state.copyWith(notifications: [], isLoading: false);
      }
    } catch (e) {
      print('Fetch notifications error: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String? notificationId) async {
    try {
      // Optimistic update
      if (notificationId != null) {
        state = state.copyWith(
          notifications: state.notifications.map((n) {
            return n.id == notificationId ? NotificationItem(
              id: n.id, title: n.title, body: n.body, type: n.type, bannerUrl: n.bannerUrl, createdAt: n.createdAt, isRead: true,
            ) : n;
          }).toList(),
        );
      } else {
        state = state.copyWith(
          notifications: state.notifications.map((n) {
            return NotificationItem(
              id: n.id, title: n.title, body: n.body, type: n.type, bannerUrl: n.bannerUrl, createdAt: n.createdAt, isRead: true,
            );
          }).toList(),
        );
      }

      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/auth', '')}/notifications/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (notificationId != null) 'notificationId': notificationId,
        }),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await AuthService().logout();
      }
    } catch (e) {
      print('Mark read error: $e');
      fetchNotifications(); // Revert on failure
    }
  }

  Future<void> clearAll() async {
    try {
      state = state.copyWith(notifications: []);
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl.replaceAll('/auth', '')}/notifications/clear'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await AuthService().logout();
      }
    } catch (e) {
      print('Clear notifications error: $e');
      fetchNotifications();
    }
  }
  
  // For dummy testing locally
  void addDummyNotification(String title, String body) {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: 'alert',
      isRead: false,
      bannerUrl: null,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(notifications: [newItem, ...state.notifications]);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
