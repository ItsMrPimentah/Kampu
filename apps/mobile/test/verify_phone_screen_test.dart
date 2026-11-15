import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/screens/auth/verify_phone_screen.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  Future<void> showScreen(
    WidgetTester tester, {
    bool? sent,
    Future<bool> Function(String)? verify,
    Future<bool> Function()? resend,
    Future<bool> Function()? signOut,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: MidnightThemeData.apply(),
          home: VerifyPhoneScreen(
            phone: '+351912345678',
            smsSent: sent,
            onVerify: verify ?? (_) async => true,
            onResend: resend ?? () async => true,
            onSignOut: signOut ?? () async => true,
          ),
        ),
      ),
    );
  }

  testWidgets('shows only known SMS delivery status', (tester) async {
    await showScreen(tester);
    expect(
      find.text('Enter your 6-digit code, or request a new SMS.'),
      findsOneWidget,
    );
    await showScreen(tester, sent: false);
    expect(
      find.text('We could not send the SMS. Request a new code.'),
      findsOneWidget,
    );
    expect(find.text('Resend SMS'), findsOneWidget);
    await showScreen(tester, sent: true);
    expect(
      find.text('Enter the 6-digit code sent to +351912345678.'),
      findsOneWidget,
    );
  });

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('verification feedback fits at $width logical pixels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await showScreen(tester, sent: false);
      await tester.tap(find.text('CONFIRM & ENTER'));
      await tester.pump();
      expect(find.text('Enter the 6-digit code.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('rejects incomplete code and submits pasted six digits', (
    tester,
  ) async {
    final codes = <String>[];
    await showScreen(
      tester,
      verify: (code) async {
        codes.add(code);
        return false;
      },
    );
    final field = find.byKey(const ValueKey('verification-code'));
    final textField = tester.widget<TextField>(field);
    expect(textField.autofillHints, contains(AutofillHints.oneTimeCode));
    await tester.enterText(field, '12345');
    await tester.tap(find.text('CONFIRM & ENTER'));
    await tester.pump();
    expect(codes, isEmpty);
    expect(find.text('Enter the 6-digit code.'), findsOneWidget);
    await tester.enterText(field, '123456');
    await tester.tap(find.text('CONFIRM & ENTER'));
    await tester.pumpAndSettle();
    expect(codes, ['123456']);
    expect(
      find.text(
        'Unable to verify your phone. Please try again or request a new SMS.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('resend and sign-out report their own failures and allow retry', (
    tester,
  ) async {
    var resendCalls = 0;
    await showScreen(
      tester,
      resend: () async => ++resendCalls > 1,
      signOut: () async => false,
    );
    await tester.tap(find.text('Resend SMS'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to resend the SMS. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Resend SMS'));
    await tester.pumpAndSettle();
    expect(find.text('A new code has been requested.'), findsOneWidget);
    await tester.tap(find.text('Use another account'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to sign out. Please try again.'), findsOneWidget);
  });

  testWidgets('disables all actions during an in-flight request', (
    tester,
  ) async {
    final pending = Completer<bool>();
    var signOutCalls = 0;
    await showScreen(
      tester,
      resend: () => pending.future,
      signOut: () async {
        signOutCalls++;
        return true;
      },
    );
    await tester.tap(find.text('Resend SMS'));
    await tester.pump();
    expect(find.text('PLEASE WAIT…'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Use another account'),
          )
          .onPressed,
      isNull,
    );
    expect(signOutCalls, 0);
    pending.complete(true);
    await tester.pumpAndSettle();
  });
}
