import assert from 'node:assert/strict';
import test from 'node:test';
import { AnalyticsService, type AnalyticsEventName } from '../src/modules/analytics/analytics.service';
import { OperatorMetricsService } from '../src/modules/analytics/operator-metrics.service';

const record = (analytics: AnalyticsService, name: AnalyticsEventName, version: number, eligibilityCategory: 'adult' | 'youth') => {
  analytics.record(name, {
    aggregateType: 'match',
    aggregateId: `${name}-${eligibilityCategory}`,
    aggregateVersion: version,
  }, {}, eligibilityCategory);
};

test('distinguishes funnel, reliability, dispute, refund, and no-show metrics', () => {
  const analytics = new AnalyticsService();
  const metrics = new OperatorMetricsService(analytics);
  const names: AnalyticsEventName[] = [
    'challenge.published',
    'opponent.agreed',
    'booking.provider_confirmed',
    'payment.completed',
    'attendance.confirmed',
    'match.completed',
    'match.cancelled',
    'booking.failed',
    'payment.failed',
    'payment.refunded',
    'dispute.opened',
    'contribution.captain_reported',
    'attendance.no_show',
  ];
  names.forEach((name, index) => record(analytics, name, index + 1, 'adult'));

  assert.deepEqual(metrics.summarize({ analyticsConsentGranted: true, includeYouthAggregate: false }), {
    consentRequired: false,
    published: 1,
    agreed: 1,
    booked: 1,
    funded: 1,
    attended: 1,
    completed: 1,
    cancellations: 1,
    bookingFailures: 1,
    paymentFailures: 1,
    refunds: 1,
    disputes: 1,
    captainReportedContributions: 1,
    noShows: 1,
  });
});

test('gates optional analytics when consent is absent and filters youth aggregates', () => {
  const analytics = new AnalyticsService();
  const metrics = new OperatorMetricsService(analytics);
  record(analytics, 'challenge.published', 1, 'adult');
  record(analytics, 'challenge.published', 2, 'youth');

  assert.equal(metrics.summarize({ analyticsConsentGranted: false, includeYouthAggregate: true }).published, 0);
  assert.equal(metrics.summarize({ analyticsConsentGranted: false, includeYouthAggregate: true }).consentRequired, true);
  assert.equal(metrics.summarize({ analyticsConsentGranted: true, includeYouthAggregate: false }).published, 1);
  assert.equal(metrics.summarize({ analyticsConsentGranted: true, includeYouthAggregate: true }).published, 2);
});

test('returns aggregate counters without individual youth data', () => {
  const analytics = new AnalyticsService();
  const metrics = new OperatorMetricsService(analytics);
  record(analytics, 'match.completed', 1, 'youth');

  const result = metrics.summarize({ analyticsConsentGranted: true, includeYouthAggregate: true });
  assert.equal(result.completed, 1);
  assert.equal('aggregateId' in result, false);
  assert.equal('userId' in result, false);
});
