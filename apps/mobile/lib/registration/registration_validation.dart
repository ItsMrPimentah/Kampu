import '../onboarding/eligibility.dart';
import 'registration_models.dart';

String? normalizeDateOfBirth(String value) {
  final match = RegExp(r'^\s*(\d{1,2})\s*/\s*(\d{1,2})\s*/\s*(\d{4})\s*$')
      .firstMatch(value);
  if (match == null) return null;

  final day = match.group(1)!.padLeft(2, '0');
  final month = match.group(2)!.padLeft(2, '0');
  final year = match.group(3)!;
  return '$year-$month-$day';
}

PasswordStrength passwordStrength(String value) {
  if (value.isEmpty) return PasswordStrength.empty;

  var score = 0;
  if (value.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(value)) score++;
  if (RegExp(r'[a-z]').hasMatch(value)) score++;
  if (RegExp(r'\d').hasMatch(value)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;

  if (score <= 2) return PasswordStrength.weak;
  if (score <= 4) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

RegistrationValidationResult validateRegistration({
  required String fullName,
  required String dateOfBirth,
  required String phone,
  required String email,
  required String password,
  required bool acceptedTerms,
  DateTime? today,
}) {
  final errors = <RegistrationField, String>{};
  EligibilityDecision? eligibility;

  if (fullName.trim().length < 2) {
    errors[RegistrationField.fullName] = 'Enter your full name.';
  }

  final normalizedDate = normalizeDateOfBirth(dateOfBirth);
  if (normalizedDate == null) {
    errors[RegistrationField.dateOfBirth] = 'Use date format DD / MM / YYYY.';
  } else {
    try {
      eligibility = evaluateEligibility(normalizedDate, today: today);
    } on EligibilityValidationException catch (error) {
      errors[RegistrationField.dateOfBirth] = error.message;
    }
  }

  final normalizedPhone = phone.replaceAll(RegExp(r'[\s()-]'), '');
  if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalizedPhone)) {
    errors[RegistrationField.phone] = 'Enter a valid mobile number.';
  }

  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
    errors[RegistrationField.email] = 'Enter a valid email address.';
  }

  final strength = passwordStrength(password);
  if (strength != PasswordStrength.strong) {
    errors[RegistrationField.password] =
        'Use 8+ characters with upper, lower, number and symbol.';
  }

  if (!acceptedTerms) {
    errors[RegistrationField.terms] =
        'Accept the Code of Conduct and Privacy Policy.';
  }

  return RegistrationValidationResult(
    errors: errors,
    passwordStrength: strength,
    eligibility: eligibility,
  );
}
