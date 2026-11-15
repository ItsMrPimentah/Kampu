import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showtime_mobile/app/auth/auth_repository.dart';
import 'package:showtime_mobile/app/auth/session_controller.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/core/registration/registration_models.dart';
import 'package:showtime_mobile/shared/external/utils/result.dart';

import 'mocks/auth_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late SessionController controller;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.saveToken(any()))
        .thenAnswer((_) async => const Result.val(Ok()));
    controller = SessionController(repository);
  });
  tearDown(() {
    if (controller.mounted) controller.dispose();
    reset(repository);
  });

  test('restores persisted session and exposes immutable user data', () async {
    when(() => repository.readToken())
        .thenAnswer((_) async => const Result.val('token'));
    when(() => repository.session('token')).thenAnswer(
      (_) async => const Result.val({
        'verified': true,
        'phone': 'test',
        'user': {'id': '1', 'name': 'Player', 'dateOfBirth': '2000-01-01'},
      }),
    );

    await controller.restore();

    expect(controller.snapshot.initialized, isTrue);
    expect(controller.snapshot.hasSession, isTrue);
    expect(controller.snapshot.verified, isTrue);
    expect(controller.snapshot.connectionFailed, isFalse);
    expect(controller.snapshot.user?.name, 'Player');
    expect(controller.snapshot.user?.id, '1');
    expect(controller.snapshot.eligibility, isNotNull);
    expect(controller.sessionToken, 'token');
  });

  test('preserves the token when restoration fails transiently', () async {
    when(() => repository.readToken())
        .thenAnswer((_) async => const Result.val('token'));
    when(() => repository.session('token'))
        .thenAnswer((_) async => const Result.err(AuthFailure.unavailable));

    await controller.restore();

    expect(controller.snapshot.hasSession, isTrue);
    expect(controller.snapshot.verified, isFalse);
    expect(controller.snapshot.connectionFailed, isTrue);
    verifyNever(() => repository.clearToken());
  });

  test('clears an unauthorized restored session', () async {
    when(() => repository.readToken())
        .thenAnswer((_) async => const Result.val('token'));
    when(() => repository.session('token'))
        .thenAnswer((_) async => const Result.err(AuthFailure.unauthorized));
    when(() => repository.clearToken())
        .thenAnswer((_) async => const Result.val(Ok()));

    await controller.restore();

    expect(controller.snapshot.hasSession, isFalse);
    expect(controller.snapshot.connectionFailed, isFalse);
    verify(() => repository.clearToken()).called(1);
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
    await controller.login('name', 'password');
    expect(controller.snapshot.smsSent, isNull);
    await controller.restore();
    expect(controller.snapshot.smsSent, isNull);
    expect(controller.snapshot.verified, isFalse);
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
    when(() => repository.register(input)).thenAnswer(
      (_) async => const Result.val({
        'token': 'token',
        'verified': false,
        'sent': false,
      }),
    );
    when(() => repository.resend('token'))
        .thenAnswer((_) async => const Result.err(AuthFailure.unavailable));
    await controller.register(input);
    expect(controller.snapshot.smsSent, isFalse);
    await controller.resend();
    expect(controller.snapshot.smsSent, isFalse);
    when(() => repository.resend('token'))
        .thenAnswer((_) async => const Result.val(Ok()));
    await controller.resend();
    expect(controller.snapshot.smsSent, isTrue);
  });

  test(
    'returns an expected login failure without creating a session',
    () async {
      when(() => repository.login('name', 'password'))
          .thenAnswer((_) async => const Result.err(AuthFailure.unauthorized));
      final result = await controller.login('name', 'password');
      expect(
        result.when(val: (_) => null, err: (error) => error),
        AuthFailure.unauthorized,
      );
      expect(controller.snapshot.hasSession, isFalse);
    },
  );

  test('rejects malformed authentication before writing a token', () async {
    when(() => repository.login('name', 'password')).thenAnswer(
      (_) async => const Result.val({'token': 'token', 'verified': 'yes'}),
    );
    final result = await controller.login('name', 'password');
    expect(
      result.when(val: (_) => null, err: (error) => error),
      AuthFailure.invalidResponse,
    );
    expect(controller.snapshot.hasSession, isFalse);
    verifyNever(() => repository.saveToken(any()));
  });

  test('does not start a session if secure persistence fails', () async {
    when(() => repository.login('name', 'password')).thenAnswer(
      (_) async => const Result.val({'token': 'token', 'verified': false}),
    );
    when(() => repository.saveToken('token'))
        .thenAnswer((_) async => const Result.err(AuthFailure.unavailable));
    final result = await controller.login('name', 'password');
    expect(
      result.when(val: (_) => null, err: (error) => error),
      AuthFailure.unavailable,
    );
    expect(controller.snapshot.hasSession, isFalse);
  });

  test(
    'verified login waits for user data before publishing a verified session',
    () async {
      final response = Completer<Result<Map<String, dynamic>, AuthFailure>>();
      when(() => repository.login('name', 'password')).thenAnswer(
        (_) async => const Result.val({'token': 'token', 'verified': true}),
      );
      final loadingSession = Completer<void>();
      when(() => repository.session('token')).thenAnswer((_) {
        loadingSession.complete();
        return response.future;
      });
      final login = controller.login('name', 'password');
      await loadingSession.future;
      expect(controller.snapshot.verified, isFalse);
      expect(controller.snapshot.hasSession, isFalse);
      response.complete(
        const Result.val({
          'verified': true,
          'user': {'id': '1', 'name': 'Player', 'dateOfBirth': '2000-01-01'},
        }),
      );
      await login;
      expect(controller.snapshot.verified, isTrue);
      expect(controller.snapshot.user?.name, 'Player');
    },
  );

  test('clears a token if login is disposed during persistence', () async {
    final write = Completer<AuthResult>();
    final writeStarted = Completer<void>();
    when(() => repository.login('name', 'password')).thenAnswer(
      (_) async => const Result.val({'token': 'token', 'verified': false}),
    );
    when(() => repository.saveToken('token')).thenAnswer((_) {
      writeStarted.complete();
      return write.future;
    });
    when(() => repository.clearToken())
        .thenAnswer((_) async => const Result.val(Ok()));
    final login = controller.login('name', 'password');
    await writeStarted.future;
    controller.dispose();
    write.complete(const Result.val(Ok()));
    await login;
    verify(() => repository.clearToken()).called(1);
  });

  test('reports failed sign-out and retains the session', () async {
    when(() => repository.login('name', 'password')).thenAnswer(
      (_) async => const Result.val({'token': 'token', 'verified': false}),
    );
    when(() => repository.logout('token'))
        .thenAnswer((_) async => const Result.err(AuthFailure.unavailable));
    await controller.login('name', 'password');
    final result = await controller.logout();
    expect(
      result.when(val: (_) => null, err: (error) => error),
      AuthFailure.unavailable,
    );
    expect(controller.snapshot.hasSession, isTrue);
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
      await controller.login('name', 'password');
      final result = await controller.logout();
      expect(result.when(val: (_) => true, err: (_) => false), isTrue);
      expect(controller.snapshot.hasSession, isFalse);
      expect(controller.snapshot.user, isNull);
      expect(controller.sessionToken, isNull);
    },
  );

  test(
    'sign-out removes persisted token and previously loaded user data',
    () async {
      when(() => repository.readToken())
          .thenAnswer((_) async => const Result.val('token'));
      when(() => repository.session('token')).thenAnswer(
        (_) async => const Result.val({
          'verified': true,
          'phone': 'test',
          'user': {'id': '1', 'name': 'Player', 'dateOfBirth': '2000-01-01'},
        }),
      );
      when(() => repository.logout('token'))
          .thenAnswer((_) async => const Result.val(Ok()));
      when(() => repository.clearToken())
          .thenAnswer((_) async => const Result.val(Ok()));
      await controller.restore();
      expect(controller.snapshot.user, isNotNull);
      final result = await controller.logout();
      expect(result.when(val: (_) => true, err: (_) => false), isTrue);
      expect(controller.snapshot.user, isNull);
      expect(controller.snapshot.phone, isNull);
      expect(controller.snapshot.eligibility, isNull);
      expect(controller.sessionToken, isNull);
      verify(() => repository.clearToken()).called(1);
    },
  );

  test(
    'does not update state after disposal during session restoration',
    () async {
      final response = Completer<Result<String?, AuthFailure>>();
      when(() => repository.readToken()).thenAnswer((_) => response.future);
      final restoration = controller.restore();
      controller.dispose();
      response.complete(const Result.val('token'));
      await restoration;
      verifyNever(() => repository.session(any()));
    },
  );
}
