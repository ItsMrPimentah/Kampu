import assert from 'node:assert/strict';
import test from 'node:test';
import { EligibilityError, evaluateEligibility } from '../src/modules/identity/eligibility';

const today = new Date('2026-10-19T12:00:00.000Z');

test('rejects malformed and impossible dates', () => {
  assert.throws(() => evaluateEligibility('19-10-2010', today), (error: unknown) => error instanceof EligibilityError && error.reason === 'invalid_date');
  assert.throws(() => evaluateEligibility('2027-01-01', today), (error: unknown) => error instanceof EligibilityError && error.reason === 'future_date');
});

test('rejects a user below the minimum age', () => {
  assert.throws(() => evaluateEligibility('2013-10-20', today), (error: unknown) => error instanceof EligibilityError && error.reason === 'under_minimum_age');
});

test('assigns youth at 13 and adult at 18', () => {
  assert.equal(evaluateEligibility('2013-10-19', today).category, 'youth');
  assert.equal(evaluateEligibility('2008-10-19', today).category, 'adult');
  assert.equal(evaluateEligibility('2008-10-20', today).category, 'youth');
});
