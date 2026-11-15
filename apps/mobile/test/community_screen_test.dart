import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showtime_mobile/screens/community/community_screen.dart';
import 'package:showtime_mobile/app/auth/auth_client.dart';
import 'package:showtime_mobile/app/navigation/app_router.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'mocks/community_fake.dart';

class _VerifiedAuth extends AuthClient {
  _VerifiedAuth() {
    initialized = true;
    verified = true;
  }

  @override
  bool get hasSession => true;
}

GoRouter _router(CommunityFake repository) => GoRouter(
  initialLocation: '/games',
  routes: [
    GoRoute(
      path: '/games',
      builder: (_, _) =>
          CommunityScreen(repository: repository, section: 'games'),
    ),
    GoRoute(
      path: '/community/:section/:itemId',
      builder: (_, state) => CommunityDetailScreen(
        repository: repository,
        section: state.pathParameters['section'] ?? '',
        itemId: state.pathParameters['itemId'] ?? '',
      ),
    ),
  ],
);

void main() {
  testWidgets(
    'authenticated community pages support deep links and guarded routes',
    (tester) async {
      final repository = CommunityFake();
      final auth = _VerifiedAuth();
      final eligibility = ValueNotifier<EligibilityDecision?>(null);
      final router = createShowtimeRouter(
        eligibility: eligibility,
        auth: auth,
        community: repository,
      );
      addTearDown(() {
        router.dispose();
        eligibility.dispose();
        auth.dispose();
      });
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: MidnightThemeData.apply(),
            routerConfig: router,
          ),
        ),
      );
      router.go('/community/games/game-1');
      await tester.pumpAndSettle();
      expect(find.text('Friday Football'), findsOneWidget);
      expect(find.text('Second · pending'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Find your next game'), findsOneWidget);

      router.go('/community/invalid/game-1');
      await tester.pumpAndSettle();
      expect(find.text('Page not found'), findsOneWidget);
    },
  );
  testWidgets('organizer can approve a selected waiting player', (
    tester,
  ) async {
    final repository = CommunityFake();
    final router = _router(repository);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: MidnightThemeData.apply(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friday Football'));
    await tester.pumpAndSettle();
    expect(find.text('First · waitlisted'), findsOneWidget);
    expect(find.text('Second · pending'), findsOneWidget);
    final secondCard = find
        .ancestor(
          of: find.text('Second · pending'),
          matching: find.byType(Column),
        )
        .first;
    await tester.tap(
      find.descendant(of: secondCard, matching: find.text('Approve')),
    );
    await tester.pumpAndSettle();
    expect(
      repository.calls,
      contains('POST games/game-1/applications/a2/approve'),
    );
    expect(find.text('Second · approved'), findsOneWidget);
  });

  testWidgets('failed community load shows retry and recovers', (tester) async {
    final repository = CommunityFake()..failList = true;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: MidnightThemeData.apply(),
          home: CommunityScreen(repository: repository, section: 'games'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load. Check your connection.'), findsOneWidget);
    repository.failList = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Friday Football'), findsOneWidget);
  });

  testWidgets('eligible captain can join an open challenge', (tester) async {
    final repository = CommunityFake();
    final router = _router(repository);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: MidnightThemeData.apply(),
          routerConfig: router,
        ),
      ),
    );
    router.go('/community/challenges/challenge-1');
    await tester.pumpAndSettle();
    expect(find.text('CHALLENGE TEAM'), findsOneWidget);
    await tester.tap(find.text('CHALLENGE TEAM'));
    await tester.pumpAndSettle();
    expect(repository.calls, contains('POST challenges/challenge-1/join'));
  });

  testWidgets('failed approval reports an error without changing status', (
    tester,
  ) async {
    final repository = CommunityFake()..failPost = true;
    final router = _router(repository);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: MidnightThemeData.apply(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friday Football'));
    await tester.pumpAndSettle();
    final secondCard = find
        .ancestor(
          of: find.text('Second · pending'),
          matching: find.byType(Column),
        )
        .first;
    await tester.tap(
      find.descendant(of: secondCard, matching: find.text('Approve')),
    );
    await tester.pump();
    expect(
      find.text(
        'Unable to complete this action. Please check the current status.',
      ),
      findsOneWidget,
    );
    expect(find.text('Second · pending'), findsOneWidget);
  });
}
