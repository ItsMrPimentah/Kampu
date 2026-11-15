import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/app/theme.dart';
import 'package:showtime_mobile/screens/auth/login_screen.dart';

void main() {
  testWidgets(
    'selector, fields, password visibility and registration are accessible',
    (tester) async {
      var registered = false;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: createAppTheme(),
            home: LoginScreen(
              onLogin: (_, _) async => true,
              onRegister: () => registered = true,
            ),
          ),
        ),
      );

      final phone = find.text('Phone Number');
      final email = find.text('Email Address');
      final guidance = find.text('Include country code, e.g. +351.');
      final heading = tester.getSemantics(find.text('WELCOME BACK, BALLER'));
      expect(
        heading,
        matchesSemantics(isHeader: true, label: 'WELCOME BACK, BALLER'),
      );
      expect(
        tester.getSemantics(phone),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          label: 'Phone Number',
        ),
      );
      final identifier = find.byKey(const ValueKey('login-identifier'));
      final password = find.byKey(const ValueKey('login-password'));
      expect(
        tester.widget<TextField>(identifier).keyboardType,
        TextInputType.phone,
      );
      expect(tester.widget<TextField>(identifier).autofillHints, [
        AutofillHints.telephoneNumber,
      ]);
      expect(tester.getSemantics(identifier).label, contains('Mobile number'));
      expect(
        tester.getSemantics(identifier).hint,
        contains('Include country code'),
      );
      expect(guidance, findsOneWidget);
      expect(tester.getSemantics(password).label, contains('Password'));
      await tester.enterText(identifier, '123');
      await tester.pump();
      expect(guidance, findsOneWidget);
      expect(
        tester.getSemantics(identifier).hint,
        contains('Include country code'),
      );
      await tester.tap(email);
      await tester.pump();
      expect(guidance, findsNothing);
      expect(
        tester.getSemantics(identifier).hint,
        isNot(contains('Include country code')),
      );
      expect(tester.widget<TextField>(identifier).controller!.text, isEmpty);
      expect(
        tester.widget<TextField>(identifier).keyboardType,
        TextInputType.emailAddress,
      );
      expect(tester.widget<TextField>(identifier).autofillHints, [
        AutofillHints.email,
      ]);
      expect(
        tester.getSemantics(email),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          label: 'Email Address',
        ),
      );
      expect(
        tester.getSemantics(phone),
        matchesSemantics(
          isButton: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          label: 'Phone Number',
        ),
      );
      expect(tester.getSemantics(identifier).label, contains('Email address'));
      await tester.tap(phone);
      await tester.pump();
      expect(guidance, findsOneWidget);
      expect(
        tester.getSemantics(identifier).hint,
        contains('Include country code'),
      );
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      expect(tester.widget<TextField>(password).autofillHints, [
        AutofillHints.password,
      ]);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(tester.widget<TextField>(password).obscureText, isFalse);
      expect(find.byTooltip('Hide password'), findsOneWidget);
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      final registration = find.text('Create your player pass');
      await tester.ensureVisible(registration);
      await tester.tap(registration);
      expect(registered, isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'loading disables repeated submission and failure can be retried',
    (tester) async {
      final pending = Completer<bool>();
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: createAppTheme(),
            home: LoginScreen(
              onLogin: (_, _) {
                calls++;
                return calls == 1 ? pending.future : Future.value(true);
              },
              onRegister: () {},
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-identifier')),
        '+351912345678',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password')),
        'secret',
      );
      await tester.ensureVisible(find.text('SIGN IN & PLAY'));
      await tester.tap(find.text('SIGN IN & PLAY'));
      await tester.pump();
      expect(calls, 1);
      final loadingButton = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('SIGNING IN…'),
          matching: find.byType(TextButton),
        ),
      );
      expect(loadingButton.onPressed, isNull);
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to sign in. Check your details and connection.'),
        findsOneWidget,
      );
      expect(find.text('SIGN IN & PLAY'), findsOneWidget);
      await tester.ensureVisible(find.text('SIGN IN & PLAY'));
      await tester.tap(find.text('SIGN IN & PLAY'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(
        find.text('Unable to sign in. Check your details and connection.'),
        findsNothing,
      );
    },
  );

  for (final width in [360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('login fits $width dp at ${scale}x text', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: createAppTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: LoginScreen(
                onLogin: (_, _) async => true,
                onRegister: () {},
              ),
            ),
          ),
        );
        await tester.ensureVisible(find.text('Create your player pass'));
        await tester.pumpAndSettle();
        final error = tester.takeException();
        expect(
          error,
          isNull,
          reason: error is FlutterError ? error.toStringDeep() : '$error',
        );
        await tester.ensureVisible(find.text('Email Address'));
        await tester.tap(find.text('Email Address'));
        await tester.pumpAndSettle();
        expect(find.text('Include country code, e.g. +351.'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Phone Number'));
        await tester.pumpAndSettle();
        expect(find.text('Include country code, e.g. +351.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
