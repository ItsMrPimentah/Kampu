import assert from 'node:assert/strict';
import test from 'node:test';
import { createDomainEvent } from '../src/shared/domain-events';
import { NotificationService } from '../src/modules/notifications/notification.service';

test('delivers templates for important lifecycle events from the outbox', () => {
  const service = new NotificationService();
  const eventTypes = [
    'challenge.proposed',
    'challenge.counteroffered',
    'challenge.approved',
    'challenge.material_changed',
    'booking.confirmed',
    'booking.failed',
    'payment.failed',
    'dispute.escalated',
    'match.cancelled',
    'attendance.requested',
    'attendance.no_show',
  ] as const;

  for (const [index, type] of eventTypes.entries()) {
    const event = createDomainEvent<Record<string, unknown>>({
      id: `event-${index}`,
      type,
      aggregateType: 'match',
      aggregateId: `match-${index}`,
      aggregateVersion: 1,
      payload: { matchLabel: 'Sunday 5v5' },
      metadata: {},
    });
    const [notification] = service.deliverFromOutbox(event, [{ userId: 'player-1', eligibility: 'adult' }]);

    assert.equal(notification.type, type);
    assert.equal(notification.payload.matchLabel, 'Sunday 5v5');
    assert.ok(notification.title);
    assert.ok(notification.body);
  }
});

test('deduplicates repeated outbox delivery per event and recipient', () => {
  const service = new NotificationService();
  const event = createDomainEvent<Record<string, unknown>>({
    id: 'event-duplicate',
    type: 'booking.failed',
    aggregateType: 'booking',
    aggregateId: 'booking-1',
    aggregateVersion: 2,
    payload: { matchLabel: 'Saturday match' },
    metadata: {},
  });
  const recipient = { userId: 'captain-1', eligibility: 'adult' as const };

  assert.equal(service.deliverFromOutbox(event, [recipient]).length, 1);
  assert.equal(service.deliverFromOutbox(event, [recipient]).length, 0);
  assert.equal(service.forUser(recipient.userId).length, 1);
});

test('removes precise youth location and unauthorized payment/report details', () => {
  const service = new NotificationService();
  const event = createDomainEvent<Record<string, unknown>>({
    id: 'event-youth',
    type: 'payment.failed',
    aggregateType: 'payment',
    aggregateId: 'payment-1',
    aggregateVersion: 1,
    payload: {
      matchLabel: 'Saturday match',
      venueName: 'Exact Stadium Address',
      address: 'Rua Exacta 12',
      coordinates: { latitude: 38.7, longitude: -9.1 },
      approximateLocation: 'Lisbon',
      amount: '50.00',
      currency: 'EUR',
      providerReference: 'secret-provider-reference',
      privateReport: 'private moderation evidence',
    },
    metadata: {},
  });

  const [notification] = service.deliverFromOutbox(event, [{ userId: 'youth-1', eligibility: 'youth' }]);

  assert.equal(notification.payload.approximateLocation, 'Lisbon');
  assert.equal(notification.payload.venueName, undefined);
  assert.equal(notification.payload.address, undefined);
  assert.equal(notification.payload.coordinates, undefined);
  assert.equal(notification.payload.amount, undefined);
  assert.equal(notification.payload.providerReference, undefined);
  assert.equal(notification.payload.privateReport, undefined);
  assert.match(notification.body, /payment.*failed/i);
  assert.doesNotMatch(notification.body, /Exact|50\.00|secret-provider/i);
});

test('includes payment details only for an authorized recipient', () => {
  const service = new NotificationService();
  const event = createDomainEvent<Record<string, unknown>>({
    id: 'event-payment-authorized',
    type: 'payment.failed',
    aggregateType: 'payment',
    aggregateId: 'payment-2',
    aggregateVersion: 1,
    payload: { matchLabel: 'Final', amount: '50.00', currency: 'EUR', providerReference: 'ref-2' },
    metadata: {},
  });

  const [notification] = service.deliverFromOutbox(event, [{
    userId: 'captain-1',
    eligibility: 'adult',
    canViewPaymentDetails: true,
  }]);

  assert.equal(notification.payload.amount, '50.00');
  assert.equal(notification.payload.currency, 'EUR');
  assert.equal(notification.payload.providerReference, 'ref-2');
});
