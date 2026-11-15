import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/screens/venues/venue_hub_screen.dart';

void main() {
  testWidgets('shows native booking and external declaration states', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: VenueHubScreen())),
    );
    expect(
      find.textContaining(
        'Native booking · operator verified · source: PlayArena',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Reserve'));
    await tester.pump();
    expect(
      find.textContaining('Booking status: Pending provider confirmation'),
      findsOneWidget,
    );
    await tester.tap(find.text('Use external booking'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextField),
      'https://external.example/booking',
    );
    await tester.tap(find.text('Declare reservation'));
    await tester.pump();
    expect(find.textContaining('Externally declared'), findsOneWidget);
  });
}
