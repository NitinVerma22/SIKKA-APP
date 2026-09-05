import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameAudio {
  static final ValueNotifier<bool> isMuted = ValueNotifier<bool>(false);

  static Future<void> toggleMute() async {
    isMuted.value = !isMuted.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_audio_muted', isMuted.value);
    
    if (isMuted.value) {
      _startPlayer.stop();
      _stopPlayer.stop();
      _rewardPlayer.stop();
      _sikkaPlayer.stop();
      _treasureBombPlayer.stop();
      _treasureCoinPlayer.stop();
      _treasureBlockShowPlayer.stop();
      _treasureBlockHidePlayer.stop();
      _emojiShowPlayer.stop();
      _emojiHidePlayer.stop();
      _emojiRewardPlayer.stop();
      _emojiWrongPlayer.stop();
      _emojiTapPlayer.stop();
      _mathWrongPlayer.stop();
      _mathCoinDropPlayer.stop();
      _mathCorrectPlayer.stop();
      _mathClaimPlayer.stop();
      _mathSikkaEarnedPlayer.stop();
    }
  }

  static final AudioPlayer _startPlayer = AudioPlayer();
  static final AudioPlayer _stopPlayer = AudioPlayer();
  static final AudioPlayer _rewardPlayer = AudioPlayer();
  static final AudioPlayer _sikkaPlayer = AudioPlayer();

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isMuted.value = prefs.getBool('is_audio_muted') ?? false;

    final players = [
      _startPlayer, _stopPlayer, _rewardPlayer, _sikkaPlayer,
      _treasureBombPlayer, _treasureCoinPlayer, _treasureBlockShowPlayer, _treasureBlockHidePlayer,
      _emojiShowPlayer, _emojiHidePlayer, _emojiRewardPlayer, _emojiWrongPlayer, _emojiTapPlayer,
      _mathWrongPlayer, _mathCoinDropPlayer, _mathCorrectPlayer, _mathClaimPlayer, _mathSikkaEarnedPlayer
    ];
    
    await AudioPlayer.global.setAudioContext(AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
      route: AudioContextConfigRoute.system,
      respectSilence: true,
    ).build());

    for (var player in players) {
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
    }
  }

  static Future<void> playSpinStart() async {
    if (isMuted.value) return;
    try {
      await _startPlayer.stop();
      await _startPlayer.play(AssetSource('audio/spin_wheel/spin_start.mp3'));
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  static Future<void> playSpinStop() async {
    if (isMuted.value) return;
    try {
      await _stopPlayer.stop();
      await _stopPlayer.play(AssetSource('audio/spin_wheel/spin_stop.mp3'));
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  static Future<void> playSpinReward() async {
    if (isMuted.value) return;
    try {
      await _rewardPlayer.stop();
      await _rewardPlayer.play(AssetSource('audio/spin_wheel/spin_reward.mp3'));
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  static Future<void> playSikkaEarned() async {
    if (isMuted.value) return;
    try {
      await _sikkaPlayer.stop();
      await _sikkaPlayer.play(AssetSource('audio/spin_wheel/sikka_earned.mp3'));
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  static final AudioPlayer _treasureBombPlayer = AudioPlayer();
  static final AudioPlayer _treasureCoinPlayer = AudioPlayer();
  static final AudioPlayer _treasureBlockShowPlayer = AudioPlayer();
  static final AudioPlayer _treasureBlockHidePlayer = AudioPlayer();

  // Treasure Grid Audios
  static Future<void> playTreasureBomb() async {
    if (isMuted.value) return;
    try {
      await _treasureBombPlayer.stop();
      await _treasureBombPlayer.play(AssetSource('audio/treasure_grid/bomb_click.mp3'));
    } catch (e) {}
  }

  static Future<void> playTreasureCoin() async {
    if (isMuted.value) return;
    try {
      await _treasureCoinPlayer.stop();
      await _treasureCoinPlayer.play(AssetSource('audio/treasure_grid/coin_reveal.mp3'));
    } catch (e) {}
  }

  static Future<void> playTreasureBlockShow() async {
    if (isMuted.value) return;
    try {
      await _treasureBlockShowPlayer.stop();
      await _treasureBlockShowPlayer.play(AssetSource('audio/treasure_grid/block_show.mp3'));
    } catch (e) {}
  }

  static Future<void> playTreasureBlockHide() async {
    if (isMuted.value) return;
    try {
      await _treasureBlockHidePlayer.stop();
      await _treasureBlockHidePlayer.play(AssetSource('audio/treasure_grid/block_hide.mp3'));
    } catch (e) {}
  }

  static final AudioPlayer _emojiShowPlayer = AudioPlayer();
  static final AudioPlayer _emojiHidePlayer = AudioPlayer();
  static final AudioPlayer _emojiRewardPlayer = AudioPlayer();
  static final AudioPlayer _emojiWrongPlayer = AudioPlayer();
  static final AudioPlayer _emojiTapPlayer = AudioPlayer();

  // Emoji Memory Audios
  static Future<void> playEmojiShow() async {
    if (isMuted.value) return;
    try {
      await _emojiShowPlayer.stop();
      await _emojiShowPlayer.play(AssetSource('audio/emoji_memory/emoji_show.mp3'));
    } catch (e) {}
  }

  static Future<void> playEmojiHide() async {
    if (isMuted.value) return;
    try {
      await _emojiHidePlayer.stop();
      await _emojiHidePlayer.play(AssetSource('audio/emoji_memory/emoji_hide.mp3'));
    } catch (e) {}
  }

  static Future<void> playEmojiReward() async {
    if (isMuted.value) return;
    try {
      await _emojiRewardPlayer.stop();
      await _emojiRewardPlayer.play(AssetSource('audio/emoji_memory/emoji_reward.mp3'));
    } catch (e) {}
  }

  static Future<void> playEmojiWrong() async {
    if (isMuted.value) return;
    try {
      await _emojiWrongPlayer.stop();
      await _emojiWrongPlayer.play(AssetSource('audio/emoji_memory/emoji_wrong.mp3'));
    } catch (e) {}
  }

  static Future<void> playEmojiTap() async {
    if (isMuted.value) return;
    try {
      await _emojiTapPlayer.stop();
      await _emojiTapPlayer.play(AssetSource('audio/emoji_memory/emoji_tap.mp3'));
    } catch (e) {}
  }

  static final AudioPlayer _mathWrongPlayer = AudioPlayer();
  static final AudioPlayer _mathCoinDropPlayer = AudioPlayer();
  static final AudioPlayer _mathCorrectPlayer = AudioPlayer();
  static final AudioPlayer _mathClaimPlayer = AudioPlayer();
  static final AudioPlayer _mathSikkaEarnedPlayer = AudioPlayer();

  // Math Rush Audios
  static Future<void> playMathWrong() async {
    if (isMuted.value) return;
    try {
      await _mathWrongPlayer.stop();
      await _mathWrongPlayer.play(AssetSource('audio/math_rush/math_wrong.mp3'));
    } catch (e) {}
  }

  static Future<void> playMathCoinDrop() async {
    if (isMuted.value) return;
    try {
      await _mathCoinDropPlayer.stop();
      await _mathCoinDropPlayer.play(AssetSource('audio/math_rush/math_coin_drop.mp3'));
    } catch (e) {}
  }

  static Future<void> playMathCorrect() async {
    if (isMuted.value) return;
    try {
      await _mathCorrectPlayer.stop();
      await _mathCorrectPlayer.play(AssetSource('audio/math_rush/math_correct.mp3'));
    } catch (e) {}
  }

  static Future<void> playMathClaim() async {
    if (isMuted.value) return;
    try {
      await _mathClaimPlayer.stop();
      await _mathClaimPlayer.play(AssetSource('audio/math_rush/math_claim.mp3'));
    } catch (e) {}
  }

  static Future<void> playMathSikkaEarned() async {
    if (isMuted.value) return;
    try {
      await _mathSikkaEarnedPlayer.stop();
      await _mathSikkaEarnedPlayer.play(AssetSource('audio/math_rush/math_sikka_earned.mp3'));
    } catch (e) {}
  }

  // Backwards compatibility
  static Future<void> playTick() async {}

  static Future<void> playWin() async {
    if (isMuted.value) return;
    await playSpinReward();
    await Future.delayed(const Duration(milliseconds: 500));
    await playSikkaEarned();
  }

  static Future<void> playCorrect() async {}
  static Future<void> playWrong() async {}
  
  static void stopAll() {
    try {
      _startPlayer.stop();
      _stopPlayer.stop();
      _rewardPlayer.stop();
      _sikkaPlayer.stop();
      _treasureBombPlayer.stop();
      _treasureCoinPlayer.stop();
      _treasureBlockShowPlayer.stop();
      _treasureBlockHidePlayer.stop();
      _emojiShowPlayer.stop();
      _emojiHidePlayer.stop();
      _emojiRewardPlayer.stop();
      _emojiWrongPlayer.stop();
      _emojiTapPlayer.stop();
      _mathWrongPlayer.stop();
      _mathCoinDropPlayer.stop();
      _mathCorrectPlayer.stop();
      _mathClaimPlayer.stop();
      _mathSikkaEarnedPlayer.stop();
    } catch (e) {}
  }
  
  static void dispose() {
    stopAll();
  }
}
