import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/screens/teams/team_hub_screen.dart';

void main() {
  testWidgets(
    'creates a team and shows roster readiness and invitation state',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: TeamHubScreen())),
      );
      await tester.enterText(
        find.byKey(const ValueKey('team-name')),
        'Lisbon Lions',
      );
      tester.testTextInput.hide();
      await tester.pump();
      await tester.ensureVisible(find.text('Create team'));
      await tester.tap(find.text('Create team'));
      await tester.pumpAndSettle();
      expect(find.text('Team created as captain in Lisbon.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('invite-player')),
        'player-2',
      );
      await tester.tap(find.text('Send invitation'));
      await tester.pump();
      expect(find.text('Invitation created for player-2.'), findsOneWidget);
      expect(find.text('Needs 4 more eligible player(s)'), findsOneWidget);
      await tester.ensureVisible(find.text('Coordinate matches'));
      expect(find.text('Coordinate matches'), findsOneWidget);
    },
  );
}
