import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/app/auth/session_controller.dart';
import 'package:showtime_mobile/app/navigation/app_router.dart';
import 'package:showtime_mobile/app/theme.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/screens/auth/login_screen.dart';
import 'package:showtime_mobile/screens/registration/registration_screen.dart';

import 'mocks/auth_fake.dart';

void main() {
  testWidgets('phone icon stays neutral when empty and invalid', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: RegisterScreen(onContinue: (_) {})),
      ),
    );
    final phone = find.byKey(const ValueKey('registration-phone'));
    IconData? phoneIcon() =>
        tester.widget<TextField>(phone).decoration?.suffixIcon is Icon
        ? (tester.widget<TextField>(phone).decoration!.suffixIcon! as Icon).icon
        : null;

    expect(phoneIcon(), Icons.phone_android);
    await tester.ensureVisible(phone);
    await tester.enterText(phone, '12');
    await tester.ensureVisible(
      find.byKey(const ValueKey('registration-continue')),
    );
    await tester.tap(find.byKey(const ValueKey('registration-continue')));
    await tester.pump();
    expect(phoneIcon(), Icons.phone_android);
    expect(find.text('Enter a valid mobile number.'), findsOneWidget);
  });

  testWidgets('registration navigation exposes buttons and 48dp targets', (
    tester,
  ) async {
    var loginTapped = false;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RegisterScreen(
            onContinue: (_) {},
            onLogin: () => loginTapped = true,
          ),
        ),
      ),
    );
    expect(find.text('ShowTime'), findsOneWidget);
    expect(find.text('Pitch Pulse'), findsNothing);
    for (final name in ['registration-back', 'registration-help']) {
      final size = tester.getSize(find.byKey(ValueKey(name)));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    final handoff = find.byKey(const ValueKey('registration-login'));
    await tester.ensureVisible(handoff);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(handoff),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
        label: 'Log In',
      ),
    );
    await tester.tap(handoff);
    expect(loginTapped, isTrue);
    semantics.dispose();
  });

  testWidgets('direct registration back falls back to login', (tester) async {
    final eligibility = ValueNotifier<EligibilityDecision?>(null);
    final auth = SessionController(FakeAuthRepository());
    await auth.restore();
    final router = createShowtimeRouter(
      eligibility: eligibility,
      session: auth,
    );
    addTearDown(() {
      router.dispose();
      auth.dispose();
      eligibility.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    router.go('/register');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('registration-back')));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME BACK, BALLER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct registration without auth returns to onboarding', (
    tester,
  ) async {
    final eligibility = ValueNotifier<EligibilityDecision?>(null);
    final router = createShowtimeRouter(eligibility: eligibility);
    addTearDown(() {
      router.dispose();
      eligibility.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    router.go('/register');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('registration-back')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/onboarding');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'login retains validation, switching, loading and failure feedback',
    (tester) async {
      final result = Completer<bool>();
      final calls = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: createAppTheme(),
            home: LoginScreen(
              onLogin: (identifier, password) {
                calls.add('$identifier:$password');
                return result.future;
              },
              onRegister: () {},
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('SIGN IN & PLAY'));
      await tester.tap(find.text('SIGN IN & PLAY'));
      await tester.pump();
      expect(
        find.text('Enter your phone or email and password.'),
        findsOneWidget,
      );
      expect(calls, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('login-identifier')),
        '123',
      );
      await tester.tap(find.text('Email Address'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('login-identifier')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-identifier')),
        ' player@example.com ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password')),
        'secret',
      );
      await tester.ensureVisible(find.text('SIGN IN & PLAY'));
      await tester.tap(find.text('SIGN IN & PLAY'));
      await tester.pump();
      expect(calls, ['player@example.com:secret']);
      expect(find.text('SIGNING IN…'), findsOneWidget);
      result.complete(false);
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to sign in. Check your details and connection.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('successful login forwards credentials to the supplied action', (
    tester,
  ) async {
    var succeeded = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: createAppTheme(),
          home: LoginScreen(
            onLogin: (identifier, password) async {
              succeeded = identifier == '+351912345678' && password == 'secret';
              return true;
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
    await tester.pumpAndSettle();
    expect(succeeded, isTrue);
    expect(find.text('SIGN IN & PLAY'), findsOneWidget);
  });

  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('auth layouts remain reachable at $width dp', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: createAppTheme(),
            home: LoginScreen(onLogin: (_, _) async => true, onRegister: () {}),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Create your player pass'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(onContinue: (_) {}, onLogin: () {}),
          ),
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('registration-login')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('auth actions remain reachable with larger text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget scaled(Widget child) => MediaQuery(
      data: const MediaQueryData(
        size: Size(360, 800),
        textScaler: TextScaler.linear(1.3),
      ),
      child: child,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: createAppTheme(),
          builder: (_, child) => scaled(child!),
          home: LoginScreen(onLogin: (_, _) async => true, onRegister: () {}),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Create your player pass'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (_, child) => scaled(child!),
          home: RegisterScreen(onContinue: (_) {}, onLogin: () {}),
        ),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('registration-login')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
