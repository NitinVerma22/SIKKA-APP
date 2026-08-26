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
    await _winPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _correctPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _wrongPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  static Future<void> playTick() async {
    final now = DateTime.now();
    if (now.difference(_lastTickTime).inMilliseconds < 80) {
      return; // Rate limit tick sound
    }
    _lastTickTime = now;

    try {
      if (_tickPlayer.state == PlayerState.playing) await _tickPlayer.stop();
      await _tickPlayer.play(AssetSource('audio/spin/spin_tick.mp3'));
    } catch (e) {
      // Ignore audio errors
    }
  }

  static Future<void> playWin() async {
    try {
      if (_winPlayer.state == PlayerState.playing) await _winPlayer.stop();
      await _winPlayer.play(AssetSource('audio/spin/spin_win.mp3'));
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> playCorrect() async {
    try {
      if (_correctPlayer.state == PlayerState.playing) await _correctPlayer.stop();
      await _correctPlayer.play(AssetSource('audio/spin/correct.mp3'));
    } catch (e) {
      // Ignore
    }
  }

  static Future<void> playWrong() async {
    try {
      if (_wrongPlayer.state == PlayerState.playing) await _wrongPlayer.stop();
      await _wrongPlayer.play(AssetSource('audio/arrow_escape/game_wrong.mp3'));
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
