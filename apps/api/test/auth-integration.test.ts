import assert from 'node:assert/strict';
import test from 'node:test';
import { randomUUID } from 'node:crypto';
import { Pool } from 'pg';
import { AuthService } from '../src/modules/identity/auth.service';

test('persists registration and requires SMS verification before protected session access', async (t) => {
  const url = process.env.DATABASE_URL ?? 'postgres://showtime:showtime@localhost:5432/showtime';
  const pool = new Pool({ connectionString: url });
  try { await pool.query('SELECT 1'); } catch { await pool.end(); t.skip('PostgreSQL is not available'); return; }
  process.env.DATABASE_URL = url;
  const service = new AuthService();
  Object.defineProperty(service, 'verifier', { value: {
    send: async () => {},
    check: async (_phone: string, code: string) => code === '123456',
  } });
  const suffix = randomUUID().replace(/\D/g, '').padEnd(10, '1').slice(0, 10);
  const email = `auth-${randomUUID()}@example.com`;
  const phone = `+351${suffix}`;
  let userId: string | undefined;
  try {
    const registration = await service.register({ name: 'Test Player', email, phone, password: 'StrongPass123!', dateOfBirth: '2000-01-01', role: 'player', acceptedTerms: true });
    assert.equal(registration.sent, true);
    const pending = await service.session(registration.token, false);
    userId = pending.user_id;
    assert.equal(pending.phone_verified, false);
    await assert.rejects(() => service.session(registration.token));
    await assert.rejects(() => service.verify(registration.token, '000000'));
    assert.equal((await service.session(registration.token, false)).phone_verified, false);
    await service.verify(registration.token, '123456');
    assert.equal((await service.session(registration.token)).phone_verified, true);
    await assert.rejects(() => service.login(email, 'incorrect'));
    const login = await service.login(phone, 'StrongPass123!');
    assert.equal(login.verified, true);
    await service.logout(login.token);
    await assert.rejects(() => service.session(login.token));
  } finally {
    if (userId) {
      await pool.query('DELETE FROM consents WHERE user_id = $1', [userId]);
      await pool.query('DELETE FROM player_profiles WHERE user_id = $1', [userId]);
      await pool.query('DELETE FROM users WHERE id = $1', [userId]);
    }
    await service.onModuleDestroy();
    await pool.end();
  }
});
