import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';

class UsageTrackerService extends WidgetsBindingObserver {
  Timer? _timer;
  final AuthService _authService = AuthService();
  
  // Track 5 minutes of usage per ping
  static const int pingIntervalMinutes = 5;

  void startTracking() {
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void stopTracking() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: pingIntervalMinutes), (timer) {
      _pingBackend();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _stopTimer();
    }
  }

  Future<void> _pingBackend() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;
      
      // We will make a POST request to /api/user/usage
      await _authService.post('/user/usage', {
        'minutes': pingIntervalMinutes,
      });
      debugPrint('Usage ping sent: $pingIntervalMinutes minutes');
    } catch (e) {
      debugPrint('Failed to ping usage: $e');
    }
  }
}

// Global instance to manage tracking
final usageTrackerService = UsageTrackerService();
