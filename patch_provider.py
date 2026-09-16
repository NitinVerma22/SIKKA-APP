import re

file_path = r'e:\development\SikkaPlay\lib\features\games\games_hub\providers\win_600_provider.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_build = '''  @override
  Win600State build() {
    final userData = ref.watch(userProvider).userData;
    int unlockedCount = userData?['win600UnlockedGullaks'] ?? 0;
    
    // Preserve isClaimed if this is a rebuild due to userProvider update
    bool isClaimed = stateOrNull?.isClaimed ?? false;

    return Win600State(unlockedGullaks: unlockedCount, isClaimed: isClaimed);
  }'''

new_build = '''  @override
  Win600State build() {
    final userData = ref.read(userProvider).userData;
    int unlockedCount = userData?['win600UnlockedGullaks'] ?? 0;
    return Win600State(unlockedGullaks: unlockedCount, isClaimed: false);
  }'''

content = content.replace(old_build, new_build)

old_increment = '''  Future<void> incrementGullak() async {
    if (state.unlockedGullaks >= 9) return;
    
    final oldCount = state.unlockedGullaks;
    final newCount = oldCount + 1;
    
    // Opt update local first
    ref.read(userProvider.notifier).updateLocalGullakCount(newCount);'''

new_increment = '''  Future<void> incrementGullak() async {
    final currentCount = ref.read(userProvider).userData?['win600UnlockedGullaks'] ?? 0;
    if (currentCount >= 9) return;
    
    final oldCount = currentCount;
    final newCount = oldCount + 1;
    
    // Opt update local first
    ref.read(userProvider.notifier).updateLocalGullakCount(newCount);'''

content = content.replace(old_increment, new_increment)

old_claim = '''  Future<void> claimFinalReward() async {
    if (state.unlockedGullaks < 9 || state.isClaimed) return;'''

new_claim = '''  Future<void> claimFinalReward() async {
    final currentCount = ref.read(userProvider).userData?['win600UnlockedGullaks'] ?? 0;
    if (currentCount < 9 || state.isClaimed) return;'''

content = content.replace(old_claim, new_claim)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched win_600_provider.dart")
