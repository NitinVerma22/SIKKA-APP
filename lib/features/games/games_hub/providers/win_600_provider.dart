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
  static const int maxGullaks = 9;

  @override
  Win600State build() {
    final userData = ref.read(userProvider).userData;
    final unlockedCount = _clampCount(userData?['win600UnlockedGullaks']);
    return Win600State(unlockedGullaks: unlockedCount, isClaimed: false);
  }

  int _clampCount(dynamic value) {
    final parsed = value is int ? value : int.tryParse('$value') ?? 0;
    return parsed.clamp(0, maxGullaks);
  }

  /// Called only after the normal game Gullak claim succeeds.
  /// Win600 progress never exceeds 9 and never resets here.
  Future<bool> incrementGullak() async {
    final currentCount = _clampCount(
      ref.read(userProvider).userData?['win600UnlockedGullaks'],
    );
    if (currentCount >= maxGullaks) return true;

    final response = await ref.read(userServiceProvider).incrementGullak();
    if (response != null && response['success'] == true) {
      final serverCount = _clampCount(response['unlockedGullaks'] ?? currentCount + 1);
      ref.read(userProvider.notifier).updateLocalGullakCount(serverCount);
      state = state.copyWith(unlockedGullaks: serverCount, isClaimed: false);
      ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.profileUpdated]);
      return true;
    }

    // Backend is authoritative; restore current server-backed local state.
    await ref.read(userProvider.notifier).refresh(silent: true);
    final refreshedCount = _clampCount(
      ref.read(userProvider).userData?['win600UnlockedGullaks'],
    );
    state = state.copyWith(unlockedGullaks: refreshedCount, isClaimed: false);
    return false;
  }

  /// Claims exactly one 150-coin Win600 gift and resets progress to 0.
  /// No local balance credit is performed here; backend response is authoritative.
  Future<bool> claimFinalReward() async {
    final currentCount = _clampCount(
      ref.read(userProvider).userData?['win600UnlockedGullaks'],
    );
    if (currentCount < maxGullaks || state.isClaimed) return false;

    state = state.copyWith(isClaimed: true);

    try {
      final response = await ref.read(userServiceProvider).claimGullakReward();
      if (response != null && response['success'] == true) {
        final newCount = _clampCount(response['unlockedGullaks']);
        final balance = response['balance'];
        ref.read(userProvider.notifier).updateLocalGullakCount(newCount);
        if (balance is int) {
          ref.read(userProvider.notifier).updateLocalBalance(balance);
        } else {
          await ref.read(userProvider.notifier).refresh(silent: true);
        }
        state = Win600State(unlockedGullaks: newCount, isClaimed: false);
        ref.read(syncCoordinatorProvider).triggerSync([
          SyncEvent.profileUpdated,
          SyncEvent.balanceChanged,
        ]);
        return true;
      }

      state = state.copyWith(isClaimed: false);
      await ref.read(userProvider.notifier).refresh(silent: true);
      return false;
    } catch (e) {
      state = state.copyWith(isClaimed: false);
      await ref.read(userProvider.notifier).refresh(silent: true);
      return false;
    }
  }
}

final win600Provider = NotifierProvider<Win600Notifier, Win600State>(() {
  return Win600Notifier();
});
