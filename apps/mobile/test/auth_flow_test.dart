import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/app/auth_provider.dart';
import 'package:showtime_mobile/main.dart';

import 'mocks/auth_fake.dart';

void main() {
  testWidgets(
    'unverified sign-in stays at OTP until a valid code and sign-out returns to login',
    (tester) async {
      final auth = FakeAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(auth)],
          child: const ShowtimeApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('login-identifier')),
        '+351912345678',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password')),
        'Password1!',
      );
      await tester.ensureVisible(find.text('SIGN IN & PLAY'));
      await tester.tap(find.text('SIGN IN & PLAY'));
      await tester.pumpAndSettle();
      expect(find.text('VERIFY YOUR PHONE'), findsOneWidget);
      expect(find.text('Discover'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('verification-code')),
        '000000',
      );
      await tester.tap(find.text('CONFIRM & ENTER'));
      await tester.pumpAndSettle();
      expect(find.text('VERIFY YOUR PHONE'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('verification-code')),
        '123456',
      );
      await tester.tap(find.text('CONFIRM & ENTER'));
      await tester.pumpAndSettle();
      expect(find.text('Discover'), findsWidgets);
      await tester.tap(find.byTooltip('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('WELCOME BACK, BALLER'), findsOneWidget);
    },
  );

  testWidgets('verified sign-in enters the authenticated shell', (
    tester,
  ) async {
    final auth = FakeAuthRepository(verified: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const ShowtimeApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('login-identifier')),
      'player@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'Password1!',
    );
    await tester.ensureVisible(find.text('SIGN IN & PLAY'));
    await tester.tap(find.text('SIGN IN & PLAY'));
    await tester.pumpAndSettle();
    expect(find.text('Discover'), findsWidgets);
    expect(find.text('VERIFY YOUR PHONE'), findsNothing);
  });
}
