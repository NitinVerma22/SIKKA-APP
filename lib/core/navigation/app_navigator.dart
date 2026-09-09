import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/routes/app_router.dart';

/// Tracks shell/tab locations so system back can walk Home → A → B → C
/// even when GoRouter tab switches use `go()` (replace) instead of a real stack.
final routeHistoryProvider = StateProvider<List<String>>((ref) => ['/home']);

/// Shell sibling destinations that replace each other (no Navigator stack entry).
bool isShellTabLocation(String location) {
  if (location == '/home' ||
      location == '/games' ||
      location == '/wallet' ||
      location == '/profile' ||
      location == '/playground' ||
      location == '/playground/friends' ||
      location == '/my_network' ||
      location == '/notifications') {
    return true;
  }
  return false;
}

String? currentLocationOf(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.path;
  } catch (_) {
    return null;
  }
}

class AppNavigator {
  AppNavigator._();

  /// Replace to [location] and record it on the back stack.
  static void go(
    BuildContext context,
    WidgetRef ref,
    String location, {
    Object? extra,
  }) {
    _record(ref, location);
    context.go(location, extra: extra);
  }

  /// Push when the route can stack; for shell tab siblings, uses [go] + history.
  static void push(
    BuildContext context,
    WidgetRef ref,
    String location, {
    Object? extra,
  }) {
    if (isShellTabLocation(location)) {
      go(context, ref, location, extra: extra);
      return;
    }
    context.push(location, extra: extra);
  }

  /// Auth / splash style jumps that clear history.
  static void resetTo(
    BuildContext context,
    WidgetRef ref,
    String location, {
    Object? extra,
  }) {
    ref.read(routeHistoryProvider.notifier).state = [location];
    context.go(location, extra: extra);
  }

  /// Same as [go] but for call sites without [WidgetRef].
  static void goWithContainer(
    BuildContext context,
    String location, {
    Object? extra,
  }) {
    final container = ProviderScope.containerOf(context);
    _recordWithContainer(container, location);
    context.go(location, extra: extra);
  }

  static void pushWithContainer(
    BuildContext context,
    String location, {
    Object? extra,
  }) {
    if (isShellTabLocation(location)) {
      goWithContainer(context, location, extra: extra);
      return;
    }
    context.push(location, extra: extra);
  }

  static void _record(WidgetRef ref, String location) {
    final history = ref.read(routeHistoryProvider);
    if (history.isNotEmpty && history.last == location) return;
    var next = [...history, location];
    if (next.length > 40) {
      next = next.sublist(next.length - 40);
    }
    ref.read(routeHistoryProvider.notifier).state = next;
  }

  static void _recordWithContainer(ProviderContainer container, String location) {
    final history = container.read(routeHistoryProvider);
    if (history.isNotEmpty && history.last == location) return;
    var next = [...history, location];
    if (next.length > 40) {
      next = next.sublist(next.length - 40);
    }
    container.read(routeHistoryProvider.notifier).state = next;
  }

  /// Returns true if back was handled. False means caller may show exit confirm.
  static bool handleSystemBack(BuildContext context, WidgetRef ref) {
    final currentLocation = currentLocationOf(context) ?? '/home';
    final onShellTab = isShellTabLocation(currentLocation);

    // 1. If user is NOT on a shell tab (e.g., inside a fullscreen game,
    //    daily_code sub-route, etc.), try real navigator pops first.
    if (!onShellTab) {
      final rootNav = rootNavigatorKey.currentState;
      if (rootNav != null && rootNav.canPop()) {
        rootNav.pop();
        return true;
      }

      final shellNav = shellNavigatorKey.currentState;
      if (shellNav != null && shellNav.canPop()) {
        shellNav.pop();
        return true;
      }
    }

    // 2. Use our custom route history to walk back through tabs.
    //    Navigator canPop/pop is unreliable for shell tab switches done via
    //    go() because go() replaces the route instead of pushing.
    final history = ref.read(routeHistoryProvider);
    if (history.length > 1) {
      final newHistory = List<String>.from(history)..removeLast();
      ref.read(routeHistoryProvider.notifier).state = newHistory;
      context.go(newHistory.last);
      return true;
    }

    // 3. If there's no history but user is not on /home, go back to home.
    if (currentLocation != '/home') {
      ref.read(routeHistoryProvider.notifier).state = ['/home'];
      context.go('/home');
      return true;
    }

    // 4. Nothing left — caller should show "press back again to exit".
    return false;
  }
}
