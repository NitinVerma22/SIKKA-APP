import re

file_path = r'e:\development\SikkaPlay\lib\features\games\games_hub\screens\win_600_coins_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('final win600State = ref.watch(win600Provider);', 'final win600State = ref.watch(win600Provider);\n              final unlockedGullaks = ref.watch(userProvider).userData?[\'win600UnlockedGullaks\'] ?? 0;')
content = content.replace('bool isUnlocked = index < win600State.unlockedGullaks;', 'bool isUnlocked = index < unlockedGullaks;')
content = content.replace('bool canClaimFinal = win600State.unlockedGullaks >= 9;', 'bool canClaimFinal = unlockedGullaks >= 9;')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched screen")
