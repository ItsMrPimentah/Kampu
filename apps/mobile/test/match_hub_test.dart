import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/screens/matches/match_hub_screen.dart';

void main() {
  testWidgets(
    'covers challenge publication, Fusion, attendance, and completion',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: MatchHubScreen())),
      );
      await tester.tap(find.text('Publish challenge'));
      await tester.pump();
      expect(find.text('Status: Open'), findsOneWidget);
      await tester.tap(find.text('Advance challenge'));
      await tester.pump();
      await tester.tap(find.text('Advance challenge'));
      await tester.pump();
      await tester.tap(find.text('Advance challenge'));
      await tester.pump();
      await tester.tap(find.text('Advance challenge'));
      await tester.pump();
      await tester.tap(find.text('Advance challenge'));
      await tester.pump();
      expect(find.text('Status: Completed'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-attendance-button')));
      await tester.pumpAndSettle();
      expect(find.text('Attendance confirmed'), findsOneWidget);
    },
  );
}
