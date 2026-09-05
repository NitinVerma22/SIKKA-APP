import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:sikkaplay/features/games/shared/audio/game_audio.dart';

class BubbleShooterAudioService {
  static final BubbleShooterAudioService instance = BubbleShooterAudioService._internal();
  
  final AudioPlayer _shootPlayer = AudioPlayer();
  final AudioPlayer _popPlayer = AudioPlayer();
  final AudioPlayer _explosionPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  BubbleShooterAudioService._internal();

  bool get isMuted => GameAudio.isMuted.value;

  void toggleMute() {
    GameAudio.toggleMute();
    if (GameAudio.isMuted.value) {
      _bgmPlayer.pause();
    } else {
      _bgmPlayer.resume();
    }
  }

  Future<void> playShootSfx() async {
    if (isMuted) return;
    try {
      await _shootPlayer.stop();
      await _shootPlayer.play(AssetSource('audio/bubble_shooter/shoot.mp3'));
    } catch (e) {
      debugPrint('Error playing shoot sfx: $e');
    }
  }

  Future<void> playPopSfx() async {
    if (isMuted) return;
    try {
      await _popPlayer.stop();
      await _popPlayer.play(AssetSource('audio/bubble_shooter/destroy.wav'));
    } catch (e) {
      debugPrint('Error playing pop sfx: $e');
    }
  }

  Future<void> playExplosionSfx() async {
    if (isMuted) return;
    try {
      await _explosionPlayer.stop();
      await _explosionPlayer.play(AssetSource('audio/bubble_shooter/explosion.wav'));
    } catch (e) {
      debugPrint('Error playing explosion sfx: $e');
    }
  }

  Future<void> startBgm() async {
    if (isMuted) return;
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
