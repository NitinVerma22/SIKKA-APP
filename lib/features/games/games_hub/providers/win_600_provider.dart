import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/features/profile/controllers/user_controller.dart';
import 'package:sikkaplay/core/sync/sync_coordinator.dart';
import 'package:sikkaplay/core/user/user_service.dart';

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
    final userData = ref.read(userProvider).userData;
    int unlockedCount = userData?['win600UnlockedGullaks'] ?? 0;
    
    ref.listen(userProvider, (previous, next) {
      final newCount = next.userData?['win600UnlockedGullaks'] ?? 0;
      if (newCount != state.unlockedGullaks) {
        state = state.copyWith(unlockedGullaks: newCount);
      }
    });

    return Win600State(unlockedGullaks: unlockedCount, isClaimed: false);
  }

  Future<void> incrementGullak() async {
    if (state.unlockedGullaks >= 9) return;
    
    final oldCount = state.unlockedGullaks;
    final newCount = oldCount + 1;
    
    // Opt update local first
    ref.read(userProvider.notifier).updateLocalGullakCount(newCount);

    try {
      final response = await ref.read(userServiceProvider).incrementGullak();
      if (response != null && response['success'] == true) {
        ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.profileUpdated]);
      } else {
        // Revert on failure
        ref.read(userProvider.notifier).updateLocalGullakCount(oldCount);
      }
    } catch (e) {
      ref.read(userProvider.notifier).updateLocalGullakCount(oldCount);
      print('Failed to increment gullak on backend: $e');
    }
  }

  Future<void> claimFinalReward() async {
    if (state.unlockedGullaks < 9 || state.isClaimed) return;
    
    state = state.copyWith(isClaimed: true);
    
    try {
      final response = await ref.read(userServiceProvider).claimGullakReward();
      if (response != null && response['success'] == true) {
        ref.read(userProvider.notifier).updateLocalGullakCount(0);
        state = Win600State(unlockedGullaks: 0, isClaimed: false);
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
