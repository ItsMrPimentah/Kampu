import assert from 'node:assert/strict';
import test from 'node:test';
import { ProfileService } from '../src/modules/players/profile.service';

test('stores and updates an eligible player profile', () => {
  const service = new ProfileService();
  service.save({ userId: 'u1', eligibility: 'adult', displayName: '  Alex  ', preferredPositions: ['midfielder'], skillLevel: 'intermediate', availability: { saturday: true }, approximateLocation: { region: 'Lisbon', latitude: 38.7, longitude: -9.1 } });
  assert.equal(service.get('u1')?.displayName, 'Alex');
  service.save({ userId: 'u1', eligibility: 'adult', displayName: 'Alex Silva', preferredPositions: ['goalkeeper'], availability: {}, approximateLocation: { region: 'Setúbal' } });
  assert.equal(service.get('u1')?.preferredPositions[0], 'goalkeeper');
});

test('projects youth locations without precise coordinates and restricts unknown-adult discovery', () => {
  const service = new ProfileService();
  service.save({ userId: 'youth', eligibility: 'youth', displayName: 'Youth Player', preferredPositions: [], availability: {}, approximateLocation: { region: 'Lisbon', latitude: 38.7, longitude: -9.1 } });
  const projected = service.project('youth', { userId: 'adult', eligibility: 'adult', authorizedRelationship: true });
  assert.deepEqual(projected?.approximateLocation, { region: 'Lisbon' });
  assert.equal(service.discover({ userId: 'adult', eligibility: 'adult', authorizedRelationship: false }).length, 0);
});
