enum EligibilityCategory { youth, adult }

class EligibilityDecision {
  const EligibilityDecision({required this.category, required this.age});

  final EligibilityCategory category;
  final int age;
}

class EligibilityValidationException implements Exception {
  const EligibilityValidationException(this.message);

  final String message;
}

EligibilityDecision evaluateEligibility(String input, {DateTime? today}) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(input);
  if (match == null) {
    throw const EligibilityValidationException('Use date format YYYY-MM-DD.');
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
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
