import { randomBytes, scrypt as scryptCallback } from 'node:crypto';
import { promisify } from 'node:util';
import { Client } from 'pg';
import { evaluateEligibility } from '../src/modules/identity/eligibility';
import { demoEmail, demoPassword } from './demo-seed';

const scrypt = promisify(scryptCallback);
const externalId = 'local-dev:demo-captain:v1';
const phone = '+15550100101';

// Match the Compose database explicitly; URL parameters and libpq overrides can
// otherwise redirect a supposedly local connection to an unintended server.
export function devDatabaseUrl(env: NodeJS.ProcessEnv): string {
  if ((env.NODE_ENV ?? 'development') !== 'development') throw new Error('Development seed requires NODE_ENV=development');
  if (Object.keys(env).some(key => key.startsWith('PG'))) throw new Error('Unset PG* environment variables before starting the development API');
  const url = env.DATABASE_URL ?? '';
  const match = /^postgres(?:ql)?:\/\/showtime:showtime@(?:localhost|127\.0\.0\.1|\[::1\]):5432\/showtime$/.exec(url);
  if (!match || match[0] !== url) {
    throw new Error('Development seed requires the local Compose DATABASE_URL postgres://showtime:showtime@localhost:5432/showtime');
  }
  return url;
}

export async function seedDevAccount(env: NodeJS.ProcessEnv = process.env): Promise<'seeded' | 'already-seeded'> {
  const client = new Client({ connectionString: devDatabaseUrl(env), connectionTimeoutMillis: 3000 });
  await client.connect();
  try {
    await client.query('BEGIN');
    try {
      await client.query("SELECT pg_advisory_xact_lock(hashtext('showtime-dev-demo-account-v1'))");
      const existing = await client.query<{ external_auth_id: string; email: string; phone: string }>(
        `SELECT u.external_auth_id, c.email, c.phone FROM users u
         LEFT JOIN auth_credentials c ON c.user_id = u.id
         WHERE u.external_auth_id = $1 OR c.email = $2 OR c.phone = $3`,
        [externalId, demoEmail, phone],
      );
      if (existing.rowCount) {
        if (existing.rowCount !== 1 || existing.rows[0].external_auth_id !== externalId || existing.rows[0].email !== demoEmail || existing.rows[0].phone !== phone) {
          throw new Error('Demo account conflicts with existing data; resolve the collision before starting the development API');
        }
        await client.query('COMMIT');
        return 'already-seeded';
      }
      const eligibility = evaluateEligibility('1994-06-15');
      const user = await client.query<{ id: string }>(
        'INSERT INTO users (external_auth_id, date_of_birth, eligibility, eligibility_policy_version) VALUES ($1, $2, $3, $4) RETURNING id',
        [externalId, eligibility.dateOfBirth, eligibility.category, eligibility.policyVersion],
      );
      const id = user.rows[0].id;
      const salt = randomBytes(16).toString('hex');
      const hash = (await scrypt(demoPassword, salt, 64)) as Buffer;
      await client.query("INSERT INTO player_profiles (user_id, display_name) VALUES ($1, 'Demo Captain')", [id]);
      await client.query("INSERT INTO auth_credentials (user_id, email, phone, password_hash, phone_verified, registration_role) VALUES ($1, $2, $3, $4, true, 'squadCaptain')", [id, demoEmail, phone, `${salt}:${hash.toString('hex')}`]);
      await client.query("INSERT INTO consents (user_id, purpose, granted, policy_version) VALUES ($1, 'community_terms', true, 'registration-v1')", [id]);
      await client.query('COMMIT');
      return 'seeded';
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }
  } finally {
    await client.end();
  }
}
