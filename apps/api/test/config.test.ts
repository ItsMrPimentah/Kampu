import assert from 'node:assert/strict';
import test from 'node:test';
import { ConfigurationError, loadConfig } from '../src/config/env';
import { createDomainEvent } from '../src/shared/domain-events';
import { FeatureFlags } from '../src/shared/feature-flags';

const validEnv = (): NodeJS.ProcessEnv => ({
  NODE_ENV: 'test',
  PORT: '3000',
  DATABASE_URL: 'postgres://showtime:showtime@localhost:5432/showtime',
  REDIS_URL: 'redis://localhost:6379',
  MINIO_ENDPOINT: 'localhost',
  MINIO_PORT: '9000',
  MINIO_USE_SSL: 'false',
  MINIO_ACCESS_KEY: 'showtime',
  MINIO_SECRET_KEY: 'showtime-secret',
  MINIO_BUCKET: 'showtime',
  BETTER_AUTH_SECRET: 'a-local-test-secret',
  STRIPE_MODE: 'test',
  STRIPE_SECRET_KEY: 'sk_test_local',
  FEATURE_NATIVE_BOOKING: 'true',
  FEATURE_PAYMENTS: 'false',
  FEATURE_ADVERTISING: 'false',
});

test('rejects missing required configuration', () => {
  const env = validEnv();
  delete env.DATABASE_URL;
  assert.throws(() => loadConfig(env), ConfigurationError);
});

test('rejects live Stripe mode outside production', () => {
  const env = validEnv();
  env.STRIPE_MODE = 'live';
  env.STRIPE_SECRET_KEY = 'sk_live_local';
  assert.throws(() => loadConfig(env), /only allowed in production/);
});

test('parses feature flags and pilot configuration', () => {
  const config = loadConfig({ ...validEnv(), PILOT_REGIONS: 'Lisbon, Setúbal' });
  const flags = new FeatureFlags(config);
  assert.equal(flags.enabled('nativeBooking'), true);
  assert.equal(flags.enabled('payments'), false);
  assert.deepEqual(config.pilotRegions, ['Lisbon', 'Setúbal']);
});

test('creates a versioned domain event envelope', () => {
  const event = createDomainEvent({
    id: 'event-1',
    type: 'match.completed',
    aggregateType: 'match',
    aggregateId: 'match-1',
    aggregateVersion: 1,
    payload: { matchId: 'match-1' },
    metadata: { actorId: 'captain-1' },
  });
  assert.equal(event.type, 'match.completed');
  assert.match(event.occurredAt, /^20/);
});
