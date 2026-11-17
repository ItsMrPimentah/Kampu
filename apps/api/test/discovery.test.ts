import assert from 'node:assert/strict';
import test from 'node:test';
import { DiscoveryService } from '../src/modules/matches/discovery.service';

test('filters discovery by format, region, capacity, and kind', () => {
  const service = new DiscoveryService();
  service.add({ id: 'open-1', kind: 'open_game', format: '5v5', region: 'Lisbon', availableCapacity: 3, requiredPositions: ['goalkeeper'], hostEligibility: 'adult' });
  service.add({ id: 'challenge-1', kind: 'challenge', format: '7v7', region: 'Setúbal', availableCapacity: 0, requiredPositions: [], hostEligibility: 'adult' });
  const results = service.search({ viewerEligibility: 'adult', region: 'Lisbon', format: '5v5', kind: 'open_game' });
  assert.equal(results.length, 1);
  assert.equal(results[0].locationPrecision, 'approximate_region');
  assert.equal(results[0].communicationContext, 'team_or_match_only');
});

test('applies youth privacy restrictions to results', () => {
  const service = new DiscoveryService();
  service.add({ id: 'youth-game', kind: 'open_game', format: 'futevoley_2v2', region: 'Lisbon', availableCapacity: 1, requiredPositions: [], hostEligibility: 'youth' });
  assert.equal(service.search({ viewerEligibility: 'adult' }).length, 0);
  assert.equal(service.search({ viewerEligibility: 'youth' })[0].locationPrecision, 'approximate_region');
});
