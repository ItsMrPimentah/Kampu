import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/auth/auth_client.dart';
import 'package:showtime_mobile/core/auth/auth_repository.dart';
import 'package:showtime_mobile/main.dart';
import 'package:showtime_mobile/onboarding/eligibility.dart';
import 'package:showtime_mobile/shared/external/utils/result.dart';

class FakeAuth extends AuthClient {
  bool session = false;
  @override
  bool get hasSession => session;

  @override
  Future<void> restore() async {
    initialized = true;
    notifyListeners();
  }

  @override
  Future<AuthResult> login(String identifier, String password) async {
    session = true;
    phone = '+351912345678';
    verified = false;
    notifyListeners();
    return const Result.val(Ok());
  }

  @override
  Future<AuthResult> verify(String code) async {
    if (code != '123456') return const Result.err(AuthFailure.unauthorized);
    eligibility = evaluateEligibility('2000-01-01');
    verified = true;
    notifyListeners();
    return const Result.val(Ok());
  }

  @override
  Future<AuthResult> logout() async {
    session = false;
    verified = false;
    notifyListeners();
    return const Result.val(Ok());
  }
}

void main() {
  testWidgets(
    'unverified sign-in stays at OTP until a valid code and sign-out returns to login',
    (tester) async {
      final auth = FakeAuth();
      await tester.pumpWidget(ShowtimeApp(auth: auth));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('login-identifier')),
        '+351912345678',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password')),
        'Password1!',
      );
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
}
