import re

file_path = r'e:\development\SikkaPlay\lib\features\games\games_hub\providers\win_600_provider.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_build = '''  @override
  Win600State build() {
    final userData = ref.read(userProvider).userData;
    int unlockedCount = userData?['win600UnlockedGullaks'] ?? 0;
    
    ref.listen(userProvider, (previous, next) {
      final newCount = next.userData?['win600UnlockedGullaks'] ?? 0;
      if (newCount != state.unlockedGullaks) {
        state = state.copyWith(unlockedGullaks: newCount);
      }
    });

    return Win600State(unlockedGullaks: unlockedCount, isClaimed: false);
  }'''

new_build = '''  @override
  Win600State build() {
    final userData = ref.watch(userProvider).userData;
    int unlockedCount = userData?['win600UnlockedGullaks'] ?? 0;
    
    // Preserve isClaimed if this is a rebuild due to userProvider update
    bool isClaimed = stateOrNull?.isClaimed ?? false;

    return Win600State(unlockedGullaks: unlockedCount, isClaimed: isClaimed);
  }'''

content = content.replace(old_build, new_build)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated win_600_provider.dart")
