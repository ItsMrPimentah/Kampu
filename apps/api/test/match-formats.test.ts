import assert from 'node:assert/strict';
import test from 'node:test';
import { supportedChallengeFormats, validateChallengeFormat } from '../src/modules/matches/match-formats';

test('accepts all configured challenge formats with validation metadata', () => {
  assert.deepEqual(supportedChallengeFormats().map((format) => format.format), ['5v5', '7v7', '11v11', 'futsal', 'futevoley_2v2']);
  assert.equal(validateChallengeFormat('futevoley_2v2').startingRoster, 2);
  assert.equal(validateChallengeFormat('futsal').policyVersion, 'formats-v1');
});

test('rejects unsupported challenge formats', () => {
  assert.throws(() => validateChallengeFormat('beach-soccer'), /Unsupported football format/);
});
