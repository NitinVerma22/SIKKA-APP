# Implementation Plan - SikkaPlay Phase 1 UI Foundation (Optimized)

Create a clean, scalable, Flutter-only UI foundation for **SikkaPlay**—a gamified engagement app. This implementation focuses on simplicity, mobile performance (especially on mid-range Android devices), micro-interactions, lightweight animations, and a scalable, feature-first structure.

## Technical & Performance Guidelines (Updated)

> [!IMPORTANT]
> - **Light Theme Only**: Clean light theme with soft backgrounds, vibrant accents (violet, cyan, subtle orange glow).
> - **Performance first**: Avoid heavy or deeply stacked glassmorphism effects (`BackdropFilter` with large blurs) to maintain high FPS on mid-range Android devices. Use light white borders, gradients, and soft shadows instead.
> - **Simple Customization**: Avoid complex custom painters where standard widgets like container borders, gradients, and clips suffice.
> - **Riverpod**: Used for simple UI states (e.g. active navigation index, daily streak state, wallet animations).
> - **Scalable Typography & Spacing**: Centralized in constants to ensure uniform responsive spacing.

---

## Proposed Changes

### Component 1: Core Setup & Shared Utilities
Initialize design tokens and responsive scaling functions.

#### [NEW] [app_sizes.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/core/constants/app_sizes.dart)
Centralized responsive spacing, padding, borders, and margins. Avoids hardcoded layout values.

#### [NEW] [app_colors.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/core/constants/app_colors.dart)
Define color constants, gradients, and shadow presets.

#### [NEW] [custom_animations.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/core/animations/custom_animations.dart)
Performance-friendly animation wrappers:
- **Hover/Floating Builder**: Light offset animations using `AnimatedBuilder` + `Transform.translate` without intensive canvas redraws.
- **Pulse Wrapper**: Light scale adjustments.

---

### Component 2: Shared & Reusable Premium Widgets
Create lightweight reusable widgets to avoid code duplication.

#### [NEW] [premium_card.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/shared/widgets/premium_card.dart)
High-performance card with subtle gradients and clean borders, delivering a modern glass-like vibe without the performance hit of `BackdropFilter` on older devices.

#### [NEW] [premium_button.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/shared/widgets/premium_button.dart)
A reusable, bouncy gradient button with dynamic scaling on tap.

#### [NEW] [streak_indicator.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/shared/widgets/streak_indicator.dart)
Clean, lightweight progress ring using standard Flutter `CircularProgressIndicator` customized with a gradient or stylized Container layout.

#### [NEW] [gullak_orb.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/shared/widgets/gullak_orb.dart)
A floating, interactive container orb representing the Gullak piggy bank. Triggers a simple particle emission overlay on click.

---

### Component 3: Layout & Shell Navigation

#### [NEW] [main_layout.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/shared/layouts/main_layout.dart)
Persistent scaffold containing:
- Shell route contents.
- A floating, pill-shaped navigation bar with clean animation transitions.

---

### Component 4: Features
Implement feature screens matching instructions.

#### [NEW] [splash_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/splash/screens/splash_screen.dart)
Animated logo and soft fade transition to `/onboarding`.

#### [NEW] [onboarding_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/onboarding/screens/onboarding_screen.dart)
Clean PageView illustrating the app's games, gullak, and reels. Simple dot indicator.

#### [NEW] [home_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/home/screens/home_screen.dart)
Dashboard with:
- Wallet balance overview.
- Streak container & indicator.
- Floating Gullak orb.
- Claim Reward triggers and list of recent claims.

#### [NEW] [reels_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/reels/screens/reels_screen.dart)
Full-screen TikTok-style layout featuring minimal overlays, vertical swipe, and progress header.

#### [NEW] [games_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/games/screens/games_screen.dart)
A beautiful grid of game arcade cards with rich gradients.

#### [NEW] [wallet_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/wallet/screens/wallet_screen.dart)
Wallet details, withdrawal popup placeholder, and animated filter tabs.

#### [NEW] [profile_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/profile/screens/profile_screen.dart)
Gamified profile metrics card, statistics panel, and toggle preference list.

#### [NEW] [rewards_overlay.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/rewards/widgets/rewards_overlay.dart)
Simple particle-burst effects using a custom lightweight overlays to keep frames stable.

---

## Verification Plan

### Automated Verification
- Run `flutter analyze` inside `SikkaPlay` directory to ensure static safety and standard practices.
- Run `flutter test` to verify everything is compilation-sound.
