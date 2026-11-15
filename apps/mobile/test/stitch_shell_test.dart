import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/app/navigation/app_router.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  testWidgets('Stitch dock remains usable across supported mobile widths', (
    tester,
  ) async {
    final eligibility = ValueNotifier<EligibilityDecision?>(
      evaluateEligibility('2000-01-01'),
    );
    final router = createShowtimeRouter(eligibility: eligibility);
    addTearDown(() {
      router.dispose();
      eligibility.dispose();
    });

    for (final width in [360.0, 390.0, 430.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: MidnightThemeData.apply(),
            routerConfig: router,
          ),
        ),
      );
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Discover'), findsWidgets);
      expect(find.text('Challenges'), findsOneWidget);
      expect(find.text('Pitches'), findsOneWidget);
      expect(find.text('Squad'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('dock stays compact instead of expanding to the viewport', (
    tester,
  ) async {
    final eligibility = ValueNotifier<EligibilityDecision?>(
      evaluateEligibility('2000-01-01'),
    );
    final router = createShowtimeRouter(eligibility: eligibility);
    addTearDown(() {
      router.dispose();
      eligibility.dispose();
      tester.binding.setSurfaceSize(null);
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: MidnightThemeData.apply(),
          routerConfig: router,
        ),
      ),
    );
    router.go('/home');
    await tester.pumpAndSettle();

    final dock = find.byKey(const ValueKey('stitch-navigation-dock'));
    expect(dock, findsOneWidget);
    expect(tester.getSize(dock).height, 68);
  });

  testWidgets('dock destination selection is exposed semantically', (
    tester,
  ) async {
    final eligibility = ValueNotifier<EligibilityDecision?>(
      evaluateEligibility('2000-01-01'),
    );
    final router = createShowtimeRouter(eligibility: eligibility);
    addTearDown(() {
      router.dispose();
      eligibility.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: MidnightThemeData.apply(),
          routerConfig: router,
        ),
      ),
    );
    router.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pitches'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/pitches');
    expect(find.text('Pitches'), findsWidgets);
  });
}
