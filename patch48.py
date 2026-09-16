import re

file_path = r'e:\development\SikkaPlay\lib\features\games\arrow_escape\screens\arrow_escape_game_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import if missing
if "import 'package:sikkaplay/features/games/games_hub/providers/win_600_provider.dart';" not in content:
    content = content.replace("import '../../shared/utils/game_notifications.dart';", "import '../../shared/utils/game_notifications.dart';\nimport 'package:sikkaplay/features/games/games_hub/providers/win_600_provider.dart';")

# Find _onLevelComplete
old_logic = """  Future<void> _onLevelComplete() async {
    // Play level complete victory sound
    ArrowEscapeAudioService.instance.playLevelCompleteSfx();
    AudioHapticHelper.playLevelComplete();"""
new_logic = """  Future<void> _onLevelComplete() async {
    // Play level complete victory sound
    ArrowEscapeAudioService.instance.playLevelCompleteSfx();
    AudioHapticHelper.playLevelComplete();
    
    // Increment Gullak progress for completing a level
    ref.read(win600Provider.notifier).incrementGullak();"""
content = content.replace(old_logic, new_logic)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched arrow_escape_game_screen.dart for gullak")
