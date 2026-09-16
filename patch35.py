import re

file_path = r'e:\development\SikkaPlay\lib\features\games\arrow_escape\services\arrow_escape_audio_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace playEscapeSfx
old_escape = r"AssetSource\('audio/spin/tick.mp3'\), volume: 0.7"
new_escape = r"AssetSource('audio/arrow_escape/arrow_shot.mp3'), volume: 0.7"
content = re.sub(old_escape, new_escape, content)

# Replace playCollisionSfx
old_collision = r"AssetSource\('audio/spin/tick.mp3'\), volume: 0.3"
new_collision = r"AssetSource('audio/arrow_escape/lifeline_lost.mp3'), volume: 0.7"
content = re.sub(old_collision, new_collision, content)

# Add playLevelCompleteSfx
level_complete_func = """
  Future<void> playLevelCompleteSfx() async {
    if (isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/arrow_escape/level_complete.mp3'), volume: 0.7);
    } catch (e) {
      debugPrint('Error playing level complete sfx: $e');
    }
  }
}"""
content = re.sub(r"}\s*$", level_complete_func, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated audio service")
