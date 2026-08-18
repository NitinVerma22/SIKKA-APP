import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class ArrowEscapeAudioService {
  static final ArrowEscapeAudioService instance = ArrowEscapeAudioService._internal();
  ArrowEscapeAudioService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isMuted = false;

  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
  }

  Future<void> playTapSfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/spin/tick.mp3'), volume: 0.4);
    } catch (e) {
      debugPrint('Error playing tap sfx: $e');
    }
  }

  Future<void> playEscapeSfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/spin/tick.mp3'), volume: 0.7);
    } catch (e) {
      debugPrint('Error playing escape sfx: $e');
    }
  }

  Future<void> playCollisionSfx() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/spin/tick.mp3'), volume: 0.3);
    } catch (e) {
      debugPrint('Error playing collision sfx: $e');
    }
  }
}
