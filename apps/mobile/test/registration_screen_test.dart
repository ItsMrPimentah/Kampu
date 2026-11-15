import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/app/auth/auth_client.dart';
import 'package:showtime_mobile/main.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/core/registration/registration_models.dart';
import 'package:showtime_mobile/screens/registration/registration_screen.dart';

class TestAuth extends AuthClient {
  @override
  Future<void> restore() async {
    initialized = true;
    notifyListeners();
  }
}

void main() {
  Future<void> pumpRegisterScreen(
    WidgetTester tester, {
    FutureOr<void> Function(RegistrationSubmission submission)? onContinue,
    VoidCallback? onLogin,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RegisterScreen(
            onContinue: onContinue ?? (_) async {},
            onLogin: onLogin,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders the Stitch registration shell without narrow-width overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpRegisterScreen(tester);

      expect(find.text('CREATE YOUR PLAYER PASS'), findsOneWidget);
      expect(find.text('STEP 1 OF 2'), findsOneWidget);
      expect(find.text('SELECT SQUAD ROLE'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('registration-continue')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'supports the wider mobile layout and accessible CTA reachability',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpRegisterScreen(tester);

      expect(
        find.bySemanticsLabel(RegExp(r'Player.*Selected')),
        findsOneWidget,
      );
      final continueButton = find.byKey(
        const ValueKey('registration-continue'),
      );
      await tester.ensureVisible(continueButton);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selects Player by default and switches one accessible role at a time',
    (tester) async {
      await pumpRegisterScreen(tester);

      expect(
        find.byKey(const ValueKey('role-indicator-player-selected')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('role-indicator-squadCaptain-unselected')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('role-squadCaptain')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('role-indicator-player-unselected')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('role-indicator-squadCaptain-selected')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Squad Captain.*Selected')),
        findsOneWidget,
      );
    },
  );

  testWidgets('exposes themed fields, terms, password controls, and CTA', (
    tester,
  ) async {
    await pumpRegisterScreen(tester);

    expect(
      find.byKey(const ValueKey('registration-full-name')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('registration-date-of-birth')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('registration-phone')), findsOneWidget);
    expect(find.byKey(const ValueKey('registration-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('registration-password')), findsOneWidget);
    expect(find.byKey(const ValueKey('registration-terms')), findsOneWidget);
    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(find.byKey(const ValueKey('password-strength-0')), findsOneWidget);
  });

  testWidgets('blocks incomplete submissions and reports field errors', (
    tester,
  ) async {
    var submitted = false;
    await pumpRegisterScreen(tester, onContinue: (_) async => submitted = true);

    final continueButton = find.byKey(const ValueKey('registration-continue'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(submitted, isFalse);
    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('Use date format DD / MM / YYYY.'), findsOneWidget);
    expect(
      find.text('Accept the Code of Conduct and Privacy Policy.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'valid youth registration shows protection status and submits once',
    (tester) async {
      var submissions = 0;
      RegistrationSubmission? payload;
      await pumpRegisterScreen(
        tester,
        onContinue: (submission) async {
          submissions++;
          payload = submission;
        },
      );

      Future<void> enter(Key key, String value) async {
        final field = find.byKey(key);
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
      }

      await enter(const ValueKey('registration-full-name'), 'Leo Messi');
      await enter(
        const ValueKey('registration-date-of-birth'),
        '03 / 11 / 2009',
      );
      await enter(const ValueKey('registration-phone'), '151 8920 4410');
      await enter(const ValueKey('registration-email'), 'leo@example.com');
      await enter(
        const ValueKey('registration-password'),
        'TacticalStriker2024!',
      );
      tester.testTextInput.hide();
      await tester.pump();
      final terms = find.byKey(const ValueKey('registration-terms'));
      await tester.ensureVisible(terms);
      final checkbox = find.byType(Checkbox).last;
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('youth-protection-status')),
        findsOneWidget,
      );
      final continueButton = find.byKey(
        const ValueKey('registration-continue'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(submissions, 1);
      expect(payload?.role, RegistrationRole.player);
      expect(payload?.eligibility.category, EligibilityCategory.youth);
    },
  );

  testWidgets(
    'rejects underage users and keeps youth protection policy explicit',
    (tester) async {
      var submissions = 0;
      await pumpRegisterScreen(tester, onContinue: (_) async => submissions++);

      final dob = find.byKey(const ValueKey('registration-date-of-birth'));
      await tester.ensureVisible(dob);
      await tester.enterText(dob, '01 / 01 / 2020');
      expect(
        find.byKey(const ValueKey('youth-protection-status')),
        findsNothing,
      );

      final continueButton = find.byKey(
        const ValueKey('registration-continue'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(find.textContaining('minimum age'), findsOneWidget);
      expect(submissions, 0);
    },
  );

  testWidgets('does not show youth-only status for adult users', (
    tester,
  ) async {
    await pumpRegisterScreen(tester);

    final dob = find.byKey(const ValueKey('registration-date-of-birth'));
    await tester.ensureVisible(dob);
    await tester.enterText(dob, '01 / 01 / 2000');
    expect(find.byKey(const ValueKey('youth-protection-status')), findsNothing);
  });

  testWidgets('login opens registration and back returns to login', (
    tester,
  ) async {
    await tester.pumpWidget(ShowtimeApp(auth: TestAuth()));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME BACK, BALLER'), findsOneWidget);

    await tester.ensureVisible(find.text('Create your player pass'));
    await tester.tap(find.text('Create your player pass'));
    await tester.pumpAndSettle();
    expect(find.text('CREATE YOUR PLAYER PASS'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('registration-back')));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME BACK, BALLER'), findsOneWidget);
  });

  testWidgets('login handoff calls the supplied callback', (tester) async {
    var tapped = false;
    await pumpRegisterScreen(tester, onLogin: () => tapped = true);

    final login = find.byKey(const ValueKey('registration-login'));
    await tester.ensureVisible(login);
    await tester.tap(login);
    expect(tapped, isTrue);
  });
}
