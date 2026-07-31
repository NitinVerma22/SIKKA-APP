import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/features/splash/screens/splash_screen.dart';
import 'package:sikkaplay/features/onboarding/screens/onboarding_screen.dart';
import 'package:sikkaplay/features/auth/screens/login_screen.dart';
import 'package:sikkaplay/features/auth/screens/register_screen.dart';
import 'package:sikkaplay/features/auth/screens/terms_screen.dart';
import 'package:sikkaplay/features/auth/screens/complete_profile_screen.dart';
import 'package:sikkaplay/features/auth/screens/forgot_password_screen.dart';
import 'package:sikkaplay/features/auth/screens/link_phone_screen.dart';
import 'package:sikkaplay/shared/layouts/main_layout.dart';
import 'package:sikkaplay/features/home/screens/home_screen.dart';
import 'package:sikkaplay/features/playground/screens/playground_lobby_screen.dart';
import 'package:sikkaplay/features/playground/screens/playground_friends_screen.dart';
import 'package:sikkaplay/features/playground/screens/playground_matchmaking_screen.dart';
import 'package:sikkaplay/features/playground/screens/playground_studio_screen.dart';
import 'package:sikkaplay/features/playground/screens/playground_profile_screen.dart';
import 'package:sikkaplay/features/playground/screens/playground_search_screen.dart';
import 'package:sikkaplay/features/games/games_hub/screens/games_hub_screen.dart';
import 'package:sikkaplay/features/games/spin_earn/screens/spin_screen.dart';
import 'package:sikkaplay/features/wallet/screens/wallet_screen.dart';
import 'package:sikkaplay/features/wallet/screens/transaction_history_screen.dart';
import 'package:sikkaplay/features/profile/screens/profile_screen.dart';
import 'package:sikkaplay/features/games/treasure_grid/screens/treasure_grid_screen.dart';
import 'package:sikkaplay/features/games/emoji_memory/screens/emoji_memory_screen.dart';
import 'package:sikkaplay/features/games/math_rush/screens/math_rush_screen.dart';
import 'package:sikkaplay/features/games/shared/screens/game_rules_screen.dart';
import 'package:sikkaplay/features/rewards/screens/my_network_screen.dart';
import 'package:sikkaplay/features/notifications/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:sikkaplay/features/profile/screens/support_screen.dart';
import 'package:sikkaplay/features/splash/screens/language_screen.dart';
import 'package:sikkaplay/features/home/screens/today_tasks_screen.dart';
import 'package:sikkaplay/features/home/screens/surveys_screen.dart';
import 'package:sikkaplay/features/home/screens/app_install_screen.dart';
import 'package:sikkaplay/features/home/screens/visit_earn_screen.dart';
import 'package:sikkaplay/features/home/screens/daily_code_screen.dart';
import 'package:sikkaplay/shared/screens/webview_screen.dart';
import 'package:sikkaplay/shared/screens/vpn_blocked_screen.dart';
import 'package:sikkaplay/shared/screens/maintenance_screen.dart';
import 'package:sikkaplay/shared/screens/update_app_screen.dart';

class AdRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      _handleRouteChange(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      _handleRouteChange(route);
    }
  }
  
  void _handleRouteChange(Route<dynamic> route) {
    // Crash Fix: Removed the problematic Future.delayed and GoRouterState.of(context) call.
    // The previous implementation was causing a "GoError: There is no modal route above the current context"
    // crash in Firebase Crashlytics because the context was no longer valid after the 500ms delay.
    // Since navigational ads were already removed for policy compliance, this logic is safely removed.
  }
}


final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    observers: [AdRouteObserver()],
    routes: [
      GoRoute(
        path: '/vpn_blocked',
        builder: (context, state) => const VpnBlockedScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: '/update_app',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final updateUrl = extra['updateUrl'] as String;
          return UpdateAppScreen(updateUrl: updateUrl);
        },
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/link-phone',
        builder: (context, state) => const LinkPhoneScreen(),
      ),
      GoRoute(
        path: '/complete_profile',
        builder: (context, state) {
          final userData = state.extra as Map<String, dynamic>;
          return CompleteProfileScreen(userData: userData);
        },
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/webview',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final url = extra['url'] as String;
          final title = extra['title'] as String;
          return WebViewScreen(url: url, title: title);
        },
      ),
      // Standalone Fullscreen Game Routes (Outside ShellRoute)
      GoRoute(
        path: '/playground/studio',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final partner = state.extra;
          return PlaygroundStudioScreen(partner: partner);
        },
      ),
      GoRoute(
        path: '/games/rules',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as GameRulesArgs;
          return GameRulesScreen(args: args);
        },
      ),
      GoRoute(
        path: '/games/spin_earn',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SpinScreen(),
      ),
      GoRoute(
        path: '/games/treasure_grid',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TreasureGridScreen(),
      ),
      GoRoute(
        path: '/games/emoji_memory',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EmojiMemoryScreen(),
      ),
      GoRoute(
        path: '/games/math_rush',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MathRushScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
            routes: [
              GoRoute(
                path: 'today_tasks',
                builder: (context, state) => const TodayTasksScreen(),
              ),
              GoRoute(
                path: 'surveys',
                builder: (context, state) => const SurveysScreen(),
              ),
              GoRoute(
                path: 'app_install',
                builder: (context, state) => const AppInstallScreen(),
              ),
              GoRoute(
                path: 'visit_earn',
                builder: (context, state) => const VisitEarnScreen(),
              ),
              GoRoute(
                path: 'daily_code',
                builder: (context, state) => const DailyCodeScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/playground',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlaygroundLobbyScreen()),
            routes: [
              GoRoute(
                path: 'friends',
                builder: (context, state) => const PlaygroundFriendsScreen(),
              ),
              GoRoute(
                path: 'matchmaking',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return PlaygroundMatchmakingScreen(gender: extra['gender'] ?? 'male');
                },
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) {
                  final username = state.extra as String;
                  return PlaygroundProfileScreen(username: username);
                },
              ),
              GoRoute(
                path: 'search',
                builder: (context, state) => const PlaygroundSearchScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/games',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GamesHubScreen()),
          ),
          GoRoute(
            path: '/wallet',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WalletScreen()),
            routes: [
              GoRoute(
                path: 'transactions',
                builder: (context, state) => const TransactionHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
          GoRoute(
            path: '/my_network',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MyNetworkScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationScreen()),
          ),
        ],
      ),
    ],
  );
});
