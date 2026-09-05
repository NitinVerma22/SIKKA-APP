import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AudioHapticHelper {
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  static Future<void> playClick() async {
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> playSuccess() async {
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> playCollision() async {
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> playFailure() async {
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> playLevelComplete() async {
    if (hapticsEnabled) {
      await HapticFeedback.vibrate();
    }
  }
}
