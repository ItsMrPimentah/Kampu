import assert from 'node:assert/strict';
import test from 'node:test';
import { demoApiHost, demoConnection } from '../scripts/demo-guard';
import { demoEligibility, demoEmail } from '../scripts/demo-seed';
import { evaluateEligibility } from '../src/modules/identity/eligibility';

const safe = { NODE_ENV: 'test', SEED_LOCAL_DEMO: 'yes', DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@127.0.0.1:55432/showtime_demo' };

test('demo account uses the documented login email', () => {
  assert.equal(demoEmail, 'captain@showtimedemo.invalid');
});

test('demo seed requires explicit environment, opt-in and dedicated loopback credentials', () => {
  assert.equal(demoConnection(safe).host, '127.0.0.1');
  assert.equal(demoConnection({ ...safe, DEMO_DATABASE_URL: 'postgresql://showtime_demo:showtime_demo@[::1]:5432/showtime_demo' }).host, '::1');
  for (const overrides of [
    { NODE_ENV: undefined }, { NODE_ENV: 'production' }, { NODE_ENV: 'staging' },
    { SEED_LOCAL_DEMO: undefined }, { SEED_LOCAL_DEMO: 'true' }, { DEMO_DATABASE_URL: undefined },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@localhost:5432/showtime_demo' },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@127.1:5432/showtime_demo' },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@127.0.0.2:5432/showtime_demo' },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@192.168.1.1:5432/showtime_demo' },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@127.0.0.1:5432/showtime' },
    { DEMO_DATABASE_URL: 'postgres://admin:secret@127.0.0.1:5432/showtime_demo' },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@127.0.0.1:5432/showtime_demo?host=remote' },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@127.0.0.1:5432/showtime_demo#fragment' },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@127.0.0.1:5432/showtime_demo\n' },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@%2Ftmp:5432/showtime_demo' },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@127.0.0.1/showtime_demo' },
    { DEMO_DATABASE_URL: 'postgres://showtime_demo:showtime_demo@127.0.0.1:99999/showtime_demo' },
    { PGHOST: 'remote' }, { PGOPTIONS: '-c search_path=evil' },
  ]) assert.throws(() => demoConnection({ ...safe, ...overrides }));
});

test('demo API requires the exact guarded database URL and uses loopback only', () => {
  assert.throws(() => demoApiHost(safe), /DATABASE_URL/);
  assert.throws(() => demoApiHost({ ...safe, DATABASE_URL: 'postgres://remote/db' }), /DATABASE_URL/);
  assert.throws(() => demoApiHost({ ...safe, NODE_ENV: 'production', DATABASE_URL: safe.DEMO_DATABASE_URL }));
  assert.equal(demoApiHost({ ...safe, DATABASE_URL: safe.DEMO_DATABASE_URL }), '127.0.0.1');
});

test('demo eligibility uses the current registration policy', () => {
  const now = new Date('2026-11-14T12:00:00Z');
  const decision = demoEligibility(now);
  assert.deepEqual(decision, evaluateEligibility('1994-06-15', now));
  assert.equal(decision.category, 'adult');
  assert.equal(decision.policyVersion, 'age-13-v1');
});
