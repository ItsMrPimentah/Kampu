import { BadRequestException, ConflictException, HttpException, Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { createHash, randomBytes, scrypt as scryptCallback, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';
import { Pool } from 'pg';
import { EligibilityError, evaluateEligibility } from './eligibility';
import { TwilioVerify, type PhoneVerifier } from './twilio-verify';

const scrypt = promisify(scryptCallback);
const digest = (token: string) => createHash('sha256').update(token).digest('hex');
const invalidCredentials = () => new UnauthorizedException('Invalid credentials');
const passwordPolicy = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,128}$/;

export interface AuthRegistration {
  name: string; email: string; phone: string; password: string; dateOfBirth: string; role: string; acceptedTerms: boolean;
}

interface AuthRow {
  user_id: string; email: string; phone: string; password_hash: string; phone_verified: boolean;
  date_of_birth: string; display_name: string; eligibility: 'youth' | 'adult';
}

@Injectable()
export class AuthService {
  private readonly pool: Pool;
  private readonly verifier: PhoneVerifier;
  constructor() {
    this.pool = new Pool({ connectionString: process.env.DATABASE_URL });
    this.verifier = new TwilioVerify(process.env.TWILIO_ACCOUNT_SID ?? '', process.env.TWILIO_AUTH_TOKEN ?? '', process.env.TWILIO_VERIFY_SERVICE_SID ?? '');
  }

  async rateLimit(key: string, limit: number, seconds: number): Promise<void> {
    const hashedKey = digest(key);
    const result = await this.pool.query<{ count: number }>(
      `INSERT INTO auth_rate_limits (key, count, expires_at) VALUES ($1, 1, now() + $2 * interval '1 second')
       ON CONFLICT (key) DO UPDATE SET count = CASE WHEN auth_rate_limits.expires_at <= now() THEN 1 ELSE auth_rate_limits.count + 1 END,
       expires_at = CASE WHEN auth_rate_limits.expires_at <= now() THEN now() + $2 * interval '1 second' ELSE auth_rate_limits.expires_at END RETURNING count`,
      [hashedKey, seconds],
    );
    if (result.rows[0].count > limit) throw new HttpException('Too many requests. Please try again later.', 429);
  }

  async register(input: AuthRegistration): Promise<{ token: string; verified: false; phone: string; sent: boolean }> {
    if (!input || typeof input.name !== 'string' || typeof input.email !== 'string' || typeof input.phone !== 'string' || typeof input.password !== 'string' || typeof input.dateOfBirth !== 'string' || typeof input.role !== 'string') throw new BadRequestException('Invalid registration details');
    const name = input.name.trim();
    const email = input.email.trim().toLowerCase();
    const phone = input.phone.replace(/[\s()-]/g, '');
    if (name.length < 2 || name.length > 120 || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 254 || !/^\+[1-9]\d{7,14}$/.test(phone) || !passwordPolicy.test(input.password) || input.acceptedTerms !== true || !['player', 'squadCaptain', 'guardian'].includes(input.role)) throw new BadRequestException('Invalid registration details');
    let eligibility;
    try { eligibility = evaluateEligibility(input.dateOfBirth); } catch (error) {
      if (error instanceof EligibilityError) throw new BadRequestException(error.message);
      throw error;
    }
    await this.rateLimit(`send:${phone}`, 3, 3600);
    const salt = randomBytes(16).toString('hex');
    const hash = (await scrypt(input.password, salt, 64)) as Buffer;
    const passwordHash = `${salt}:${hash.toString('hex')}`;
    const client = await this.pool.connect();
    let userId: string;
    let token: string;
    try {
      await client.query('BEGIN');
      const user = await client.query<{ id: string }>(
        `INSERT INTO users (external_auth_id, date_of_birth, eligibility, eligibility_policy_version)
         VALUES ($1, $2, $3, $4) RETURNING id`,
        [`local:${randomBytes(16).toString('hex')}`, eligibility.dateOfBirth, eligibility.category, eligibility.policyVersion],
      );
      userId = user.rows[0].id;
      await client.query('INSERT INTO player_profiles (user_id, display_name) VALUES ($1, $2)', [userId, name]);
      await client.query('INSERT INTO auth_credentials (user_id, email, phone, password_hash, registration_role) VALUES ($1, $2, $3, $4, $5)', [userId, email, phone, passwordHash, input.role]);
      await client.query('INSERT INTO consents (user_id, purpose, granted, policy_version) VALUES ($1, $2, true, $3)', [userId, 'community_terms', 'registration-v1']);
      token = randomBytes(32).toString('base64url');
      await client.query("INSERT INTO auth_sessions (token_hash, user_id, expires_at) VALUES ($1, $2, now() + interval '30 days')", [digest(token), userId]);
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      if ((error as { code?: string }).code === '23505') throw new ConflictException('An account already exists. Sign in to continue.');
      throw error;
    } finally { client.release(); }
    let sent = true;
    try { await this.verifier.send(phone); } catch { sent = false; }
    return { token, verified: false, phone, sent };
  }

  async login(identifier: string, password: string): Promise<{ token: string; verified: boolean; phone: string }> {
    if (typeof identifier !== 'string' || typeof password !== 'string' || password.length > 128) throw invalidCredentials();
    const normalized = identifier.trim().toLowerCase().replace(/[\s()-]/g, '');
    await this.rateLimit(`login:${normalized}`, 10, 900);
    const result = await this.pool.query<AuthRow>('SELECT * FROM auth_credentials WHERE email = $1 OR phone = $1', [normalized]);
    const row = result.rows[0];
    const [salt, stored] = (row?.password_hash ?? '00000000000000000000000000000000:' + '00'.repeat(64)).split(':');
    const actual = (await scrypt(password, salt, 64)) as Buffer;
    const expected = Buffer.from(stored, 'hex');
    if (!row || expected.length !== actual.length || !timingSafeEqual(actual, expected)) throw invalidCredentials();
    return { token: await this.createSession(row.user_id), verified: row.phone_verified, phone: row.phone };
  }

  async resend(token: string): Promise<void> {
    const row = await this.session(token, false);
    if (row.phone_verified) throw new BadRequestException('Phone already verified');
    await this.rateLimit(`send:${row.phone}`, 3, 3600);
    try { await this.verifier.send(row.phone); } catch { throw new ServiceUnavailableException('Unable to send SMS. Please try again.'); }
  }

  async verify(token: string, code: string): Promise<AuthRow> {
    const row = await this.session(token, false);
    if (row.phone_verified) return row;
    if (typeof code !== 'string' || !/^\d{6}$/.test(code)) throw new BadRequestException('Enter the six-digit code');
    await this.rateLimit(`verify:${row.phone}`, 10, 900);
    let approved: boolean;
    try { approved = await this.verifier.check(row.phone, code); } catch { throw new BadRequestException('Code invalid or expired. Request a new code.'); }
    if (!approved) throw new BadRequestException('Code invalid or expired.');
    await this.pool.query('UPDATE auth_credentials SET phone_verified = true WHERE user_id = $1', [row.user_id]);
    return { ...row, phone_verified: true };
  }

  async session(token: string, requireVerified = true): Promise<AuthRow> {
    if (!token || token.length > 128) throw invalidCredentials();
    const result = await this.pool.query<AuthRow>(
      `SELECT c.*, u.date_of_birth::text, u.eligibility, p.display_name FROM auth_sessions s
       JOIN auth_credentials c ON c.user_id = s.user_id JOIN users u ON u.id = c.user_id
       JOIN player_profiles p ON p.user_id = u.id WHERE s.token_hash = $1 AND s.expires_at > now()`, [digest(token)],
    );
    const row = result.rows[0];
    if (!row || (requireVerified && !row.phone_verified)) throw invalidCredentials();
    return row;
  }

  async logout(token: string): Promise<void> { await this.pool.query('DELETE FROM auth_sessions WHERE token_hash = $1', [digest(token)]); }

  async onModuleDestroy(): Promise<void> { await this.pool.end(); }

  private async createSession(userId: string): Promise<string> {
    const token = randomBytes(32).toString('base64url');
    await this.pool.query("INSERT INTO auth_sessions (token_hash, user_id, expires_at) VALUES ($1, $2, now() + interval '30 days')", [digest(token), userId]);
    return token;
  }
}
