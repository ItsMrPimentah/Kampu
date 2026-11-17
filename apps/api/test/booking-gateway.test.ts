import assert from 'node:assert/strict';
import test from 'node:test';
import { assertConnectorContract } from '../src/modules/venues/booking-gateway';
import { FakeBookingConnector } from '../src/modules/venues/fake-connector';

test('fake connector satisfies the Booking Gateway contract and is idempotent', async () => {
  const connector = new FakeBookingConnector();
  assertConnectorContract(connector);
  const first = await connector.createReservation({ venueId: 'venue', providerSlotId: 'slot', idempotencyKey: 'key-1' });
  const second = await connector.createReservation({ venueId: 'venue', providerSlotId: 'slot', idempotencyKey: 'key-1' });
  assert.equal(first.providerReference, second.providerReference);
  assert.deepEqual(await connector.health().then((value) => value.healthy), true);
});
