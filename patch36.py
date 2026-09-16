import re

file_path = r'e:\development\SikkaPlay\lib\features\games\arrow_escape\screens\game\game_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add the audio service call in _showLevelCompleteDialog
old_func = r"Future<void> _showLevelCompleteDialog\(int stars\) async \{"
new_func = """Future<void> _showLevelCompleteDialog(int stars) async {
    ArrowEscapeAudioService.instance.playLevelCompleteSfx();"""

content = re.sub(old_func, new_func, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated game_screen.dart with level complete sfx")
