import assert from 'node:assert/strict';
import test from 'node:test';
import { VenueService } from '../src/modules/venues/venue.service';

test('searches the PlayArena pilot catalog by region and format', () => {
  const service = new VenueService();
  service.seedPlayArena('Lisbon', ['5v5', 'futsal']);
  service.seedPlayArena('Setúbal', ['7v7']);
  const results = service.search({ region: 'Lisbon', format: 'futsal', bookingMethod: 'native' });
  assert.equal(results.length, 1);
  assert.equal(results[0].source, 'PlayArena');
  assert.equal(results[0].verificationLevel, 'operator_verified');
  assert.equal(results[0].locationPrecision, 'region_only');
});
