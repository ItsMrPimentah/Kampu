import assert from 'node:assert/strict';
import test from 'node:test';
import { StripeSandboxError, StripeSandboxService } from '../src/modules/payments/stripe-sandbox.service';

test('supports sandbox intent statuses and refunds', () => {
  const service = new StripeSandboxService();
  const intent = service.create(100, 'EUR', true);
  assert.equal(intent.provider, 'stripe_sandbox');
  service.transition(intent.id, 'processing');
  service.transition(intent.id, 'succeeded');
  assert.equal(service.refund(intent.id, 100).status, 'refunded');
});

test('does not create live or disabled payment intents', () => {
  const service = new StripeSandboxService();
  assert.throws(() => service.create(10, 'EUR', false), StripeSandboxError);
});
