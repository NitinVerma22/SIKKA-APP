import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/features/splash/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Define a minimal test router with splash and mock onboarding destinations
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: Text('Onboarding Mock View')),
        ),
      ],
    );

    // Build the router app
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // Verify SikkaPlay branding displays initially
    expect(find.text('SikkaPlay'), findsOneWidget);

    // Pump to trigger the 2500ms splash screen redirect timer
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    // Verify that navigation correctly transitioned to the onboarding route
    expect(find.text('Onboarding Mock View'), findsOneWidget);
  });
}
