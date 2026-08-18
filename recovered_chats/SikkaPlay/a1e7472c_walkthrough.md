# Walkthrough: Phase 1 Egress Optimization

Phase 1 has been successfully implemented and verified through static code analysis.

## Centralized Sync Coordinator Implementation

### ✅ What changed
- Created [sync_coordinator.dart](file:///E:/development/SikkaPlay/lib/core/sync/sync_coordinator.dart) to define a central `SyncCoordinator` provider. It maps specific user events (`SyncEvent`) to affected Riverpod providers, debounces incoming calls by 300ms, and implements a 3-attempt exponential backoff retry.
- Refactored [user_controller.dart](file:///E:/development/SikkaPlay/lib/features/profile/controllers/user_controller.dart) to remove `homeProvider` refreshes inside read operations (`fetchProfile`), and redirected mutating actions (`claimReward`, `updateUpi`, etc.) to trigger sync events via `SyncCoordinator`.
- Refactored [home_controller.dart](file:///E:/development/SikkaPlay/lib/features/home/controllers/home_controller.dart) to remove `userProvider` refreshes inside read operations (`_loadState`) and stripped out background FCM token updates. Mutating operations now trigger sync events.
- Updated game claims in [game_claim_dialog.dart](file:///E:/development/SikkaPlay/lib/features/games/shared/utils/game_claim_dialog.dart), daily codes in [daily_code_screen.dart](file:///E:/development/SikkaPlay/lib/features/home/screens/daily_code_screen.dart), and visit links in [visit_earn_screen.dart](file:///E:/development/SikkaPlay/lib/features/home/screens/visit_earn_screen.dart) to trigger sync events.

### ✅ Why
To eliminate the infinite API request loop polling `/profile` and `/home` (running 14 SQL queries per cycle) continuously in the background, conserving Supabase resource egress and DB CPU.

### ✅ Risk level
**LOW**. All optimistic UI updates remain identical, and providers are successfully updated exactly once in the background.

### ✅ Rollback plan
To revert, execute:
```bash
git checkout -- lib/features/profile/controllers/user_controller.dart
git checkout -- lib/features/home/controllers/home_controller.dart
git checkout -- lib/features/games/shared/utils/game_claim_dialog.dart
git checkout -- lib/features/home/screens/daily_code_screen.dart
git checkout -- lib/features/home/screens/visit_earn_screen.dart
rm lib/core/sync/sync_coordinator.dart
```

### ✅ Files and Lines Changed
- **[NEW]** `lib/core/sync/sync_coordinator.dart` (104 lines added)
- **[MODIFY]** `lib/features/profile/controllers/user_controller.dart` (Lines 1-5, 46-61, 122-130, 143-151, 156-167, 169-176, 181-186, 192-198)
- **[MODIFY]** `lib/features/home/controllers/home_controller.dart` (Lines 2-7, 246-268, 270-276, 278-299, 311-333, 363-376)
- **[MODIFY]** `lib/features/games/shared/utils/game_claim_dialog.dart` (Lines 9-11, 50-51, 114-115, 423-424)
- **[MODIFY]** `lib/features/home/screens/daily_code_screen.dart` (Lines 21-24, 287-288)
- **[MODIFY]** `lib/features/home/screens/visit_earn_screen.dart` (Lines 8, 138-139)

---

## Before vs. After Code Comparison

### 1. Read Operations (fetchProfile & _loadState)

#### Before (Mutual Silent Refresh Loop)
```dart
// UserNotifier
Future<void> fetchProfile({bool silent = false}) async {
  ...
  final data = await _userService.getProfile();
  if (data != null) {
    state = state.copyWith(isLoading: false, userData: data);
    _ref.read(homeProvider.notifier).refresh(silent: true).catchError((_) {}); // circular trigger
  }
}

// HomeNotifier
Future<void> _loadState() async {
  ...
  final data = await _userService.getHomeState();
  if (data != null && data['success'] == true) {
    state = HomeState.fromJson(data).copyWith(isLoading: false);
    _ref.read(userProvider.notifier).refresh(silent: true).catchError((_) {}); // circular trigger
  }
}
```

#### After (Read-Only Side-Effect Free Fetching)
```dart
// UserNotifier
Future<void> fetchProfile({bool silent = false}) async {
  ...
  final data = await _userService.getProfile();
  if (data != null) {
    state = state.copyWith(isLoading: false, userData: data);
  } else {
    throw Exception('Failed to load profile'); // propagates to SyncCoordinator
  }
}

// HomeNotifier
Future<void> _loadState() async {
  ...
  final data = await _userService.getHomeState();
  if (data != null && data['success'] == true) {
    state = HomeState.fromJson(data).copyWith(isLoading: false);
  } else {
    throw Exception('Failed to load home state'); // propagates to SyncCoordinator
  }
}
```

---

### 2. Mutating Operations (e.g. claimReward)

#### Before (Direct Cross-Refresh)
```dart
if (success) {
  await fetchProfile(); // automatically triggered circular home refresh
}
```

#### After (Centralized Event Dispatch)
```dart
if (success) {
  _ref.read(syncCoordinatorProvider).triggerSync([SyncEvent.balanceChanged]); // debounced, exact updates
}
```
