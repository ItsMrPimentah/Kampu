import assert from 'node:assert/strict';
import test from 'node:test';
import { seedFixtures, seedIds, seedTimestamp } from '../scripts/seed-fixtures';

test('seed fixtures are deterministic and non-sensitive', () => {
  assert.equal(seedTimestamp, '2026-01-01T00:00:00.000Z');
  assert.equal(seedFixtures.users[0].externalAuthId, 'seed:adult-captain');
  assert.equal(seedFixtures.venues[0].name, 'PlayArena Lisbon');
  assert.equal(seedFixtures.stripeSandboxEvent.eventType, 'stripe.sandbox.payment_succeeded');
  assert.match(seedFixtures.stripeSandboxEvent.providerReference, /^pi_seed_sandbox_/);
  assert.ok(Object.values(seedIds).every((id) => /^[0-9a-f-]{36}$/.test(id)));
  assert.equal(JSON.stringify(seedFixtures).includes('sk_live_'), false);
  assert.equal(JSON.stringify(seedFixtures).includes('prod'), false);
});
