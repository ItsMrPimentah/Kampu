import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showtime_mobile/app/auth/auth_client.dart';
import 'package:showtime_mobile/app/auth/auth_repository.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/core/registration/registration_models.dart';
import 'package:showtime_mobile/shared/external/utils/result.dart';

import 'mocks/auth_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late AuthClient client;

  setUp(() {
    repository = MockAuthRepository();
    client = AuthClient(repository: repository);
  });
  tearDown(() {
    client.dispose();
    reset(repository);
  });

  test('restores a verified session from secure storage', () async {
    when(() => repository.readToken())
        .thenAnswer((_) async => const Result.val('token'));
    when(() => repository.session('token')).thenAnswer(
      (_) async => const Result.val({
        'verified': true,
        'phone': 'test',
        'user': {'dateOfBirth': '2000-01-01'},
      }),
    );

    await client.restore();

    expect(client.initialized, isTrue);
    expect(client.hasSession, isTrue);
    expect(client.verified, isTrue);
    expect(client.connectionFailed, isFalse);
  });

  test('unverified login and restoration leave SMS delivery unknown', () async {
    when(() => repository.login('name', 'password')).thenAnswer(
      (_) async => const Result.val({'token': 'token', 'verified': false}),
    );
    when(() => repository.readToken())
        .thenAnswer((_) async => const Result.val('token'));
    when(() => repository.session('token')).thenAnswer(
      (_) async => const Result.val({
        'verified': false,
        'phone': 'test',
        'user': {'dateOfBirth': '2000-01-01'},
      }),
    );
    client.smsSent = false;
    await client.login('name', 'password');
    expect(client.smsSent, isNull);
    client.smsSent = true;
    await client.restore();
    expect(client.smsSent, isNull);
    expect(client.verified, isFalse);
  });

  test('registration and resend track known SMS results', () async {
    final input = RegistrationSubmission(
      role: RegistrationRole.player,
      fullName: 'Player',
      dateOfBirth: '2000-01-01',
      phone: '+351912345678',
      email: 'player@example.com',
      password: 'password',
      eligibility: evaluateEligibility('2000-01-01'),
    );
    var sent = false;
    when(() => repository.register(input)).thenAnswer(
      (_) async =>
          Result.val({'token': 'token', 'verified': false, 'sent': sent}),
    );
    when(() => repository.resend('token'))
        .thenAnswer((_) async => const Result.err(AuthFailure.unavailable));
    await client.register(input);
    expect(client.smsSent, isFalse);
    await client.resend();
    expect(client.smsSent, isFalse);
    when(() => repository.resend('token'))
        .thenAnswer((_) async => const Result.val(Ok()));
    await client.resend();
    expect(client.smsSent, isTrue);
    sent = true;
    await client.register(input);
    expect(client.smsSent, isTrue);
  });

  test('preserves the token when restoration fails transiently', () async {
    when(() => repository.readToken())
        .thenAnswer((_) async => const Result.val('token'));
    when(() => repository.session('token'))
        .thenAnswer((_) async => const Result.err(AuthFailure.unavailable));

    await client.restore();

    expect(client.hasSession, isTrue);
    expect(client.verified, isFalse);
    expect(client.connectionFailed, isTrue);
    verifyNever(() => repository.clearToken());
  });

  test('clears an unauthorized restored session', () async {
    when(() => repository.readToken())
        .thenAnswer((_) async => const Result.val('token'));
    when(() => repository.session('token'))
        .thenAnswer((_) async => const Result.err(AuthFailure.unauthorized));
    when(() => repository.clearToken())
        .thenAnswer((_) async => const Result.val(Ok()));

    await client.restore();

    expect(client.hasSession, isFalse);
    expect(client.connectionFailed, isFalse);
    verify(() => repository.clearToken()).called(1);
  });

  test(
    'returns an expected login failure without creating a session',
    () async {
      when(() => repository.login('name', 'password'))
          .thenAnswer((_) async => const Result.err(AuthFailure.unauthorized));

      final result = await client.login('name', 'password');

      expect(
        result.when(val: (_) => null, err: (error) => error),
        AuthFailure.unauthorized,
      );
      expect(client.hasSession, isFalse);
    },
  );

  test('reports failed sign-out and retains the session', () async {
    when(() => repository.login('name', 'password')).thenAnswer(
      (_) async => const Result.val({'token': 'token', 'verified': false}),
    );
    when(() => repository.logout('token'))
        .thenAnswer((_) async => const Result.err(AuthFailure.unavailable));
    await client.login('name', 'password');

    final result = await client.logout();

    expect(
      result.when(val: (_) => null, err: (error) => error),
      AuthFailure.unavailable,
    );
    expect(client.hasSession, isTrue);
    verifyNever(() => repository.clearToken());
  });

  test(
    'clears local session when the server session is already invalid',
    () async {
      when(() => repository.login('name', 'password')).thenAnswer(
        (_) async => const Result.val({'token': 'token', 'verified': false}),
      );
      when(() => repository.logout('token'))
          .thenAnswer((_) async => const Result.err(AuthFailure.unauthorized));
      when(() => repository.clearToken())
          .thenAnswer((_) async => const Result.val(Ok()));
      await client.login('name', 'password');

      final result = await client.logout();

      expect(result.when(val: (_) => true, err: (_) => false), isTrue);
      expect(client.hasSession, isFalse);
    },
  );
}
