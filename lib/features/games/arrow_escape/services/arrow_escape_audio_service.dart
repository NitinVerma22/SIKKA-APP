import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class ArrowEscapeAudioService {
  static final ArrowEscapeAudioService instance = ArrowEscapeAudioService._internal();
  ArrowEscapeAudioService._internal();

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

  Future<void> playLaunchSfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/water_sort/sfx_copo-curto.mp3'));
    } catch (e) {
      debugPrint('Error playing launch sfx: $e');
    }
  }

  Future<void> playEscapeSfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/water_sort/sfx_garrafa-enchendo.mp3'));
    } catch (e) {
      debugPrint('Error playing escape sfx: $e');
    }
  }

  Future<void> playCollisionSfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/spin/tick.mp3'));
    } catch (e) {
      debugPrint('Error playing collision sfx: $e');
    }
  }

  Future<void> startBgm() async {
    if (_isMuted) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('audio/water_sort/bgm_calm4.mp3'), volume: 0.2);
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
