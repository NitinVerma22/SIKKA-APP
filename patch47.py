import re

file_path = r'e:\development\SikkaPlay\lib\features\games\arrow_escape\screens\arrow_escape_game_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import if missing
if "import '../services/arrow_escape_audio_service.dart';" not in content:
    content = content.replace("import '../services/arrow_escape_service.dart';", "import '../services/arrow_escape_service.dart';\nimport '../services/arrow_escape_audio_service.dart';")

# Find _onCanvasTap success
success_old = """    if (canEscape) {
      tappedArrow.isEscaping = true;
      tappedArrow.escapeProgress = 0.0;"""
success_new = """    if (canEscape) {
      ArrowEscapeAudioService.instance.playEscapeSfx();
      tappedArrow.isEscaping = true;
      tappedArrow.escapeProgress = 0.0;"""
content = content.replace(success_old, success_new)

# Find _onCanvasTap failure (collision)
failure_old = """      setState(() {
        _lives--;
        _highlightedArrowId = tappedArrow.id; // Highlight on wrong tap!
      });
      AudioHapticHelper.playCollision();"""
failure_new = """      setState(() {
        _lives--;
        _highlightedArrowId = tappedArrow.id; // Highlight on wrong tap!
      });
      ArrowEscapeAudioService.instance.playCollisionSfx();
      AudioHapticHelper.playCollision();"""
content = content.replace(failure_old, failure_new)

# Find _onLevelComplete
level_comp_old = """  Future<void> _onLevelComplete() async {
    // Play level complete victory sound
    AudioHapticHelper.playLevelComplete();"""
level_comp_new = """  Future<void> _onLevelComplete() async {
    // Play level complete victory sound
    ArrowEscapeAudioService.instance.playLevelCompleteSfx();
    AudioHapticHelper.playLevelComplete();"""
content = content.replace(level_comp_old, level_comp_new)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched arrow_escape_game_screen.dart for audio")
