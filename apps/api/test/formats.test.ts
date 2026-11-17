import assert from 'node:assert/strict';
import test from 'node:test';
import { calculateReadiness, formatConfig } from '../src/modules/teams/formats';

test('accepts all configured MVP formats with their roster sizes', () => {
  assert.equal(formatConfig('5v5').startingRoster, 5);
  assert.equal(formatConfig('7v7').startingRoster, 7);
  assert.equal(formatConfig('11v11').startingRoster, 11);
  assert.equal(formatConfig('futsal').startingRoster, 5);
  assert.equal(formatConfig('futevoley_2v2').startingRoster, 2);
  assert.throws(() => formatConfig('8v8'), /Unsupported/);
});

test('does not mark incomplete teams ready', () => {
  const incomplete = calculateReadiness('7v7', ['7v7'], 6);
  assert.equal(incomplete.ready, false);
  assert.equal(incomplete.additionalPlayersNeeded, 1);
  const complete = calculateReadiness('7v7', ['7v7'], 7);
  assert.equal(complete.ready, true);
});
