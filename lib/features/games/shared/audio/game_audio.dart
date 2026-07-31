import 'package:audioplayers/audioplayers.dart';

class GameAudio {
  static final AudioPlayer _tickPlayer = AudioPlayer();
  static final AudioPlayer _winPlayer = AudioPlayer();
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _wrongPlayer = AudioPlayer();
  static bool _initialized = false;
  static DateTime _lastTickTime = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    await _tickPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _tickPlayer.setSource(AssetSource('audio/spin/tick.mp3'));

    await _winPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _winPlayer.setSource(AssetSource('audio/spin/win.mp3'));

    await _correctPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _correctPlayer.setSource(AssetSource('audio/spin/correct.mp3'));

    await _wrongPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _wrongPlayer.setSource(AssetSource('audio/spin/wrong.mp3'));
  }

  static Future<void> playTick() async {
    final now = DateTime.now();
    if (now.difference(_lastTickTime).inMilliseconds < 80) {
      return; // Rate limit tick sound to prevent platform-channel thread saturation
    }
    _lastTickTime = now;

    try {
      if (_tickPlayer.state == PlayerState.playing) {
        await _tickPlayer.stop();
      }
      await _tickPlayer.seek(Duration.zero);
      await _tickPlayer.resume();
    } catch (e) {
      // Ignore audio errors
    }
  }

  static Future<void> playWin() async {
    try {
      if (_winPlayer.state == PlayerState.playing) await _winPlayer.stop();
      await _winPlayer.seek(Duration.zero);
      await _winPlayer.resume();
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> playCorrect() async {
    try {
      if (_correctPlayer.state == PlayerState.playing) await _correctPlayer.stop();
      await _correctPlayer.seek(Duration.zero);
      await _correctPlayer.resume();
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> playWrong() async {
    try {
      if (_wrongPlayer.state == PlayerState.playing) await _wrongPlayer.stop();
      await _wrongPlayer.seek(Duration.zero);
      await _wrongPlayer.resume();
    } catch (e) {
      // Ignore
    }
  }

  static void dispose() {
    _tickPlayer.dispose();
    _winPlayer.dispose();
    _correctPlayer.dispose();
    _wrongPlayer.dispose();
  }
}
