import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/features/reels/webview/reels_webview.dart';
import 'package:sikkaplay/features/reels/providers/reels_provider.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  Timer? _gullakTimer;
  int _elapsedSeconds = 0;
  int _inactivitySeconds = 0;
  final int _targetSeconds = 300; // 5 minutes
  bool _hasShownLoginPopup = false;

  @override
  void initState() {
    super.initState();
    _elapsedSeconds = ref.read(reelsProvider).elapsedSeconds;
    _startTimer();
  }

  void _startTimer() {
    _gullakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      // Pause earning if user is not on the reels page (e.g., login page or normal feed)
      final currentUrl = ref.read(reelsProvider).currentUrl;
      if (!currentUrl.contains('/reels/')) {
        if ((currentUrl.contains('accounts/login') || currentUrl.contains('challenge')) && !_hasShownLoginPopup) {
          _hasShownLoginPopup = true;
          _showLoginEducationalPopup();
        }
        return; 
      }
      
      if (_elapsedSeconds < _targetSeconds) {
        setState(() {
          _inactivitySeconds++;
          if (_inactivitySeconds < 90) {
            _elapsedSeconds++;
            ref.read(reelsProvider.notifier).setElapsedSeconds(_elapsedSeconds);
            // Increment reels watched time in home provider every 60 active seconds
            if (_elapsedSeconds > 0 && _elapsedSeconds % 60 == 0) {
              // ref.read(homeProvider.notifier).incrementReelsTime();
            }
          }
        });
      }
    });
  }

  void _resetInactivity() {
    if (_inactivitySeconds >= 90) {
      GameNotifications.showCoinUpdate(context, 'Earnings Resumed!');
    }
    setState(() {
      _inactivitySeconds = 0;
    });
  }

  void _showLoginEducationalPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Log In to Instagram', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Logging in unlocks the best Reels experience:', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 10),
            Text('✨ Get a personalized feed', style: TextStyle(color: Colors.white)),
            Text('📤 Share reels directly with friends', style: TextStyle(color: Colors.white)),
            Text('❤️ Like and save your favorites', style: TextStyle(color: Colors.white)),
            SizedBox(height: 20),
            Text('🔒 Privacy Assured:', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            Text('Your login is completely secure and handled directly by Instagram. SikkaPlay cannot access your password or data.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gullakTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Listener(
        onPointerDown: (_) => _resetInactivity(),
        onPointerMove: (_) => _resetInactivity(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: const ReelsWebView(),
          ),
        ),
      ),
    );
  }
}
