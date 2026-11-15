/// Supported account age categories.
enum EligibilityCategory { youth, adult }

/// The account category and age determined from a valid date of birth.
class EligibilityDecision {
  /// Creates an eligibility decision.
  const EligibilityDecision({required this.category, required this.age});

  /// The resulting account category.
  final EligibilityCategory category;

  /// Age in completed years.
  final int age;
}

/// Indicates that a date of birth does not satisfy the account policy.
class EligibilityValidationException implements Exception {
  /// Creates an error with a user-visible explanation.
  const EligibilityValidationException(this.message);

  /// Explanation of the invalid date.
  final String message;
}

/// Evaluates the minimum-age policy against [input] in `YYYY-MM-DD` format.
EligibilityDecision evaluateEligibility(String input, {DateTime? today}) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(input);
  if (match == null) {
    throw const EligibilityValidationException('Use date format YYYY-MM-DD.');
  }
  final year = int.parse(input.substring(0, 4));
  final month = int.parse(input.substring(5, 7));
  final day = int.parse(input.substring(8, 10));
  final dob = DateTime.utc(year, month, day);
  if (dob.year != year || dob.month != month || dob.day != day) {
    throw const EligibilityValidationException('Enter a valid calendar date.');
  }
  final reference = today ?? DateTime.now().toUtc();
  final currentDay = DateTime.utc(
    reference.year,
    reference.month,
    reference.day,
  );
  if (dob.isAfter(currentDay)) {
    throw const EligibilityValidationException(
      'Date of birth cannot be in the future.',
    );
  }
  var age = currentDay.year - dob.year;
  final beforeBirthday =
      currentDay.month < dob.month ||
      (currentDay.month == dob.month && currentDay.day < dob.day);
  if (beforeBirthday) age--;
  if (age < 13) {
    throw const EligibilityValidationException(
      'Showtime accounts require a minimum age of 13.',
    );
  }
  return EligibilityDecision(
    age: age,
    category: age < 18 ? EligibilityCategory.youth : EligibilityCategory.adult,
  );
}
