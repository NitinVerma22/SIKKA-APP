import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioHapticHelper {
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  static final AudioPlayer _successPlayer = AudioPlayer();
  static final AudioPlayer _collisionPlayer = AudioPlayer();
  static final AudioPlayer _lifelinePlayer = AudioPlayer();
  static final AudioPlayer _levelCompletePlayer = AudioPlayer();

  static bool _initialized = false;

  static Future<void> _initAudio() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _successPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _collisionPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _lifelinePlayer.setPlayerMode(PlayerMode.lowLatency);
      await _levelCompletePlayer.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Error initializing Arrow Escape audio: $e');
    }
  }

  static Future<void> playClick() async {
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> playSuccess() async {
    if (soundEnabled) {
      try {
        await _successPlayer.stop();
        await _successPlayer.play(AssetSource('audio/arrow_escape/arrow_success.mp3'));
      } catch (e) {
        debugPrint('Error playing success audio: $e');
      }
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> playCollision() async {
    if (soundEnabled) {
      try {
        await _collisionPlayer.stop();
        await _collisionPlayer.play(AssetSource('audio/arrow_escape/arrow_collision.mp3'));
      } catch (e) {
        debugPrint('Error playing collision audio: $e');
      }
    }
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> playFailure() async {
    if (soundEnabled) {
      try {
        await _lifelinePlayer.stop();
        await _lifelinePlayer.play(AssetSource('audio/arrow_escape/arrow_lifeline.mp3'));
      } catch (e) {
        debugPrint('Error playing failure audio: $e');
      }
    }
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> playLevelComplete() async {
    if (soundEnabled) {
      try {
        await _levelCompletePlayer.stop();
        await _levelCompletePlayer.play(AssetSource('audio/arrow_escape/arrow_level_complete.mp3'));
      } catch (e) {
        debugPrint('Error playing level complete audio: $e');
      }
    }
    if (hapticsEnabled) {
      await HapticFeedback.vibrate();
    }
  }
}
