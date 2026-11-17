import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/onboarding/eligibility.dart';

void main() {
  final today = DateTime.utc(2026, 10, 19);

  test('classifies youth and adult boundaries', () {
    expect(
      evaluateEligibility('2013-10-19', today: today).category,
      EligibilityCategory.youth,
    );
    expect(
      evaluateEligibility('2008-10-19', today: today).category,
      EligibilityCategory.adult,
    );
    expect(
      evaluateEligibility('2008-10-20', today: today).category,
      EligibilityCategory.youth,
    );
  });

  test('rejects underage and invalid dates', () {
    expect(
      () => evaluateEligibility('2013-10-20', today: today),
      throwsA(isA<EligibilityValidationException>()),
    );
    expect(
      () => evaluateEligibility('2026-11-01', today: today),
      throwsA(isA<EligibilityValidationException>()),
    );
    expect(
      () => evaluateEligibility('not-a-date', today: today),
      throwsA(isA<EligibilityValidationException>()),
    );
  });
}
