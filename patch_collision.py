import re

file_path = r'e:\development\SikkaPlay\lib\features\games\arrow_escape\screens\arrow_escape_game_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_logic_1 = '''    // Check if tappedArrow is locked or path is blocked
    if (tappedArrow.isLocked) {
      tappedArrow.isBlockedShaking = true;
      tappedArrow.shakeProgress = -1.0;
      _lives--;
      if (_lives <= 0) _isGameOver = true;
      setState(() {});
      return;
    }'''
new_logic_1 = '''    // Check if tappedArrow is locked or path is blocked
    if (tappedArrow.isLocked) {
      ArrowEscapeAudioService.instance.playCollisionSfx();
      AudioHapticHelper.playCollision();
      tappedArrow.isBlockedShaking = true;
      tappedArrow.shakeProgress = -1.0;
      _lives--;
      if (_lives <= 0) _isGameOver = true;
      setState(() {});
      return;
    }'''

old_logic_2 = '''    } else {
      tappedArrow.isBlockedShaking = true;
      tappedArrow.shakeProgress = -1.0;

      _lives--;
      if (_lives <= 0) {
        _isGameOver = true;
      }
    }'''
new_logic_2 = '''    } else {
      ArrowEscapeAudioService.instance.playCollisionSfx();
      AudioHapticHelper.playCollision();
      tappedArrow.isBlockedShaking = true;
      tappedArrow.shakeProgress = -1.0;

      _lives--;
      if (_lives <= 0) {
        _isGameOver = true;
      }
    }'''

content = content.replace(old_logic_1, new_logic_1)
content = content.replace(old_logic_2, new_logic_2)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched arrow escape collision")
