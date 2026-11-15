import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/app/auth_provider.dart';
import 'package:showtime_mobile/main.dart';

import 'mocks/auth_fake.dart';

void main() {
  testWidgets('requires sign in before showing the authenticated shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const ShowtimeApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('WELCOME BACK, BALLER'), findsOneWidget);
    expect(find.text('SIGN IN & PLAY'), findsOneWidget);
    expect(find.text('Discover'), findsNothing);
  });
}
