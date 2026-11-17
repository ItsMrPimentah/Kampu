import assert from 'node:assert/strict';
import test from 'node:test';
import { BookingLifecycleError, BookingService } from '../src/modules/venues/booking.service';
import { PlayArenaConnector } from '../src/modules/venues/playarena-connector';

test('deduplicates provider events and expires pending bookings', async () => {
  const connector = new PlayArenaConnector();
  const service = new BookingService(connector);
  const booking = await service.reserve({ id: 'booking-1', matchId: 'match-1', venueId: 'PlayArena Lisbon', providerSlotId: 'slot-1', idempotencyKey: 'key-1', expiresAt: '2026-01-01T00:00:00Z' });
  const event = { eventId: 'provider-event-1', providerReference: booking.providerReference!, status: 'confirmed' as const, occurredAt: '2025-12-01T00:00:00Z' };
  const signed = { ...event, signature: connector.sign(event) };
  await service.applyProviderEvent(booking.id, signed);
  await service.applyProviderEvent(booking.id, signed);
  assert.equal(service.get(booking.id)?.providerEvents.length, 1);
  assert.equal(service.get(booking.id)?.status, 'confirmed');

  const pending = await service.reserve({ id: 'booking-2', matchId: 'match-1', venueId: 'PlayArena Lisbon', providerSlotId: 'slot-2', idempotencyKey: 'key-2', expiresAt: '2026-01-01T00:00:00Z' });
  assert.equal(service.expire(pending.id, new Date('2026-02-01T00:00:00Z')).status, 'failed');
});

test('rejects manual confirmation', () => {
  const service = new BookingService(new PlayArenaConnector());
  assert.throws(() => service.confirmManually('booking-1'), BookingLifecycleError);
});
