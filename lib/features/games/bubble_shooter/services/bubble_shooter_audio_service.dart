import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class BubbleShooterAudioService {
  static final BubbleShooterAudioService instance = BubbleShooterAudioService._internal();
  BubbleShooterAudioService._internal();

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

  Future<void> playShootSfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/bubble_shooter/shoot.mp3'));
    } catch (e) {
      debugPrint('Error playing shoot sfx: $e');
    }
  }

  Future<void> playPopSfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/bubble_shooter/destroy.wav'));
    } catch (e) {
      debugPrint('Error playing pop sfx: $e');
    }
  }

  Future<void> playExplosionSfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/bubble_shooter/explosion.wav'));
    } catch (e) {
      debugPrint('Error playing explosion sfx: $e');
    }
  }

  Future<void> startBgm() async {
    if (_isMuted) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('audio/bubble_shooter/background.mp3'), volume: 0.25);
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
