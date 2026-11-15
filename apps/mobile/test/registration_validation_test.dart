import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/core/registration/registration_models.dart';
import 'package:showtime_mobile/core/registration/registration_validation.dart';

void main() {
  final today = DateTime.utc(2026, 11, 2);

  test('normalizes the Stitch date format', () {
    expect(normalizeDateOfBirth('24 / 06 / 2008'), '2008-06-24');
    expect(normalizeDateOfBirth('bad date'), isNull);
  });

  test('preserves the existing age boundaries', () {
    final youth = validateRegistration(
      fullName: 'Leo Messi',
      dateOfBirth: '03 / 11 / 2008',
      phone: '+49 151 8920 4410',
      email: 'leo@example.com',
      password: 'TacticalStriker2024!',
      acceptedTerms: true,
      today: today,
    );
    final adult = validateRegistration(
      fullName: 'Alex Morgan',
      dateOfBirth: '02 / 11 / 2008',
      phone: '+49 151 8920 4410',
      email: 'alex@example.com',
      password: 'TacticalStriker2024!',
      acceptedTerms: true,
      today: today,
    );

    expect(youth.eligibility?.category, EligibilityCategory.youth);
    expect(adult.eligibility?.category, EligibilityCategory.adult);
  });

  test('rejects underage, invalid, and incomplete input', () {
    final result = validateRegistration(
      fullName: '',
      dateOfBirth: '03 / 11 / 2013',
      phone: '12',
      email: 'invalid',
      password: 'weak',
      acceptedTerms: false,
      today: today,
    );

    expect(result.isValid, isFalse);
    expect(result.errors[RegistrationField.fullName], isNotNull);
    expect(
      result.errors[RegistrationField.dateOfBirth],
      contains('minimum age'),
    );
    expect(result.errors[RegistrationField.phone], isNotNull);
    expect(result.errors[RegistrationField.email], isNotNull);
    expect(result.errors[RegistrationField.password], isNotNull);
    expect(result.errors[RegistrationField.terms], isNotNull);
  });

  test('classifies password strength without exposing the password', () {
    expect(passwordStrength(''), PasswordStrength.empty);
    expect(passwordStrength('password'), PasswordStrength.weak);
    expect(passwordStrength('Password1'), PasswordStrength.medium);
    expect(passwordStrength('TacticalStriker2024!'), PasswordStrength.strong);
  });
}
