import assert from 'node:assert/strict';
import test from 'node:test';
import { randomUUID } from 'node:crypto';
import { Pool } from 'pg';
import { createDomainEvent } from '../src/shared/domain-events';
import { IdempotencyConflictError, runAtomically, useIdempotencyKey, withTransaction } from '../src/db/transactional-events';

const pool = new Pool({ connectionString: process.env.DATABASE_URL ?? 'postgres://showtime:showtime@localhost:5432/showtime' });

test('commits work and its outbox event atomically', async (t) => {
  try {
    await pool.query('SELECT 1');
  } catch {
    t.skip('PostgreSQL is not available');
    return;
  }

  const aggregateId = randomUUID();
  const eventId = randomUUID();
  const event = createDomainEvent({
    id: eventId,
    type: 'test.atomicity',
    aggregateType: 'test',
    aggregateId,
    aggregateVersion: 1,
    payload: { aggregateId },
    metadata: {},
  });

  await runAtomically(pool, event, async (client) => {
    await client.query('SELECT $1::text', ['domain-work']);
    return 'committed';
  });
  const committed = await pool.query('SELECT id FROM outbox_events WHERE id = $1', [eventId]);
  assert.equal(committed.rowCount, 1);

  const rollbackEvent = createDomainEvent({ ...event, id: randomUUID(), aggregateVersion: 2 });
  await assert.rejects(
    runAtomically(pool, rollbackEvent, async () => {
      throw new Error('force rollback');
    }),
    /force rollback/,
  );
  const rolledBack = await pool.query('SELECT id FROM outbox_events WHERE id = $1', [rollbackEvent.id]);
  assert.equal(rolledBack.rowCount, 0);

  await pool.query('DELETE FROM outbox_events WHERE id IN ($1, $2)', [eventId, rollbackEvent.id]);
});

test('replays an idempotent response and rejects hash reuse', async (t) => {
  try {
    await pool.query('SELECT 1');
  } catch {
    t.skip('PostgreSQL is not available');
    return;
  }

  const scope = `test-${randomUUID()}`;
  const key = 'request-1';
  const first = await withTransaction(pool, (client) => useIdempotencyKey(client, scope, key, 'hash-a', { ok: true }));
  const replay = await withTransaction(pool, (client) => useIdempotencyKey(client, scope, key, 'hash-a', { ok: false }));
  assert.equal(first.replayed, false);
  assert.deepEqual(replay, { replayed: true, response: { ok: true } });
  await assert.rejects(
    withTransaction(pool, (client) => useIdempotencyKey(client, scope, key, 'hash-b', { ok: false })),
    IdempotencyConflictError,
  );
  await pool.query('DELETE FROM idempotency_keys WHERE scope = $1 AND key = $2', [scope, key]);
});

test.after(async () => {
  await pool.end();
});
