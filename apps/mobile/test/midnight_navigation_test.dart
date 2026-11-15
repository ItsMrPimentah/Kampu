import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showtime_mobile/app/navigation/app_router.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  late ValueNotifier<EligibilityDecision?> eligibility;
  late GoRouter router;

  setUp(() {
    eligibility = ValueNotifier<EligibilityDecision?>(null);
    router = createShowtimeRouter(eligibility: eligibility);
  });

  tearDown(() {
    router.dispose();
    eligibility.dispose();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: MidnightThemeData.apply(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('guards direct authenticated destinations until eligibility', (
    tester,
  ) async {
    await pumpApp(tester);
    router.go('/pitches');
    await tester.pumpAndSettle();
    expect(find.text('Join Showtime'), findsOneWidget);

    eligibility.value = evaluateEligibility('2000-01-01');
    router.go('/pitches');
    await tester.pumpAndSettle();
    expect(find.text('SMART SCHEDULER · AREA 01'), findsOneWidget);
    expect(find.text('Pitches'), findsWidgets);
  });

  testWidgets(
    'preserves shell and parent destination through challenge detail back stack',
    (tester) async {
      eligibility.value = evaluateEligibility('2000-01-01');
      await pumpApp(tester);
      router.go('/challenges/challenge-001');
      await tester.pumpAndSettle();

      expect(find.text('Challenge negotiation'), findsOneWidget);
      expect(find.text('Challenges'), findsWidgets);

      router.pop();
      await tester.pumpAndSettle();
      expect(
        find.text('Team negotiations', skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets('preserves pitch detail context and returns to Pitches', (
    tester,
  ) async {
    eligibility.value = evaluateEligibility('2000-01-01');
    await pumpApp(tester);
    router.go('/pitches/venue-001');
    await tester.pumpAndSettle();

    expect(find.text('Pitch details'), findsOneWidget);
    expect(find.text('Pitches'), findsWidgets);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('SMART SCHEDULER · AREA 01'), findsOneWidget);
  });

  testWidgets('renders a useful unknown-route destination', (tester) async {
    eligibility.value = evaluateEligibility('2000-01-01');
    await pumpApp(tester);
    router.go('/not-a-real-destination');
    await tester.pumpAndSettle();
    expect(find.text('Page not found'), findsOneWidget);
  });
}
