import re

file_path = r'e:\development\SikkaPlay\lib\features\profile\controllers\user_controller.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_func = """  void updateLocalBalance(int newBalance) {
    if (state.userData != null) {
      final currentData = Map<String, dynamic>.from(state.userData!);
      currentData['balance'] = newBalance;
      state = state.copyWith(userData: currentData);
    }
    _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
  }

  void updateLocalGullakCount(int newCount) {
    if (state.userData != null) {
      final currentData = Map<String, dynamic>.from(state.userData!);
      currentData['win600UnlockedGullaks'] = newCount;
      state = state.copyWith(userData: currentData);
    }
  }"""

content = content.replace("  void updateLocalBalance(int newBalance) {\n    if (state.userData != null) {\n      final currentData = Map<String, dynamic>.from(state.userData!);\n      currentData['balance'] = newBalance;\n      state = state.copyWith(userData: currentData);\n    }\n    _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);\n  }", new_func)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated user_controller.dart")
