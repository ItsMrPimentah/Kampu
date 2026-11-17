import assert from 'node:assert/strict';
import test from 'node:test';
import { BookingStateError, BookingStateService } from '../src/modules/venues/booking-state.service';

test('keeps booking state separate from challenge state', () => {
  const service = new BookingStateService();
  service.create('booking-1', 'match-1', 'agreed');
  assert.equal(service.get('booking-1')?.bookingStatus, 'not_requested');
  assert.throws(() => service.transition('booking-1', 'confirmed', 'user_declared'), BookingStateError);
  const pending = service.transition('booking-1', 'pending_provider_confirmation', 'provider');
  assert.equal(pending.providerConfirmed, false);
  const confirmed = service.transition('booking-1', 'confirmed', 'provider', true);
  assert.equal(confirmed.providerConfirmed, true);
});
