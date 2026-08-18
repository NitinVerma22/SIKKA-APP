# Implementation Plan - SikkaPlay Improvements & Bug Fixes

This implementation plan covers the remaining tasks: Tic-Tac-Toe chat game fixes, received gifts icon displays, daily streak miss notifications (keeping cost at `missed days * 15`), and confirmation option dialogs before showing rewarded ads.

## Proposed Changes

### 1. Frontend: Tic-Tac-Toe chat game (COMPLETED / ALREADY APPLIED)
- Resolved the polling suspension bug under dialog routes by checking for `PageRoute` overlay instead of a simple `isCurrent` route check.
- Added symbol swapping, request timeouts (15s), and PopScope forfeit protection.

### 2. Frontend: Received Gifts Showcase Icons
#### [MODIFY] [profile_screen.dart](file:///e:/development/SikkaPlay/lib/features/profile/screens/profile_screen.dart)
- Implement `_getGiftEmoji(String name)` mapping gift names to their SikkaPlay emoji icons (e.g. Coffee -> `☕`, Rose -> `🌹`, Crown -> `👑`).
- Update received gifts showcase renderer: if `Image.network` fails to load (errorBuilder) or if the image URL is not a valid http string, render the matching high-fidelity emoji instead of the generic `'🎁'` placeholder.

### 3. Frontend: Daily Streak Miss Notification (Cost: skippedDays * 15)
#### [MODIFY] [daily_streak_widget.dart](file:///e:/development/SikkaPlay/lib/features/home/widgets/daily_streak_widget.dart)
- The cost remains at `skippedDays * 15` (no changes to backend cost calculation).
- Update daily streak resume dialog text and successful resume SnackBar to show: `Missed N days. OK` where `N` is the number of missed days.

### 4. Frontend: Watch Video Confirmation Option Dialog
#### [MODIFY] [ad_service.dart](file:///e:/development/SikkaPlay/lib/core/ads/ad_service.dart)
- Update `showRewardedAd` method to accept `BuildContext context`.
- Before displaying the ad, show a confirmation AlertDialog:
  - Title: "Watch Video? 🎮"
  - Content: "Watch video to claim this reward."
  - Buttons: "CANCEL" (dismisses ad / cancels) and "WATCH NOW" (plays the admob ad).
- If not confirmed, call `onAdDismissed()` and return without playing.
#### [MODIFY] Call Sites for `showRewardedAd`
Update calls to pass the `context` parameter:
- [game_claim_dialog.dart](file:///e:/development/SikkaPlay/lib/features/games/shared/utils/game_claim_dialog.dart) (lines 250, 275)
- [spin_screen.dart](file:///e:/development/SikkaPlay/lib/features/games/spin_earn/screens/spin_screen.dart) (line 273)
- [daily_code_screen.dart](file:///e:/development/SikkaPlay/lib/features/home/screens/daily_code_screen.dart) (lines 307, 329)
- [home_screen.dart](file:///e:/development/SikkaPlay/lib/features/home/screens/home_screen.dart) (lines 328, 356)
- [daily_streak_widget.dart](file:///e:/development/SikkaPlay/lib/features/home/widgets/daily_streak_widget.dart) (lines 109, 133)

---

## Verification Plan

### Manual Verification
1. **Received Gifts**: Open profile page. Mismatched or missing gift icons (like Rose) should render their correct emojis instead of generic `🎁`.
2. **Daily Streak Resume**:
   - Miss a daily streak. Confirm the Dialog reads "Missed N days. OK" and charges `skippedDays * 15` coins.
   - Click Resume -> confirm success snackbar displays `Missed N days. OK`.
3. **Rewarded Ads Option**:
   - Click a reward claim (e.g. daily streak milestone, free spins, daily code, social claims).
   - Verify an option dialog "Watch Video? Watch video to claim this reward" pops up *before* the ad plays.
   - Verify clicking CANCEL cancels the claim, and WATCH NOW plays the ad.
