import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_client.dart';
import '../core/community/community_repository.dart';
import '../shared/external/http/api_client.dart';
import '../core/eligibility/eligibility.dart';
import 'auth/auth_repository.dart';
import '../core/registration/registration_models.dart';

/// Immutable view of the current application session.
class AuthSessionState {
  /// Creates a session snapshot without exposing its token.
  const AuthSessionState({
    required this.initialized,
    required this.hasSession,
    required this.verified,
    required this.connectionFailed,
    required this.smsSent,
    required this.phone,
    required this.eligibility,
  });

  /// Whether session restoration has completed.
  final bool initialized;

  /// Whether a session token exists.
  final bool hasSession;

  /// Whether the phone is verified.
  final bool verified;

  /// Whether the session service is unavailable.
  final bool connectionFailed;

  /// Whether the verification message was sent, or null if unknown.
  final bool? smsSent;

  /// Phone number associated with the session.
  final String? phone;

  /// Current account eligibility.
  final EligibilityDecision? eligibility;
}

/// Exposes session changes through Riverpod while the legacy client is migrated.
class AuthSessionController extends StateNotifier<AuthSessionState> {
  /// Observes an injected authentication client.
  AuthSessionController(this._client) : super(_snapshot(_client)) {
    _client.addListener(_changed);
  }
  final AuthClient _client;

  static AuthSessionState _snapshot(AuthClient client) => AuthSessionState(
    initialized: client.initialized,
    hasSession: client.hasSession,
    verified: client.verified,
    connectionFailed: client.connectionFailed,
    smsSent: client.smsSent,
    phone: client.phone,
    eligibility: client.eligibility,
  );
  void _changed() => state = _snapshot(_client);

  /// Current snapshot used by routing and other application services.
  AuthSessionState get snapshot => state;

  /// Restores the stored session.
  Future<void> restore() => _client.restore();

  /// Signs in with the supplied credentials.
  Future<AuthResult> login(String identifier, String password) =>
      _client.login(identifier, password);

  /// Registers a new account.
  Future<AuthResult> register(RegistrationSubmission input) =>
      _client.register(input);

  /// Verifies the phone number.
  Future<AuthResult> verify(String code) => _client.verify(code);

  /// Requests a new verification code.
  Future<AuthResult> resend() => _client.resend();

  /// Signs out the current session.
  Future<AuthResult> logout() => _client.logout();

  /// Supplies the current token to an authenticated service.
  String? get sessionToken => _client.sessionToken;

  @override
  void dispose() {
    _client.removeListener(_changed);
    super.dispose();
  }
}

/// Owns the current authentication client and disposes it with the app scope.
final authClientProvider = Provider<AuthClient>((ref) {
  final client = AuthClient();
  ref.onDispose(client.dispose);
  return client;
});

/// Tracks application-wide authentication state.
final authSessionProvider =
    StateNotifierProvider<AuthSessionController, AuthSessionState>(
      (ref) => AuthSessionController(ref.watch(authClientProvider)),
    );

/// Owns the community API client while reading the current session on each call.
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final auth = ref.watch(authClientProvider);
  final dio = createApiClient();
  ref.onDispose(dio.close);
  return DioCommunityRepository(dio: dio, token: () => auth.sessionToken);
});
