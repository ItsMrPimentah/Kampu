import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:showtime_mobile/core/community/community_repository.dart';
import 'package:showtime_mobile/screens/community/community_screen.dart';
import 'package:showtime_mobile/shared/external/utils/result.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'mocks/community_fake.dart';

class _HistoryRepository extends CommunityFake {
  List<CommunityJson> challenges = [];

  @override
  Future<CommunityResult<List<CommunityJson>>> list(String path) async {
    if (path == 'challenges') {
      calls.add('GET challenges');
      if (failList) return const Result.err(CommunityFailure.unavailable);
      return Result.val(challenges);
    }
    return super.list(path);
  }

  @override
  Future<CommunityResult<CommunityJson>> get(String path) async {
    calls.add('GET $path');
    if (path == 'challenges/history-1') {
      return Result.val({
        'match': challenges.firstWhere((item) => item['id'] == 'history-1'),
        'proposals': <CommunityJson>[],
        'votes': <CommunityJson>[],
      });
    }
    return super.get(path);
  }
}

CommunityJson _challenge(
  String id,
  String status,
  String host,
  String? opponent,
  String date,
) => {
  'id': id,
  'host_team_id': 'host',
  'opponent_team_id': opponent == null ? null : 'opponent',
  'host_name': host,
  'opponent_name': opponent,
  'status': status,
  'format': '7v7',
  'region': 'Lisbon',
  'field_name': 'Local pitch',
  'field_status': 'confirmed',
  'scheduled_at': date,
};

GoRouter _router(_HistoryRepository repository, String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(
      path: '/home',
      builder: (_, _) => CommunityDiscoveryScreen(repository: repository),
    ),
    GoRoute(
      path: '/challenges',
      builder: (_, _) =>
          CommunityScreen(repository: repository, section: 'challenges'),
    ),
    GoRoute(
      path: '/community/:section/:itemId',
      builder: (_, state) => CommunityDetailScreen(
        repository: repository,
        section: state.pathParameters['section']!,
        itemId: state.pathParameters['itemId']!,
      ),
    ),
  ],
);

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: MidnightThemeData.apply(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'completed and active challenges remain distinct and open details',
    (tester) async {
      final repository = _HistoryRepository()
        ..challenges = [
          _challenge(
            'history-1',
            'completed',
            'Historic Home',
            'Historic Away',
            '2024-01-02T18:00:00Z',
          ),
          _challenge(
            'open-1',
            'open',
            'Active Home',
            null,
            '2035-02-01T18:00:00Z',
          ),
          _challenge(
            'closed-1',
            'cancelled',
            'Closed Home',
            null,
            '2024-02-01T18:00:00Z',
          ),
        ];
      final router = _router(repository, '/challenges');
      addTearDown(router.dispose);
      await _pump(tester, router);

      expect(find.text('Upcoming & active'), findsOneWidget);
      expect(find.text('Active Home  vs  Seeking opponent'), findsOneWidget);
      await tester.ensureVisible(find.text('Match history'));
      expect(find.text('Match history'), findsOneWidget);
      expect(find.text('Historic Home  vs  Historic Away'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.textContaining('Local pitch'), findsWidgets);
      expect(find.text('View match details →'), findsOneWidget);
      await tester.ensureVisible(find.text('Historic Home  vs  Historic Away'));
      await tester.tap(find.text('Historic Home  vs  Historic Away'));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('GET challenges/history-1'));
      expect(find.text('Historic Home  vs  Historic Away'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.textContaining('2024'), findsOneWidget);
      expect(find.text('CHALLENGE TEAM'), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Other challenges'));
      expect(find.text('Closed Home  vs  Opponent not set'), findsOneWidget);
    },
  );

  testWidgets('empty history and active lists explain their state', (
    tester,
  ) async {
    final router = _router(_HistoryRepository(), '/challenges');
    addTearDown(router.dispose);
    await _pump(tester, router);
    expect(find.text('No active challenges yet.'), findsOneWidget);
    await tester.ensureVisible(find.text('No completed matches yet.'));
    expect(find.text('No completed matches yet.'), findsOneWidget);
    expect(find.text('CREATE CHALLENGE'), findsOneWidget);
  });

  testWidgets('challenge load failure can be retried', (tester) async {
    final repository = _HistoryRepository()..failList = true;
    final router = _router(repository, '/challenges');
    addTearDown(router.dispose);
    await _pump(tester, router);
    expect(find.text('Unable to load. Check your connection.'), findsOneWidget);
    repository.failList = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Upcoming & active'), findsOneWidget);
    await tester.ensureVisible(find.text('No completed matches yet.'));
    expect(find.text('No completed matches yet.'), findsOneWidget);
  });

  testWidgets(
    'home shows only open challenges seeking opponents and keeps next fixture',
    (tester) async {
      final repository = _HistoryRepository()
        ..challenges = [
          _challenge(
            'history-1',
            'completed',
            'Historic Home',
            'Historic Away',
            '2024-01-02T18:00:00Z',
          ),
          _challenge(
            'future-1',
            'confirmed',
            'Future Home',
            'Future Away',
            '2099-01-02T18:00:00Z',
          ),
          _challenge(
            'future-2',
            'confirmed',
            'Later Home',
            'Later Away',
            '2099-01-03T18:00:00Z',
          ),
          _challenge(
            'open-1',
            'open',
            'Active Home',
            null,
            '2099-02-01T18:00:00Z',
          ),
          _challenge(
            'cancelled-1',
            'cancelled',
            'Cancelled Home',
            null,
            '2099-02-01T18:00:00Z',
          ),
          _challenge(
            'expired-1',
            'expired',
            'Expired Home',
            null,
            '2099-02-01T18:00:00Z',
          ),
          _challenge(
            'negotiation-1',
            'negotiation',
            'Negotiating Home',
            'Negotiating Away',
            '2099-02-01T18:00:00Z',
          ),
          _challenge(
            'occupied-1',
            'open',
            'Occupied Home',
            'Occupied Away',
            '2099-02-01T18:00:00Z',
          ),
        ];
      final router = _router(repository, '/home');
      addTearDown(router.dispose);
      await _pump(tester, router);
      expect(find.text('NEXT FIXTURE'), findsOneWidget);
      expect(find.text('Future Home  vs  Future Away'), findsOneWidget);
      expect(find.text('Later Home  vs  Later Away'), findsNothing);
      await tester.ensureVisible(find.text('Seeking Opponent'));
      expect(find.text('1 challenges'), findsOneWidget);
      expect(find.text('Historic Home  vs  Historic Away'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Active Home  vs  Seeking opponent'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Active Home  vs  Seeking opponent'), findsOneWidget);
      expect(find.text('Cancelled Home  vs  Opponent not set'), findsNothing);
      expect(find.text('Expired Home  vs  Opponent not set'), findsNothing);
      expect(find.text('Negotiating Home  vs  Negotiating Away'), findsNothing);
      expect(find.text('Occupied Home  vs  Occupied Away'), findsNothing);
      expect(find.text('Future Home  vs  Future Away'), findsOneWidget);
    },
  );
}
