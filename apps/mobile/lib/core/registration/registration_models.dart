import '../eligibility/eligibility.dart';

enum RegistrationRole { player, squadCaptain, guardian }

extension RegistrationRoleLabel on RegistrationRole {
  String get label => switch (this) {
    RegistrationRole.player => 'Player',
    RegistrationRole.squadCaptain => 'Squad Captain',
    RegistrationRole.guardian => 'Guardian',
  };

  String get description => switch (this) {
    RegistrationRole.player => 'Find matches, track stats, join squads',
    RegistrationRole.squadCaptain =>
      'Organize games, manage rosters & collections',
    RegistrationRole.guardian => 'Support youth-safe match coordination',
  };

  String get badge => switch (this) {
    RegistrationRole.player => 'DEFAULT',
    RegistrationRole.squadCaptain => 'PRO',
    RegistrationRole.guardian => 'YOUTH SAFE',
  };
}

enum RegistrationField { fullName, dateOfBirth, phone, email, password, terms }

enum PasswordStrength { empty, weak, medium, strong }

class RegistrationSubmission {
  const RegistrationSubmission({
    required this.role,
    required this.fullName,
    required this.dateOfBirth,
    required this.phone,
    required this.email,
    required this.password,
    required this.eligibility,
  });

  final RegistrationRole role;
  final String fullName;
  final String dateOfBirth;
  final String phone;
  final String email;
  final String password;
  final EligibilityDecision eligibility;
}

class RegistrationValidationResult {
  RegistrationValidationResult({
    required Map<RegistrationField, String> errors,
    required this.passwordStrength,
    this.eligibility,
  }) : errors = Map.unmodifiable(errors);

  final Map<RegistrationField, String> errors;
  final PasswordStrength passwordStrength;
  final EligibilityDecision? eligibility;

  bool get isValid => errors.isEmpty && eligibility != null;
}
