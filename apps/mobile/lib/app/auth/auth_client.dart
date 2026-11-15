import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/external/http/api_client.dart';
import '../../shared/external/utils/result.dart';
import '../../core/eligibility/eligibility.dart';
import '../../core/registration/registration_models.dart';
import 'auth_repository.dart';

/// Session state and authentication actions used by the app router.
class AuthClient extends ChangeNotifier {
  /// Creates an authentication client with optionally injected dependencies.
  AuthClient({
    Dio? dio,
    FlutterSecureStorage? storage,
    AuthRepository? repository,
  }) : this._(
         dio ?? createApiClient(),
         storage ?? const FlutterSecureStorage(),
         repository,
       );

  AuthClient._(
    Dio dio,
    FlutterSecureStorage storage,
    AuthRepository? repository,
  ) : _repository = repository ?? AuthRepository(dio: dio, storage: storage);

  final AuthRepository _repository;
  String? _token;
  String? phone;
  bool verified = false;
  bool initialized = false;

  /// Whether sending the most recent known verification SMS succeeded, if known.
  bool? smsSent;
  bool connectionFailed = false;
  EligibilityDecision? eligibility;

  bool get hasSession => _token != null;

  /// Current token for authenticated service requests, if a session exists.
  String? get sessionToken => _token;

  /// Restores a saved session, retaining the token on transient connection failure.
  Future<void> restore() async {
    connectionFailed = false;
    verified = false;
    eligibility = null;
    smsSent = null;
    final stored = await _repository.readToken();
    await stored.when(
      val: (token) async {
        _token = token;
        if (token == null) return;
        final result = await _fetchSession(token);
        await result.when(
          val: (_) async {},
          err: (error) async {
            if (error == AuthFailure.unauthorized) {
              final cleared = await _clear();
              cleared.when(val: (_) {}, err: (_) => connectionFailed = true);
            } else {
              connectionFailed = true;
            }
          },
        );
      },
      err: (_) async => connectionFailed = true,
    );
    initialized = true;
    notifyListeners();
  }

  /// Registers a user and returns an explicit result.
  Future<AuthResult> register(RegistrationSubmission input) async {
    final result = await _repository.register(input);
    return result.when(
      val: (data) {
        if (!_isAuthenticationResponse(data) || data['sent'] is! bool) {
          return const Result.err(AuthFailure.invalidResponse);
        }
        _accept(data);
        smsSent = data['sent'] == true;
        notifyListeners();
        return const Result.val(Ok());
      },
      err: Result.err,
    );
  }

  /// Signs in and loads the session when the phone is already verified.
  Future<AuthResult> login(String identifier, String password) async {
    final result = await _repository.login(identifier, password);
    return result.when(
      val: (data) async {
        if (!_isAuthenticationResponse(data)) {
          return const Result.err(AuthFailure.invalidResponse);
        }
        _accept(data);
        smsSent = null;
        final token = _token;
        if (verified && token != null) {
          final session = await _fetchSession(token);
          session.when(
            val: (_) {},
            err: (_) {
              verified = false;
              connectionFailed = true;
            },
          );
          notifyListeners();
          return session;
        }
        notifyListeners();
        return const Result.val(Ok());
      },
      err: (error) async => Result.err(error),
    );
  }

  /// Requests another verification code.
  Future<AuthResult> resend() async {
    final token = _token;
    if (token == null) return const Result.err(AuthFailure.unauthorized);
    final result = await _repository.resend(token);
    result.when(
      val: (_) {
        smsSent = true;
        notifyListeners();
      },
      err: (_) {},
    );
    return result;
  }

  /// Verifies the phone and reloads the server session.
  Future<AuthResult> verify(String code) async {
    final token = _token;
    if (token == null) return const Result.err(AuthFailure.unauthorized);
    final result = await _repository.verify(token, code);
    return result.when(
      val: (_) async {
        final session = await _fetchSession(token);
        session.when(
          val: (_) {},
          err: (_) {
            verified = false;
            connectionFailed = true;
          },
        );
        notifyListeners();
        return session;
      },
      err: (error) async => Result.err(error),
    );
  }

  /// Invalidates and clears the active session.
  Future<AuthResult> logout() async {
    final token = _token;
    if (token != null) {
      final result = await _repository.logout(token);
      if (result case Failure<Ok, AuthFailure>(error: final error)) {
        if (error != AuthFailure.unauthorized) return result;
      }
    }
    final result = await _clear();
    notifyListeners();
    return result;
  }

  void _accept(Map<String, dynamic> data) {
    _token = data['token'] as String;
    verified = data['verified'] == true;
    phone = data['phone'] as String?;
  }

  bool _isAuthenticationResponse(Map<String, dynamic> data) =>
      data['token'] is String &&
      (data['token'] as String).isNotEmpty &&
      data['verified'] is bool &&
      (data['phone'] == null || data['phone'] is String);

  Future<AuthResult> _fetchSession(String token) async {
    final result = await _repository.session(token);
    return result.when(
      val: (data) {
        final user = data['user'];
        if (user is! Map<String, dynamic> ||
            user['dateOfBirth'] is! String ||
            data['verified'] is! bool ||
            (data['phone'] != null && data['phone'] is! String)) {
          return const Result.err(AuthFailure.invalidResponse);
        }
        try {
          final decision = evaluateEligibility(user['dateOfBirth'] as String);
          verified = data['verified'] == true;
          phone = data['phone'] as String?;
          eligibility = decision;
          return const Result.val(Ok());
        } on EligibilityValidationException {
          return const Result.err(AuthFailure.invalidResponse);
        }
      },
      err: Result.err,
    );
  }

  Future<AuthResult> _clear() async {
    final result = await _repository.clearToken();
    result.when(
      val: (_) {
        _token = null;
        verified = false;
        phone = null;
        eligibility = null;
        smsSent = null;
      },
      err: (_) {},
    );
    return result;
  }
}
