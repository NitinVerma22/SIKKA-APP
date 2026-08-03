import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/user/user_service.dart';
import 'package:sikkaplay/features/home/controllers/home_controller.dart';
import 'package:sikkaplay/core/sync/sync_coordinator.dart';

class UserState {
  final bool isLoading;
  final Map<String, dynamic>? userData;
  final String? error;

  UserState({
    this.isLoading = false,
    this.userData,
    this.error,
  });

  UserState copyWith({
    bool? isLoading,
    Map<String, dynamic>? userData,
    String? error,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      userData: userData ?? this.userData,
      error: error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final UserService _userService;
  final Ref _ref;

  UserNotifier(this._userService, this._ref) : super(UserState()) {
    // Only fetch if we have a token (i.e., user is logged in)
    _tryFetchProfile();
  }

  Future<void> _tryFetchProfile() async {
    try {
      await fetchProfile();
    } catch (_) {
      // Silently fail - user may not be logged in yet
    }
  }

  Future<void> _fetchProfileSilently() async {
    try {
      final data = await _userService.getProfile();
      if (data != null) {
        state = state.copyWith(isLoading: false, userData: data);
      }
    } catch (_) {}
  }

  Future<void> fetchProfile({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final data = await _userService.getProfile();
      if (data != null) {
        state = state.copyWith(isLoading: false, userData: data);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load profile');
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Refresh data explicitly
  Future<void> refresh({bool silent = false}) async {
    await fetchProfile(silent: silent);
  }

  Future<bool> claimReward(int amount, String type, String description) async {
    // Optimistic update
    if (state.userData != null) {
      final currentData = Map<String, dynamic>.from(state.userData!);
      currentData['balance'] = (currentData['balance'] ?? 0) + amount;
      currentData['totalEarned'] = (currentData['totalEarned'] ?? 0) + amount;
      state = state.copyWith(userData: currentData);
    }

    bool success = false;
    final lowerType = type.toLowerCase();
    final lowerDesc = description.toLowerCase();

    if (lowerType == 'daily_streak') {
      success = await _userService.claimDailyStreak();
    } else if (lowerType == 'social_task') {
      String platform = 'telegram';
      if (lowerDesc.contains('whatsapp')) {
        platform = 'whatsapp';
      } else if (lowerDesc.contains('group')) {
        platform = 'group';
      }
      success = await _userService.claimSocialTask(platform);
    } else if (lowerType == 'survey') {
      String provider = 'Mock Partner';
      if (lowerDesc.contains('cpx')) {
        provider = 'CPX Research';
      }
      success = await _userService.claimSurvey(description, provider);
    } else if (lowerType == 'app_install') {
      String offerId = 'telegram';
      if (lowerDesc.contains('binance')) {
        offerId = 'binance';
      } else if (lowerDesc.contains('phonepe')) offerId = 'phonepe';
      else if (lowerDesc.contains('gpay') || lowerDesc.contains('google pay')) offerId = 'gpay';
      else if (lowerDesc.contains('whatsapp')) offerId = 'whatsapp_biz';
      success = await _userService.claimAppInstall(offerId);
    } else if (lowerType == 'watch_earn') {
      final match = RegExp(r'(\d+)\s*mins').firstMatch(description);
      final minutes = match != null ? int.tryParse(match.group(1) ?? '') ?? 0 : 0;
      success = await _userService.claimMilestone('watch', minutes);
    } else if (lowerType == 'earning') {
      if (lowerDesc.contains('daily code')) {
        success = await _userService.claimMilestone('daily_code_task', 0);
      } else if (lowerDesc.contains('visited all links')) {
        success = await _userService.claimMilestone('visit_all_task', 0);
      } else {
        // play milestone
        final match = RegExp(r'(\d+)\s*mins').firstMatch(description);
        final minutes = match != null ? int.tryParse(match.group(1) ?? '') ?? 0 : 0;
        success = await _userService.claimMilestone('play', minutes);
      }
    }

    if (success) {
      // Sync with backend using the centralized Sync Coordinator
      _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
    } else {
      // Revert optimistic update
      await _fetchProfileSilently();
    }
    return success;
  }

  Future<bool> claimDynamicSocialTask(String taskId, int amount) async {
    // Optimistic update
    if (state.userData != null) {
      final currentData = Map<String, dynamic>.from(state.userData!);
      currentData['balance'] = (currentData['balance'] ?? 0) + amount;
      currentData['totalEarned'] = (currentData['totalEarned'] ?? 0) + amount;
      state = state.copyWith(userData: currentData);
    }

    final success = await _userService.claimDynamicSocialTask(taskId);

    if (success) {
      // Sync with backend using the centralized Sync Coordinator
      _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
    } else {
      // Revert optimistic update
      await _fetchProfileSilently();
    }
    return success;
  }

  Future<Map<String, dynamic>?> spinWheel(String sessionId, {bool delayBalanceUpdate = false}) async {
    final response = await _userService.spinWheel(sessionId);
    if (response != null && response['success'] == true) {
      if (!delayBalanceUpdate) {
        if (state.userData != null) {
          final currentData = Map<String, dynamic>.from(state.userData!);
          currentData['balance'] = response['balance'];
          state = state.copyWith(userData: currentData);
        }
        _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
      }
      return response;
    }
    return null;
  }

  void updateLocalBalance(int newBalance) {
    if (state.userData != null) {
      final currentData = Map<String, dynamic>.from(state.userData!);
      currentData['balance'] = newBalance;
      state = state.copyWith(userData: currentData);
    }
    _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]);
  }

  Future<bool> updateUpi(String upiId) async {
    state = state.copyWith(isLoading: true, error: null);
    final success = await _userService.updateUpi(upiId);
    if (success) {
      _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.profileUpdated]);
    } else {
      state = state.copyWith(isLoading: false, error: 'Failed to update UPI ID');
    }
    return success;
  }

  Future<Map<String, dynamic>> updateProfileDetails({String? name, String? username, String? gender, String? city}) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _userService.updateProfileDetails(name: name, username: username, gender: gender, city: city);
    if (res['success'] == true) {
      _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.profileUpdated]);
    } else {
      state = state.copyWith(isLoading: false, error: res['error']);
    }
    return res;
  }
}

final userServiceProvider = Provider((ref) => UserService());

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final userService = ref.watch(userServiceProvider);
  return UserNotifier(userService, ref);
});
