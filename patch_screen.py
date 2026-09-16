import re

file_path = r'e:\development\SikkaPlay\lib\features\games\games_hub\screens\win_600_coins_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_builder = '''          Consumer(
            builder: (context, ref, child) {
              final win600State = ref.watch(win600Provider);
              return GridView.builder('''

new_builder = '''          Consumer(
            builder: (context, ref, child) {
              final win600State = ref.watch(win600Provider);
              final unlockedGullaks = ref.watch(userProvider).userData?['win600UnlockedGullaks'] ?? 0;
              return GridView.builder('''

old_unlocked = '''                itemBuilder: (context, index) {
                  bool isLast = index == 9;
                  bool isUnlocked = index < win600State.unlockedGullaks;
                  bool canClaimFinal = win600State.unlockedGullaks >= 9;'''

new_unlocked = '''                itemBuilder: (context, index) {
                  bool isLast = index == 9;
                  bool isUnlocked = index < unlockedGullaks;
                  bool canClaimFinal = unlockedGullaks >= 9;'''

content = content.replace(old_builder, new_builder)
content = content.replace(old_unlocked, new_unlocked)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched win_600_coins_screen.dart")
