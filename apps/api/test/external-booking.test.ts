import assert from 'node:assert/strict';
import test from 'node:test';
import { ExternalBookingError, ExternalBookingService } from '../src/modules/venues/external-booking.service';

test('records complete external reservations as user-declared', () => {
  const service = new ExternalBookingService();
  const declaration = service.declare({ matchId: 'match-1', venueId: 'venue-1', requestedAt: '2026-11-01T10:00:00.000Z', sourceUrl: 'https://venue.example/booking', externalReference: 'ABC-1', receiptMetadata: { objectKey: 'receipts/abc.pdf', contentType: 'application/pdf' } });
  assert.equal(declaration.status, 'externally_declared');
  assert.equal(declaration.verificationLevel, 'user_declared');
});

test('rejects incomplete external declarations', () => {
  const service = new ExternalBookingService();
  assert.throws(() => service.declare({ matchId: '', venueId: 'venue', requestedAt: '2026-11-01T10:00:00Z', sourceUrl: 'https://example.com' }), ExternalBookingError);
  assert.throws(() => service.declare({ matchId: 'match', venueId: 'venue', requestedAt: 'invalid', sourceUrl: 'https://example.com' }), /Requested/);
  assert.throws(() => service.declare({ matchId: 'match', venueId: 'venue', requestedAt: '2026-11-01T10:00:00Z', sourceUrl: 'not-a-url' }), /Source URL/);
});
