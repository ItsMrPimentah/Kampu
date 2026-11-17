import assert from 'node:assert/strict';
import test from 'node:test';
import { PlayArenaConnector } from '../src/modules/venues/playarena-connector';

test('supports sandbox pilot availability and idempotent reservations', async () => {
  const connector = new PlayArenaConnector();
  assert.equal((await connector.searchAvailability({ region: 'Lisbon', format: '5v5', startsAt: '2026-11-01T10:00:00Z' })).length, 1);
  assert.equal((await connector.searchAvailability({ region: 'Porto', format: '5v5', startsAt: '2026-11-01T10:00:00Z' })).length, 0);
  const first = await connector.createReservation({ venueId: 'PlayArena Lisbon', providerSlotId: 'slot-1', idempotencyKey: 'key-1' });
  const second = await connector.createReservation({ venueId: 'PlayArena Lisbon', providerSlotId: 'slot-1', idempotencyKey: 'key-1' });
  assert.equal(first.providerReference, second.providerReference);
});

test('accepts only signed provider confirmation events', async () => {
  const connector = new PlayArenaConnector();
  const event = { eventId: 'event-1', providerReference: 'pa-slot-1', status: 'confirmed' as const, occurredAt: '2026-11-01T10:00:00Z' };
  const confirmed = await connector.handleProviderEvent({ ...event, signature: connector.sign(event) });
  assert.equal(confirmed.status, 'confirmed');
  await assert.rejects(connector.handleProviderEvent({ ...event, signature: 'tampered' }), /signature/);
});
