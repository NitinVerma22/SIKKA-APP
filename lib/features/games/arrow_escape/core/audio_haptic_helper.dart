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
      await _successPlayer.setSource(AssetSource('audio/Arrow sound/Arrow Escape game mai jab user arrows ko shi nikale tab.mp3'));

      await _collisionPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _collisionPlayer.setSource(AssetSource('audio/Arrow sound/Arrow Escape mai jab user galat arrow ko exit de ya jab arrow apas mai takraye.mp3'));

      await _lifelinePlayer.setPlayerMode(PlayerMode.lowLatency);
      await _lifelinePlayer.setSource(AssetSource('audio/Arrow sound/Arror Escape game mai lifeline kam hone p.mp3'));

      await _levelCompletePlayer.setPlayerMode(PlayerMode.lowLatency);
      await _levelCompletePlayer.setSource(AssetSource('audio/Arrow sound/Arrow Escape mai jab user level complete kr le tab .mp3'));
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
      await _initAudio();
      try {
        if (_successPlayer.state == PlayerState.playing) await _successPlayer.stop();
        await _successPlayer.seek(Duration.zero);
        await _successPlayer.resume();
      } catch (_) {}
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> playCollision() async {
    if (soundEnabled) {
      await _initAudio();
      try {
        if (_collisionPlayer.state == PlayerState.playing) await _collisionPlayer.stop();
        await _collisionPlayer.seek(Duration.zero);
        await _collisionPlayer.resume();
      } catch (_) {}
    }
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> playFailure() async {
    if (soundEnabled) {
      await _initAudio();
      try {
        if (_lifelinePlayer.state == PlayerState.playing) await _lifelinePlayer.stop();
        await _lifelinePlayer.seek(Duration.zero);
        await _lifelinePlayer.resume();
      } catch (_) {}
    }
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> playLevelComplete() async {
    if (soundEnabled) {
      await _initAudio();
      try {
        if (_levelCompletePlayer.state == PlayerState.playing) await _levelCompletePlayer.stop();
        await _levelCompletePlayer.seek(Duration.zero);
        await _levelCompletePlayer.resume();
      } catch (_) {}
    }
    if (hapticsEnabled) {
      await HapticFeedback.vibrate();
    }
  }
}
