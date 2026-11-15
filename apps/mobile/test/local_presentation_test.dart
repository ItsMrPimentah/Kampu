import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/core/discovery/local_fixtures.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  test('local fixture loading is deterministic and backend independent', () {
    final first = LocalFixtures.load();
    final second = LocalFixtures.load();

    expect(first.homeContext.displayName, 'Alex Morgan');
    expect(first.homeContext.initials, 'AM');
    expect(first.homeContext.activeTeam, 'Showtime FC');
    expect(first.homeContext.locationLabel, 'Lisbon · Area 01');
    expect(first.homeContext.unreadNotifications, 3);
    expect(first.homeContext.displayName, second.homeContext.displayName);
    expect(first.snapshot.label, 'LOCAL PREVIEW · CACHED');
    expect(first.snapshot.isOffline, isTrue);
    expect(first.snapshot.capturedAt, second.snapshot.capturedAt);
    expect(first.fixture.id, second.fixture.id);
    expect(
      first.challenges.map((challenge) => challenge.id).toList(),
      second.challenges.map((challenge) => challenge.id).toList(),
    );
    expect(
      first.openGames.map((game) => game.id).toList(),
      second.openGames.map((game) => game.id).toList(),
    );
    expect(first.openGames, isNotEmpty);
    expect(
      first.openGames.any(
        (game) => game.approvedPlayers >= game.playerCapacity,
      ),
      isTrue,
    );
    expect(first.fixture.venue, isNotEmpty);
    expect(first.challenges, isNotEmpty);
    expect(first.venues, isNotEmpty);
    expect(first.lastSyncedAt, first.snapshot.capturedAt);
    expect(
      first.venues.map((venue) => venue.id).toList(),
      second.venues.map((venue) => venue.id).toList(),
    );
    expect(
      first.challenges
          .singleWhere((challenge) => challenge.id == 'challenge-001')
          .revisions
          .length,
      2,
    );
  });

  test('Midnight exposes required palette and readable typography', () {
    final tokens = MidnightTheme.defaults;
    expect(tokens.voidColor.toARGB32(), 0xFF0F101A);
    expect(tokens.carbon.toARGB32(), 0xFF151621);
    expect(tokens.gunmetal.toARGB32(), 0xFF1F2433);
    expect(tokens.iris.toARGB32(), 0xFF5B63D3);
    expect(tokens.periwinkle.toARGB32(), 0xFF7C87F7);
    expect(tokens.frost.toARGB32(), 0xFFC9D3EE);
    expect(tokens.monoStyle.fontFamily, 'JetBrains Mono');
  });
}
