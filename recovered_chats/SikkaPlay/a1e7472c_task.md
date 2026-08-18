# Phase 1: Riverpod Circular Loop Fix Tasks

- [x] Create Centralized Sync Coordinator
  - [x] Implement `SyncEvent` enum and `SyncCoordinator` class
  - [x] Add event-based queueing, debouncing (300ms), and duplicate filtering
  - [x] Add robust retry logic (up to 3 times) with exponential backoff
- [x] Refactor Profile Controller (`user_controller.dart`)
  - [x] Remove `homeProvider` trigger from `fetchProfile`
  - [x] Call `SyncCoordinator` inside `claimReward`, `claimDynamicSocialTask`, `updateUpi`, and `updateProfileDetails`
- [x] Refactor Home Controller (`home_controller.dart`)
  - [x] Remove `userProvider` trigger from `_loadState`
  - [x] Update `refresh` to only fetch user profile on explicit manual refreshes
  - [x] Call `SyncCoordinator` inside mutating actions
- [x] Update Client Screens and Dialogs
  - [x] Edit `game_claim_dialog.dart` to trigger coordinator sync on claim success
  - [x] Edit `daily_code_screen.dart` to trigger coordinator sync on code claim success
  - [x] Edit `visit_earn_screen.dart` to trigger coordinator sync on link claim success
- [x] Verification
  - [x] Verify static code checks with `flutter analyze`
