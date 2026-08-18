# Goal: Add Premium UI/UX & Performance Features

We will implement the following 4 features to elevate the website to a world-class standard:
1. Page Transition Animations (Framer Motion)
2. Custom Animated Cursor
3. Scroll Progress Indicator
4. Route-level Lazy Loading (Performance Optimization)

> [!IMPORTANT]  
> Please review the open questions below before approving this plan.

## Open Questions

1. **Persistent Navbar/Footer**: Currently, the `<Layout>` (which includes the Navbar and Footer) is imported individually inside every single page. If we add page transitions, the Navbar and Footer will also "fade out" and "fade in" on every click. **Should I refactor the app to have a single, persistent Navbar/Footer so they stay perfectly static while only the main content animates?** (Recommended for a premium feel).
2. **Cursor Color**: I plan to make the custom cursor a glowing cyan/blue dot that expands when hovering. Does this work, or would you prefer a different color (like amber)?

## Proposed Changes

### Global UI Components
#### [NEW] `src/components/CustomCursor.tsx`
- Create a custom cursor component using `framer-motion` that tracks the mouse position (`clientX`, `clientY`).
- Add a hover effect that scales the cursor up when over interactive elements.

#### [NEW] `src/components/ScrollProgress.tsx`
- Implement a thin progress bar fixed to the top of the window using `framer-motion`'s `useScroll` and `scaleX`.
- Style it with the brand's cyan or amber gradient.

### Layout & Routing
#### [MODIFY] `src/components/Layout.tsx`
- (Pending answer to Q1) Either add a `motion.div` wrapper around the `children` here for transitions, or remove Navbar/Footer from here and move them to `App.tsx` to create a true persistent layout.

#### [MODIFY] `src/App.tsx`
- Convert all static page imports (e.g., `import Index from "./pages/Index"`) to React `lazy()` imports.
- Wrap the `<Routes>` in `<Suspense>` with a loading fallback.
- Wrap the `<Routes>` in `AnimatePresence mode="wait"` to enable exit animations.
- Integrate `<CustomCursor />` and `<ScrollProgress />`.

## Verification Plan

### Manual Verification
- Navigate between Home, Services, and Contact to ensure page transitions trigger smoothly (and ideally, Navbar/Footer stay static if Q1 is approved).
- Move the mouse across the screen to test the custom cursor delay/spring physics.
- Scroll down a long page to verify the top progress bar fills up accurately.
- Check the network tab in dev tools to verify JavaScript chunks are loaded lazily upon navigation.
