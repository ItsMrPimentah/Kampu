import assert from 'node:assert/strict';
import test from 'node:test';
import { StripeWebhookService } from '../src/modules/payments/stripe-webhook.service';

test('verifies and deduplicates Stripe webhook events', async () => {
  const service = new StripeWebhookService();
  const event = { eventId: 'evt-1', intentId: 'pi-1', status: 'succeeded' as const, occurredAt: '2026-10-19T00:00:00Z' };
  assert.equal((await service.handle({ ...event, signature: service.sign(event) })).processed, true);
  assert.equal((await service.handle({ ...event, signature: service.sign(event) })).processed, false);
  assert.equal(service.records().length, 1);
});
