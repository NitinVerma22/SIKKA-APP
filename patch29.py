import re

file_path = r'e:\development\SikkaPlay\lib\features\games\games_hub\providers\win_600_provider.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_content = """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/core/sync/sync_coordinator.dart';

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
    // We derive state directly from the user provider's profile data
    final userData = ref.watch(userProvider).userData;
    final int unlockedCount = userData?['win600UnlockedGullaks'] ?? 0;
    
    // We don't track isClaimed permanently anymore since it's an infinite loop.
    // If it's resetting, we just see it back to 0.
    return Win600State(unlockedGullaks: unlockedCount, isClaimed: false);
  }

  Future<void> incrementGullak() async {
    // Optimistic update
    if (state.unlockedGullaks >= 9) return;
    state = state.copyWith(unlockedGullaks: state.unlockedGullaks + 1);

    // Call backend
    final response = await ref.read(userServiceProvider).incrementGullak();
    if (response != null && response['success'] == true) {
      // Sync user profile to reflect the real count
      ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.profileUpdated]);
    }
  }

  Future<void> claimFinalReward() async {
    if (state.unlockedGullaks < 9 || state.isClaimed) return;
    
    // Optimistic update
    state = state.copyWith(isClaimed: true);
    
    // Call backend
    final response = await ref.read(userServiceProvider).claimGullakReward();
    if (response != null && response['success'] == true) {
      // Sync user profile (which will reset unlockedGullaks to 0) and update balance
      ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.profileUpdated, SyncEvent.balanceChanged]);
      // reset local claimed state to allow next loop
      state = Win600State(unlockedGullaks: 0, isClaimed: false);
    } else {
      // Revert if failed
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
