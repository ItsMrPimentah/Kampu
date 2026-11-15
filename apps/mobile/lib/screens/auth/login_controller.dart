import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A sign-in operation supplied by the app's authentication composition root.
typedef LoginAction = Future<bool> Function(String identifier, String password);

/// State of the sign-in operation.
class LoginState {
  /// Creates a sign-in state.
  const LoginState({this.loading = false, this.error});

  /// Whether a sign-in request is in flight.
  final bool loading;

  /// User-visible validation or sign-in failure.
  final String? error;
}

/// Coordinates sign-in validation and requests.
class LoginController extends StateNotifier<LoginState> {
  /// Creates a controller with the injected authentication action.
  LoginController(this._login) : super(const LoginState());

  final LoginAction _login;

  /// Validates credentials and signs in once at a time.
  Future<void> submit(String identifier, String password) async {
    if (state.loading) return;
    final trimmed = identifier.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      state = const LoginState(
        error: 'Enter your phone or email and password.',
      );
      return;
    }
    state = const LoginState(loading: true);
    final success = await _login(trimmed, password);
    if (!mounted) return;
    state = success
        ? const LoginState()
        : const LoginState(
            error: 'Unable to sign in. Check your details and connection.',
          );
  }
}

/// Owns the login controller for a screen's injected action.
final loginControllerProvider = StateNotifierProvider.autoDispose
    .family<LoginController, LoginState, LoginAction>(
      (ref, action) => LoginController(action),
    );
