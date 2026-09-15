import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _load();
    return Win600State(unlockedGullaks: 0, isClaimed: false);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getInt('win600_unlocked_gullaks') ?? 0;
    final claimed = prefs.getBool('win600_is_claimed') ?? false;
    state = Win600State(unlockedGullaks: unlocked, isClaimed: claimed);
  }

  Future<void> incrementGullak() async {
    if (state.unlockedGullaks >= 9) return;
    
    final newCount = state.unlockedGullaks + 1;
    state = state.copyWith(unlockedGullaks: newCount);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('win600_unlocked_gullaks', newCount);
  }

  Future<void> claimFinalReward() async {
    if (state.unlockedGullaks < 9 || state.isClaimed) return;
    
    state = state.copyWith(isClaimed: true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('win600_is_claimed', true);
  }
}

final win600Provider = NotifierProvider<Win600Notifier, Win600State>(() {
  return Win600Notifier();
});
