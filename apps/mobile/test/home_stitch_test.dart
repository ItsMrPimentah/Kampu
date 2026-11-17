import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:showtime_mobile/discovery/home_screen.dart';
import 'package:showtime_mobile/navigation/app_router.dart';
import 'package:showtime_mobile/onboarding/eligibility.dart';
import 'package:showtime_mobile/theme/midnight_theme.dart';
import 'package:showtime_mobile/theme/stitch_components.dart';

void main() {
  Future<GoRouterHarness> pumpHome(WidgetTester tester) async {
    final eligibility = ValueNotifier<EligibilityDecision?>(
      evaluateEligibility('2000-01-01'),
    );
    final router = createShowtimeRouter(eligibility: eligibility);
    await tester.binding.setSurfaceSize(const Size(390, 4200));
    await tester.pumpWidget(
      MaterialApp.router(
        theme: MidnightThemeData.apply(),
        routerConfig: router,
      ),
    );
    router.go('/home');
    await tester.pumpAndSettle();
    return GoRouterHarness(router: router, eligibility: eligibility);
  }

  testWidgets('Home renders the Stitch feed hierarchy and local context', (
    tester,
  ) async {
    final harness = await pumpHome(tester);
    addTearDown(() {
      harness.dispose();
      tester.binding.setSurfaceSize(null);
    });

    expect(find.text('Discover'), findsWidgets);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.text('Welcome back, Alex Morgan', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Showtime FC', skipOffstage: false), findsWidgets);
    expect(
      find.text('LOCAL PREVIEW · CACHED', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('UPCOMING FIXTURE', skipOffstage: false), findsOneWidget);
    expect(find.text('DISCOVERY FILTERS', skipOffstage: false), findsOneWidget);
    expect(find.text('Team challenges', skipOffstage: false), findsOneWidget);
    expect(find.text('Open games', skipOffstage: false), findsOneWidget);
    expect(find.text('Manage teams', skipOffstage: false), findsOneWidget);
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.byTooltip('Notifications, 3 unread'), findsOneWidget);
    expect(
      find.byTooltip('Alex Morgan avatar', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Open challenge with Alfama United', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byTooltip(
        'Friday night kickabout, 2 slots open',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  Future<void> jumpHome(WidgetTester tester, double offset) async {
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(offset);
    await tester.pump();
  }

  testWidgets('Home filters games and keeps full games unavailable', (
    tester,
  ) async {
    final harness = await pumpHome(tester);
    addTearDown(() {
      harness.dispose();
      tester.binding.setSurfaceSize(null);
    });

    expect(find.text('Game full', skipOffstage: false), findsOneWidget);
    await jumpHome(tester, 500);
    final formatAction = find.widgetWithText(
      StitchFilterChip,
      '7v7',
      skipOffstage: false,
    );
    tester.widget<StitchFilterChip>(formatAction).onSelected(true);
    await tester.pump();
    await jumpHome(tester, 2000);

    expect(
      find.text('Wednesday league warm-up', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Friday night kickabout'), findsNothing);
    expect(find.text('Sunday futsal run'), findsNothing);
    expect(find.text('Game full', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Home remains usable across supported mobile widths', (
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

    for (final width in [360.0, 390.0, 430.0]) {
      await tester.binding.setSurfaceSize(Size(width, 844));
      await tester.pumpWidget(
        MaterialApp.router(
          theme: MidnightThemeData.apply(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(padding: const EdgeInsets.only(bottom: 24)),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Discover'), findsWidgets);
      expect(find.text('Manage teams', skipOffstage: false), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Home layout exception at width $width',
      );
    }
  });

  testWidgets('Home exposes cached refresh and local action states', (
    tester,
  ) async {
    final harness = await pumpHome(tester);
    addTearDown(() {
      harness.dispose();
      tester.binding.setSurfaceSize(null);
    });

    await jumpHome(tester, 500);
    final challengeAction = find.widgetWithText(
      TextButton,
      'Challenge',
      skipOffstage: false,
    );
    tester.widget<TextButton>(challengeAction.first).onPressed!();
    await tester.pump();
    expect(find.text('Saved', skipOffstage: false), findsOneWidget);

    await jumpHome(tester, 700);
    final joinAction = find.widgetWithText(
      StitchGradientButton,
      'Join game',
      skipOffstage: false,
    );
    tester.widget<StitchGradientButton>(joinAction.first).onPressed!();
    await tester.pump();
    expect(find.text('Joined locally', skipOffstage: false), findsOneWidget);
    expect(
      find.text(
        'Your open-game place is held in this local preview.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    final retryAction = find.widgetWithText(
      TextButton,
      'Retry',
      skipOffstage: false,
    );
    tester.widget<TextButton>(retryAction.first).onPressed!();
    await tester.pump();
    expect(
      find.byType(LinearProgressIndicator, skipOffstage: false),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        'Local refresh complete · cached results retained.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}

class GoRouterHarness {
  GoRouterHarness({required this.router, required this.eligibility});

  final GoRouter router;
  final ValueNotifier<EligibilityDecision?> eligibility;

  void dispose() {
    router.dispose();
    eligibility.dispose();
  }
}
