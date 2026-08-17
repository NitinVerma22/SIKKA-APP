import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class WaterSortAudioService {
  static final WaterSortAudioService instance = WaterSortAudioService._internal();
  WaterSortAudioService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isMuted = false;

  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgmPlayer.pause();
    } else {
      _bgmPlayer.resume();
    }
  }

  Future<void> playPourSfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/water_sort/sfx_copo-agua.mp3'));
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
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/water_sort/sfx_copo-cheio.mp3'));
    } catch (e) {
      debugPrint('Error playing bottle complete sfx: $e');
    }
  }

  Future<void> playVictorySfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/water_sort/sfx_garrafa-enchendo.mp3'));
    } catch (e) {
      debugPrint('Error playing victory sfx: $e');
    }
  }

  Future<void> startBgm() async {
    if (_isMuted) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('audio/water_sort/bgm_calm4.mp3'), volume: 0.3);
    } catch (e) {
      debugPrint('Error starting bgm: $e');
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping bgm: $e');
    }
  }
}
