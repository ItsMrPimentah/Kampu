import type { Pool, PoolClient } from 'pg';

const sensitiveKeys = new Set(['dateOfBirth', 'email', 'address', 'preciseLocation', 'phone', 'evidence']);

export interface AuditDecisionInput {
  actorId?: string;
  action: string;
  targetType: string;
  targetId?: string;
  reason?: string;
  policyVersion?: string;
  metadata?: Record<string, unknown>;
}

export function sanitizeAuditMetadata(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(sanitizeAuditMetadata);
  if (!value || typeof value !== 'object') return value;
  return Object.fromEntries(
    Object.entries(value as Record<string, unknown>)
      .filter(([key]) => !sensitiveKeys.has(key))
      .map(([key, nested]) => [key, sanitizeAuditMetadata(nested)]),
  );
}

export class AuditService {
  async recordAuthorizationDecision(client: PoolClient, input: AuditDecisionInput): Promise<void> {
    const metadata = sanitizeAuditMetadata({
      ...(input.metadata ?? {}),
      policyVersion: input.policyVersion ?? 'policy-v1',
    });
    await client.query(
      `INSERT INTO audit_logs (actor_id, action, target_type, target_id, reason, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [input.actorId ?? null, input.action, input.targetType, input.targetId ?? null, input.reason ?? null, metadata],
    );
  }

  async recordWithPool(pool: Pool, input: AuditDecisionInput): Promise<void> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await this.recordAuthorizationDecision(client, input);
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}
