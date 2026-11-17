import assert from 'node:assert/strict';
import test from 'node:test';
import { randomUUID } from 'node:crypto';
import { Pool } from 'pg';
import { AuditService, sanitizeAuditMetadata } from '../src/modules/audit/audit.service';

test('sanitizes sensitive audit metadata recursively', () => {
  assert.deepEqual(
    sanitizeAuditMetadata({ policyVersion: 'age-16-v1', dateOfBirth: '2010-01-01', nested: { address: 'private', reason: 'policy' } }),
    { policyVersion: 'age-16-v1', nested: { reason: 'policy' } },
  );
});

test('persists an authorization decision with minimal metadata', async (t) => {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL ?? 'postgres://showtime:showtime@localhost:5432/showtime' });
  try {
    await pool.query('SELECT 1');
  } catch {
    await pool.end();
    t.skip('PostgreSQL is not available');
    return;
  }

  const service = new AuditService();
  const action = `test.authorization.${randomUUID()}`;
  await service.recordWithPool(pool, {
    action,
    targetType: 'user',
    reason: 'eligibility established',
    policyVersion: 'age-16-v1',
    metadata: { dateOfBirth: '2010-01-01', category: 'youth' },
  });
  const result = await pool.query('SELECT reason, metadata FROM audit_logs WHERE action = $1', [action]);
  assert.equal(result.rowCount, 1);
  assert.equal(result.rows[0].metadata.dateOfBirth, undefined);
  assert.equal(result.rows[0].metadata.policyVersion, 'age-16-v1');
  await pool.query('DELETE FROM audit_logs WHERE action = $1', [action]);
  await pool.end();
});
