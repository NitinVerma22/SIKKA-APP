import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:sikkaplay/features/games/shared/audio/game_audio.dart';

class WaterSortAudioService {
  static final WaterSortAudioService instance = WaterSortAudioService._internal();
  WaterSortAudioService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool get isMuted => GameAudio.isMuted.value;

  void toggleMute() {
    GameAudio.toggleMute();
    if (GameAudio.isMuted.value) {
      _bgmPlayer.pause();
    } else {
      _bgmPlayer.resume();
    }
  }

  Future<void> playPourSfx() async {
    if (isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setReleaseMode(ReleaseMode.loop);
      await _sfxPlayer.play(AssetSource('audio/water_sort/water_pour.mp3'));
    } catch (e) {
      debugPrint('Error playing pour sfx: $e');
    }
  }

  Future<void> stopPourSfx() async {
    try {
      await _sfxPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping pour sfx: $e');
    }
  }

  Future<void> playBottleCompleteSfx() async {
    // Deleted
  }

  Future<void> playVictorySfx() async {
    // Deleted
  }

  Future<void> startBgm() async {
    // Deleted
  }

  Future<void> stopBgm() async {
    // Deleted
  }
}
