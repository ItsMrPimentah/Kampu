import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A verification operation supplied by the app authentication layer.
typedef VerificationAction = Future<bool> Function();

/// State of the current verification operation.
class VerifyPhoneState {
  /// Creates a verification state.
  const VerifyPhoneState({this.loading = false, this.message});

  /// Whether an operation is in flight.
  final bool loading;

  /// User-visible feedback for the most recent operation.
  final String? message;
}

/// Coordinates phone verification, resend and sign-out actions.
class VerifyPhoneController extends StateNotifier<VerifyPhoneState> {
  /// Creates a controller for a verification screen.
  VerifyPhoneController() : super(const VerifyPhoneState());

  /// Validates and submits a six-digit verification code.
  Future<void> verify(String code, Future<bool> Function(String) action) async {
    if (state.loading) return;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      state = const VerifyPhoneState(message: 'Enter the 6-digit code.');
      return;
    }
    await _run(
      () => action(code),
      failure:
          'Unable to verify your phone. Please try again or request a new SMS.',
    );
  }

  /// Requests another verification SMS.
  Future<void> resend(VerificationAction action) => _run(
    action,
    success: 'A new code has been requested.',
    failure: 'Unable to resend the SMS. Please try again.',
  );

  /// Signs out of the current account.
  Future<void> signOut(VerificationAction action) =>
      _run(action, failure: 'Unable to sign out. Please try again.');

  Future<void> _run(
    VerificationAction action, {
    String? success,
    required String failure,
  }) async {
    if (state.loading) return;
    state = const VerifyPhoneState(loading: true);
    final completed = await action();
    if (!mounted) return;
    state = VerifyPhoneState(message: completed ? success : failure);
  }
}

/// Owns transient verification screen state.
final verifyPhoneControllerProvider =
    StateNotifierProvider.autoDispose<VerifyPhoneController, VerifyPhoneState>(
      (ref) => VerifyPhoneController(),
    );
