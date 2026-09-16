import re

file_path = r'e:\development\SikkaPlay\lib\features\games\games_hub\providers\win_600_provider.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_content = """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/core/sync/sync_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Win600State {
  final int unlockedGullaks;
  final bool isClaimed;

  Win600State({required this.unlockedGullaks, required this.isClaimed});

  Win600State copyWith({int? unlockedGullaks, bool? isClaimed}) {
    return Win600State(
      unlockedGullaks: unlockedGullaks ?? this.unlockedGullaks,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}

class Win600Notifier extends Notifier<Win600State> {
  @override
  Win600State build() {
    // Read initial value once so we don't rebuild and lose optimistic state on every balance change
    final userData = ref.read(userProvider).userData;
    int unlockedCount = userData?['win600UnlockedGullaks'] ?? 0;
    
    // Listen for backend profile updates and sync them IF they are higher (or if it reset to 0)
    ref.listen(userProvider, (previous, next) {
      final newCount = next.userData?['win600UnlockedGullaks'] ?? 0;
      // Update state if the backend explicitly reset it (0) or has a different count
      if (newCount != state.unlockedGullaks) {
        state = state.copyWith(unlockedGullaks: newCount);
      }
    });

    return Win600State(unlockedGullaks: unlockedCount, isClaimed: false);
  }

  Future<void> incrementGullak() async {
    if (state.unlockedGullaks >= 9) return;
    
    // Optimistic update so UI feels instant
    final newCount = state.unlockedGullaks + 1;
    state = state.copyWith(unlockedGullaks: newCount);

    try {
      final response = await ref.read(userServiceProvider).incrementGullak();
      if (response != null && response['success'] == true) {
        // Backend confirmed, sync profile to ensure everything is consistent
        ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.profileUpdated]);
      }
    } catch (e) {
      print('Failed to increment gullak on backend: $e');
    }
  }

  Future<void> claimFinalReward() async {
    if (state.unlockedGullaks < 9 || state.isClaimed) return;
    
    state = state.copyWith(isClaimed: true);
    
    try {
      final response = await ref.read(userServiceProvider).claimGullakReward();
      if (response != null && response['success'] == true) {
        // Reset local state to allow next loop
        state = Win600State(unlockedGullaks: 0, isClaimed: false);
        // Sync user profile and balance
        ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.profileUpdated, SyncEvent.balanceChanged]);
      } else {
        state = state.copyWith(isClaimed: false);
      }
    } catch (e) {
      state = state.copyWith(isClaimed: false);
    }
  }
}

final win600Provider = NotifierProvider<Win600Notifier, Win600State>(() {
  return Win600Notifier();
});
"""

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)
