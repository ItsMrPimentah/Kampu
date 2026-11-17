export type EligibilityCategory = 'youth' | 'adult';

export interface EligibilityDecision {
  eligible: true;
  category: EligibilityCategory;
  policyVersion: string;
  age: number;
  dateOfBirth: string;
}

export class EligibilityError extends Error {
  constructor(public readonly reason: 'invalid_date' | 'future_date' | 'under_minimum_age', message: string) {
    super(message);
    this.name = 'EligibilityError';
  }
}

function parseDateOfBirth(value: string): Date {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new EligibilityError('invalid_date', 'Date of birth must use YYYY-MM-DD');
  }
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new EligibilityError('invalid_date', 'Date of birth is not a valid calendar date');
  }
  return date;
}

export function evaluateEligibility(dateOfBirth: string, now = new Date(), policyVersion = 'age-13-v1'): EligibilityDecision {
  const dob = parseDateOfBirth(dateOfBirth);
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  if (dob > today) throw new EligibilityError('future_date', 'Date of birth cannot be in the future');

  let age = today.getUTCFullYear() - dob.getUTCFullYear();
  const birthdayHasPassed = today.getUTCMonth() > dob.getUTCMonth()
    || (today.getUTCMonth() === dob.getUTCMonth() && today.getUTCDate() >= dob.getUTCDate());
  if (!birthdayHasPassed) age -= 1;
  if (age < 13) throw new EligibilityError('under_minimum_age', 'Showtime accounts require a minimum age of 13');

  return {
    eligible: true,
    category: age < 18 ? 'youth' : 'adult',
    policyVersion,
    age,
    dateOfBirth,
  };
}
