import assert from 'node:assert/strict';
import test from 'node:test';
import { AnalyticsService, type AnalyticsEventName } from '../src/modules/analytics/analytics.service';

const eventNames: AnalyticsEventName[] = [
  'challenge.published',
  'opponent.agreed',
  'schedule.agreed',
  'booking.declared',
  'booking.provider_confirmed',
  'payment.completed',
  'attendance.confirmed',
  'match.completed',
  'match.cancelled',
  'attendance.no_show',
];

test('records all match funnel events with source aggregate and version', () => {
  const service = new AnalyticsService();
  for (const [index, name] of eventNames.entries()) {
    const event = service.record(name, {
      aggregateType: 'match',
      aggregateId: 'match-1',
      aggregateVersion: index + 1,
    }, { format: '5v5' }, index % 2 === 0 ? 'youth' : 'adult');

    assert.equal(event.name, name);
    assert.equal(event.aggregateType, 'match');
    assert.equal(event.aggregateId, 'match-1');
    assert.equal(event.aggregateVersion, index + 1);
    assert.equal(event.payload.format, '5v5');
  }
  assert.equal(service.forAggregate('match', 'match-1').length, eventNames.length);
});

test('does not duplicate an analytics event when the same source version is replayed', () => {
  const service = new AnalyticsService();
  const source = { aggregateType: 'booking', aggregateId: 'booking-1', aggregateVersion: 3 };
  const first = service.record('booking.provider_confirmed', source, { provider: 'PlayArena' });
  const replay = service.record('booking.provider_confirmed', source, { provider: 'different-provider' });

  assert.equal(replay.id, first.id);
  assert.equal(replay.payload.provider, 'PlayArena');
  assert.equal(service.all().length, 1);
});

test('rejects invalid source versions', () => {
  const service = new AnalyticsService();
  assert.throws(() => service.record('match.completed', {
    aggregateType: 'match',
    aggregateId: 'match-1',
    aggregateVersion: 0,
  }));
});
