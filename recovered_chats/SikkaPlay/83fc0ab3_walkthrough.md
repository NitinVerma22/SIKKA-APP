# SikkaPlay Phase 1 UI Foundation Walkthrough

We have successfully constructed the Phase 1 UI Foundation for **SikkaPlay**, adhering to the responsive design tokens, modular feature-first architecture, performance-optimized visual layouts, and interactive state guidelines.

## Architecture Summary
The application follows a **feature-first** structure:
- **`core/`**: Houses app-wide theme details, scaling sizing tokens, performance-oriented custom animations, and layout dimensions.
- **`shared/`**: Contains core reusable layouts and widgets such as `PremiumCard`, `PremiumButton`, `GullakOrb`, and navigation shells.
- **`features/`**: Modular feature folders (e.g. `home`, `reels`, `games`, `wallet`, `profile`, `rewards`) keeping files flat, focused, and maintainable.
- **`routes/`**: Integrates `GoRouter` shell route declarations.

---

## File Walkthrough

### 1. Design & Animation Tokens
- **[app_sizes.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/core/constants/app_sizes.dart)**: Contains spacing tokens (`xs` through `xxl`), border radii, and utility methods `getPadding` and `getResponsiveFontSize` to ensure layout consistency across mobile devices.
- **[app_colors.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/core/constants/app_colors.dart)**: Defines Royal Purple and Vibrant Cyan color palettes along with high-fidelity gradients (`primaryGradient`, `goldGradient`) and premium soft shadows.
- **[custom_animations.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/core/animations/custom_animations.dart)**: Implements performance-friendly animation wrappers:
  - `HoverWidget`: Subtle bobbing motion (great for the Gullak Orb).
  - `PulseWidget`: Breathing scale updates (perfect for coin notifications).
  - `FadeInSlideWidget`: Clean entrance offset slide.

### 2. Reusable Premium Widgets
- **[premium_card.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/shared/widgets/premium_card.dart)**: Premium card using subtle borders and soft shadows, avoiding expensive BackdropFilter blurs for superior Android rendering.
- **[premium_button.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/shared/widgets/premium_button.dart)**: Supports custom linear gradients, suffix/prefix icons, loading states, and features micro-scaling animation upon user press.
- **[streak_indicator.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/shared/widgets/streak_indicator.dart)**: Shows streak progress via customized standard circular indicators.
- **[gullak_orb.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/shared/widgets/gullak_orb.dart)**: Floating glowing orb representing the piggy bank (Gullak) that detects taps and animates scales.

### 3. Core Pages
- **[splash_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/splash/screens/splash_screen.dart)**: Pulsing brand logo overlay transitioning to onboarding.
- **[onboarding_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/onboarding/screens/onboarding_screen.dart)**: 3-page slideshow illustrating coin wins with a dots progress bar.
- **[main_layout.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/shared/layouts/main_layout.dart)**: Shell wrapper displaying active route contents alongside a floating pill navigation bar.
- **[home_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/home/screens/home_screen.dart)**: The central dashboard binding wallet overview cards, daily streak, the interactive Gullak Orb, and recent transactions. It includes a **"Reset Orb"** utility for replay testing.
- **[reels_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/reels/screens/reels_screen.dart)**: Implements vertical swipe page sheets detailing watch rewards, micro-actions (likes/shares), and horizontal progress bars.
- **[games_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/games/screens/games_screen.dart)**: Curated category filtered arcade lists featuring interactive dialog prompts.
- **[wallet_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/wallet/screens/wallet_screen.dart)**: Displays coin earnings and UPI/bank withdrawal mocks.
- **[profile_screen.dart](file:///c:/Users/Nitin/OneDrive/Desktop/Mission/SikkaPlay/lib/features/profile/screens/profile_screen.dart)**: Visual XP bar indicator, statistics grids, and settings toggle switches.

---

## State Bindings & Interaction Flow
- Both `HomeScreen` and `WalletScreen` listen to the centralized `homeProvider` Riverpod state (`lib/features/home/controllers/home_controller.dart`).
- When a user taps the Gullak Orb, it triggers the claim state, adds coins, increases the daily streak, and pushes a notification to `recentRewards` list.
- Both dashboards instantly reflect these coin increases in real-time.
- If the reward has already been claimed for the day, a SnackBar pops up offering to **"Reset (Replay)"** the claim status, making manual validation easy and fun.
