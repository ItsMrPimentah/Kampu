import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/core/registration/registration_models.dart';
import 'package:showtime_mobile/core/registration/registration_validation.dart';

/// A snapshot of form input, used only while validating or submitting.
class RegistrationInput {
  /// Creates a registration input snapshot.
  const RegistrationInput({
    required this.fullName,
    required this.dateOfBirth,
    required this.phone,
    required this.email,
    required this.password,
    required this.countryCode,
    required this.acceptedTerms,
  });

  /// Entered full name.
  final String fullName;

  /// Entered date of birth.
  final String dateOfBirth;

  /// Entered phone number without country code.
  final String phone;

  /// Entered email.
  final String email;

  /// Entered password; never stored in controller state.
  final String password;

  /// Selected country code.
  final String countryCode;

  /// Whether terms were accepted.
  final bool acceptedTerms;
}

/// State of registration validation and submission.
class RegistrationState {
  /// Creates registration state.
  const RegistrationState({
    this.role = RegistrationRole.player,
    this.hasSubmitted = false,
    this.submitting = false,
    this.submitted = false,
    this.error,
    this.validation,
    this.strength = PasswordStrength.empty,
  });

  /// Selected account role.
  final RegistrationRole role;

  /// Whether validation has been requested.
  final bool hasSubmitted;

  /// Whether a submission is in flight.
  final bool submitting;

  /// Whether a submission completed successfully.
  final bool submitted;

  /// Submission failure message.
  final String? error;

  /// Current validation feedback.
  final RegistrationValidationResult? validation;

  /// Current password strength.
  final PasswordStrength strength;

  /// Copies state with explicit nullable-field replacement.
  RegistrationState copyWith({
    RegistrationRole? role,
    bool? hasSubmitted,
    bool? submitting,
    bool? submitted,
    String? error,
    bool clearError = false,
    RegistrationValidationResult? validation,
    bool clearValidation = false,
    PasswordStrength? strength,
  }) => RegistrationState(
    role: role ?? this.role,
    hasSubmitted: hasSubmitted ?? this.hasSubmitted,
    submitting: submitting ?? this.submitting,
    submitted: submitted ?? this.submitted,
    error: clearError ? null : error ?? this.error,
    validation: clearValidation ? null : validation ?? this.validation,
    strength: strength ?? this.strength,
  );
}

/// Coordinates registration validation, preview and submission.
class RegistrationController extends StateNotifier<RegistrationState> {
  /// Creates the registration screen controller.
  RegistrationController() : super(const RegistrationState());

  /// Selects the account role.
  void selectRole(RegistrationRole role) => state = state.copyWith(role: role);

  RegistrationValidationResult _validate(RegistrationInput input) =>
      validateRegistration(
        fullName: input.fullName,
        dateOfBirth: input.dateOfBirth,
        phone: '${input.countryCode} ${input.phone}',
        email: input.email,
        password: input.password,
        acceptedTerms: input.acceptedTerms,
      );

  /// Updates validation and eligibility preview as fields change.
  void fieldsChanged(RegistrationInput input) {
    final strength = passwordStrength(input.password);
    if (state.hasSubmitted) {
      state = state.copyWith(validation: _validate(input), strength: strength);
      return;
    }
    final normalized = normalizeDateOfBirth(input.dateOfBirth);
    EligibilityDecision? eligibility;
    if (normalized != null) {
      try {
        eligibility = evaluateEligibility(normalized);
      } on EligibilityValidationException {
        eligibility = null;
      }
    }
    state = state.copyWith(
      strength: strength,
      validation: RegistrationValidationResult(
        errors: const {},
        passwordStrength: strength,
        eligibility: eligibility,
      ),
    );
  }

  /// Validates and submits at most one registration at a time.
  Future<void> submit(
    RegistrationInput input,
    Future<bool> Function(RegistrationSubmission) action,
  ) async {
    if (state.submitting || state.submitted) return;
    final validation = _validate(input);
    state = state.copyWith(
      hasSubmitted: true,
      clearError: true,
      validation: validation,
      strength: validation.passwordStrength,
    );
    final date = normalizeDateOfBirth(input.dateOfBirth);
    final eligibility = validation.eligibility;
    if (!validation.isValid || date == null || eligibility == null) return;
    final submission = RegistrationSubmission(
      role: state.role,
      fullName: input.fullName.trim(),
      dateOfBirth: date,
      phone: '${input.countryCode} ${input.phone.trim()}',
      email: input.email.trim(),
      password: input.password,
      eligibility: eligibility,
    );
    state = state.copyWith(submitting: true);
    final success = await action(submission);
    if (!mounted) return;
    state = state.copyWith(
      submitting: false,
      submitted: success,
      error: success ? null : 'We could not continue. Please try again.',
      clearError: success,
    );
  }
}

/// Provides screen-scoped registration state.
final registrationControllerProvider =
    StateNotifierProvider.autoDispose<
      RegistrationController,
      RegistrationState
    >((ref) => RegistrationController());
