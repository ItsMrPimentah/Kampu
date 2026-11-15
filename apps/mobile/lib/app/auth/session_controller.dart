import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/eligibility/eligibility.dart';
import '../../core/registration/registration_models.dart';
import '../../shared/external/utils/result.dart';
import 'auth_repository.dart';

part 'session_controller.freezed.dart';

/// The user details returned by the authenticated session endpoint.
@freezed
abstract class SessionUser with _$SessionUser {
  /// Creates a user snapshot without exposing authentication credentials.
  const factory SessionUser({
    String? id,
    String? name,
    required String dateOfBirth,
  }) = _SessionUser;
}

/// Immutable application-wide session state; the token is kept private.
@freezed
abstract class SessionState with _$SessionState {
  /// Creates a session snapshot.
  const factory SessionState({
    @Default(false) bool initialized,
    @Default(false) bool hasSession,
    @Default(false) bool verified,
    @Default(false) bool connectionFailed,
    bool? smsSent,
    String? phone,
    EligibilityDecision? eligibility,
    SessionUser? user,
  }) = _SessionState;
}

/// Coordinates authentication and secure session persistence.
class SessionController extends StateNotifier<SessionState> {
  /// Creates a session controller using the injected authentication boundary.
  SessionController(this._repository) : super(const SessionState());

  final AuthRepository _repository;
  String? _token;
  int _operation = 0;
  Future<void> _storageQueue = Future<void>.value();

  /// The current session snapshot for routing.
  SessionState get snapshot => state;

  /// Supplies the current token to authenticated services.
  String? get sessionToken => _token;

  bool _active(int operation) => mounted && operation == _operation;

  /// Restores the stored session, retaining its token on transient failures.
  Future<void> restore() async {
    if (!mounted) return;
    final operation = ++_operation;
    state = state.copyWith(
      initialized: false,
      connectionFailed: false,
      verified: false,
      eligibility: null,
      user: null,
      smsSent: null,
    );
    final stored = await _runStorage(() => _repository.readToken());
    if (!_active(operation)) return;
    final token = stored.when(val: (value) => value, err: (_) => null);
    if (stored case Failure<String?, AuthFailure>()) {
      state = state.copyWith(initialized: true, connectionFailed: true);
      return;
    }
    _token = token;
    state = state.copyWith(hasSession: token != null, phone: null);
    if (token != null) {
      final result = await _fetchSession(token, operation);
      if (!_active(operation)) return;
      if (result case Failure<Ok, AuthFailure>(error: final error)) {
        if (error == AuthFailure.unauthorized) {
          final cleared = await _clear(operation);
          if (!_active(operation)) return;
          if (cleared is Failure<Ok, AuthFailure>) {
            state = state.copyWith(connectionFailed: true);
          }
        } else {
          state = state.copyWith(connectionFailed: true);
        }
      }
    }
    if (_active(operation)) state = state.copyWith(initialized: true);
  }

  /// Registers a user and retains the resulting session.
  Future<AuthResult> register(RegistrationSubmission input) async {
    if (!mounted) return const Result.err(AuthFailure.unavailable);
    final operation = ++_operation;
    final result = await _repository.register(input);
    if (!_active(operation)) return const Result.err(AuthFailure.unavailable);
    return result.when(
      val: (data) async {
        if (!_isAuthenticationResponse(data) || data['sent'] is! bool) {
          return const Result.err(AuthFailure.invalidResponse);
        }
        final saved = await _save(data['token'] as String, operation);
        if (!_active(operation)) {
          return const Result.err(AuthFailure.unavailable);
        }
        if (saved is Failure<Ok, AuthFailure>) return saved;
        _accept(data, smsSent: data['sent'] as bool);
        return const Result.val(Ok());
      },
      err: (error) async => Result.err(error),
    );
  }

  /// Signs in and loads user data for an already verified account.
  Future<AuthResult> login(String identifier, String password) async {
    if (!mounted) return const Result.err(AuthFailure.unavailable);
    final operation = ++_operation;
    final result = await _repository.login(identifier, password);
    if (!_active(operation)) return const Result.err(AuthFailure.unavailable);
    return result.when(
      val: (data) async {
        if (!_isAuthenticationResponse(data)) {
          return const Result.err(AuthFailure.invalidResponse);
        }
        final saved = await _save(data['token'] as String, operation);
        if (!_active(operation)) {
          return const Result.err(AuthFailure.unavailable);
        }
        if (saved is Failure<Ok, AuthFailure>) return saved;
        if (data['verified'] == true) {
          final token = data['token'] as String;
          _token = token;
          final session = await _fetchSession(
            token,
            operation,
            establishSession: true,
          );
          if (!_active(operation)) {
            return const Result.err(AuthFailure.unavailable);
          }
          if (session is Failure<Ok, AuthFailure>) {
            _accept(data, verified: false);
            state = state.copyWith(verified: false, connectionFailed: true);
          }
          return session;
        }
        _accept(data);
        return const Result.val(Ok());
      },
      err: (error) async => Result.err(error),
    );
  }

  /// Requests another verification code.
  Future<AuthResult> resend() async {
    if (!mounted) return const Result.err(AuthFailure.unavailable);
    final token = _token;
    if (token == null) return const Result.err(AuthFailure.unauthorized);
    final operation = _operation;
    final result = await _repository.resend(token);
    if (!_active(operation)) return const Result.err(AuthFailure.unavailable);
    if (result is! Failure<Ok, AuthFailure>) {
      state = state.copyWith(smsSent: true);
    }
    return result;
  }

  /// Verifies the phone and reloads the server session.
  Future<AuthResult> verify(String code) async {
    if (!mounted) return const Result.err(AuthFailure.unavailable);
    final token = _token;
    if (token == null) return const Result.err(AuthFailure.unauthorized);
    final operation = ++_operation;
    final result = await _repository.verify(token, code);
    if (!_active(operation)) return const Result.err(AuthFailure.unavailable);
    return result.when(
      val: (_) async {
        final session = await _fetchSession(token, operation);
        if (!_active(operation)) {
          return const Result.err(AuthFailure.unavailable);
        }
        if (session is Failure<Ok, AuthFailure>) {
          state = state.copyWith(verified: false, connectionFailed: true);
        }
        return session;
      },
      err: (error) async => Result.err(error),
    );
  }

  /// Invalidates the remote session and clears locally persisted credentials.
  Future<AuthResult> logout() async {
    if (!mounted) return const Result.err(AuthFailure.unavailable);
    final operation = ++_operation;
    final token = _token;
    if (token != null) {
      final result = await _repository.logout(token);
      if (!_active(operation)) return const Result.err(AuthFailure.unavailable);
      if (result case Failure<Ok, AuthFailure>(error: final error)) {
        if (error != AuthFailure.unauthorized) return result;
      }
    }
    return _clear(operation);
  }

  void _accept(Map<String, dynamic> data, {bool? smsSent, bool? verified}) {
    _token = data['token'] as String;
    state = state.copyWith(
      hasSession: true,
      verified: verified ?? data['verified'] as bool,
      phone: data['phone'] as String?,
      smsSent: smsSent,
      eligibility: null,
      user: null,
      connectionFailed: false,
    );
  }

  bool _isAuthenticationResponse(Map<String, dynamic> data) =>
      data['token'] is String &&
      (data['token'] as String).isNotEmpty &&
      data['verified'] is bool &&
      (data['phone'] == null || data['phone'] is String);

  Future<AuthResult> _fetchSession(
    String token,
    int operation, {
    bool establishSession = false,
  }) async {
    final result = await _repository.session(token);
    if (!_active(operation)) return const Result.err(AuthFailure.unavailable);
    return result.when(
      val: (data) {
        final user = data['user'];
        if (user is! Map<String, dynamic> ||
            user['dateOfBirth'] is! String ||
            (user['id'] != null && user['id'] is! String) ||
            (user['name'] != null && user['name'] is! String) ||
            data['verified'] is! bool ||
            (data['phone'] != null && data['phone'] is! String)) {
          return const Result.err(AuthFailure.invalidResponse);
        }
        try {
          final dateOfBirth = user['dateOfBirth'] as String;
          state = state.copyWith(
            hasSession: establishSession || state.hasSession,
            connectionFailed: false,
            smsSent: establishSession ? null : state.smsSent,
            verified: data['verified'] as bool,
            phone: data['phone'] as String?,
            eligibility: evaluateEligibility(dateOfBirth),
            user: SessionUser(
              id: user['id'] as String?,
              name: user['name'] as String?,
              dateOfBirth: dateOfBirth,
            ),
          );
          return const Result.val(Ok());
        } on EligibilityValidationException {
          return const Result.err(AuthFailure.invalidResponse);
        }
      },
      err: Result.err,
    );
  }

  Future<AuthResult> _clear(int operation) async {
    final result = await _runStorage(() async {
      if (!_active(operation)) {
        return const Result<Ok, AuthFailure>.err(AuthFailure.unavailable);
      }
      return _repository.clearToken();
    });
    if (!_active(operation)) return const Result.err(AuthFailure.unavailable);
    if (result is! Failure<Ok, AuthFailure>) {
      _token = null;
      state = SessionState(initialized: state.initialized);
    }
    return result;
  }

  Future<AuthResult> _save(String token, int operation) => _runStorage(
    () async {
      if (!_active(operation)) return const Result.err(AuthFailure.unavailable);
      final previousToken = _token;
      final result = await _repository.saveToken(token);
      if (!_active(operation) && result is! Failure<Ok, AuthFailure>) {
        if (previousToken == null) {
          await _repository.clearToken();
        } else {
          await _repository.saveToken(previousToken);
        }
        return const Result.err(AuthFailure.unavailable);
      }
      return result;
    },
  );

  Future<T> _runStorage<T>(Future<T> Function() action) {
    final result = _storageQueue.then((_) => action());
    _storageQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }
}
