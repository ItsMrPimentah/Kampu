import type { Pool, PoolClient, QueryResultRow } from 'pg';
import type { DomainEvent } from '../shared/domain-events';

export class IdempotencyConflictError extends Error {
  constructor(scope: string, key: string) {
    super(`Idempotency key ${scope}:${key} was already used with a different request`);
    this.name = 'IdempotencyConflictError';
  }
}

export interface IdempotencyResult<T> {
  replayed: boolean;
  response?: T;
}

async function query<T extends QueryResultRow>(client: PoolClient, text: string, values: unknown[] = []): Promise<T[]> {
  const result = await client.query<T>(text, values);
  return result.rows;
}

export async function withTransaction<T>(pool: Pool, work: (client: PoolClient) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await work(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function appendOutboxEvent(client: PoolClient, event: DomainEvent<Record<string, unknown>>): Promise<void> {
  await client.query(
    `INSERT INTO outbox_events
      (id, event_type, aggregate_type, aggregate_id, aggregate_version, payload)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (aggregate_type, aggregate_id, aggregate_version) DO NOTHING`,
    [event.id, event.type, event.aggregateType, event.aggregateId, event.aggregateVersion, event.payload],
  );
}

export async function useIdempotencyKey<T>(
  client: PoolClient,
  scope: string,
  key: string,
  requestHash: string,
  response: T,
): Promise<IdempotencyResult<T>> {
  const existing = await query<{ request_hash: string; response: T | null }>(
    client,
    'SELECT request_hash, response FROM idempotency_keys WHERE scope = $1 AND key = $2 FOR UPDATE',
    [scope, key],
  );

  if (existing[0]) {
    if (existing[0].request_hash !== requestHash) throw new IdempotencyConflictError(scope, key);
    return { replayed: true, response: existing[0].response ?? undefined };
  }

  await client.query(
    `INSERT INTO idempotency_keys (scope, key, request_hash, response, completed_at)
     VALUES ($1, $2, $3, $4, now())`,
    [scope, key, requestHash, response],
  );
  return { replayed: false, response };
}

export async function runAtomically<T>(
  pool: Pool,
  event: DomainEvent<Record<string, unknown>>,
  work: (client: PoolClient) => Promise<T>,
): Promise<T> {
  return withTransaction(pool, async (client) => {
    const result = await work(client);
    await appendOutboxEvent(client, event);
    return result;
  });
}
