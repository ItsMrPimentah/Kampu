import { randomBytes, scrypt as scryptCallback } from 'node:crypto';
import { promisify } from 'node:util';
import { Client } from 'pg';
import { demoConnection } from './demo-guard';
import { evaluateEligibility } from '../src/modules/identity/eligibility';

export const demoEmail = 'captain@showtimedemo.invalid';
export const demoPassword = 'LocalDemo123!';
export const demoId = (kind: number, index: number) => `d3e00000-0000-4000-8000-${(kind * 10000 + index).toString().padStart(12, '0')}`;
const marker = demoId(99, 1);
const scrypt = promisify(scryptCallback);
const days = (now: Date, offset: number) => new Date(now.getTime() + offset * 86400000).toISOString();
export const demoEligibility = (now: Date) => evaluateEligibility('1994-06-15', now);

/** Validates the loopback target; operators must independently rule out port forwarding. */
export async function seedLocalDemo(env: NodeJS.ProcessEnv = process.env): Promise<'seeded' | 'already-seeded'> {
  const client = new Client(demoConnection(env));
  await client.connect();
  try {
    const identity = await client.query<{ db: string; local: boolean }>(
      "SELECT current_database() AS db, COALESCE(inet_server_addr() = '127.0.0.1'::inet OR inet_server_addr() = '::1'::inet, false) AS local",
    );
    if (identity.rows[0].db !== 'showtime_demo' || !identity.rows[0].local) {
      throw new Error('Connected server is not the dedicated loopback database');
    }
    await client.query('BEGIN');
    try {
      await client.query("SELECT pg_advisory_xact_lock(hashtext('showtime-local-demo-v1'))");
      // On first use, refuse public application data, even outside the fixture graph.
      // PostGIS owns and populates spatial_ref_sys during CREATE EXTENSION.
      // Lock tables while checking so a concurrent writer cannot race the check.
      const tables = await client.query<{ name: string }>(
        "SELECT quote_ident(n.nspname) || '.' || quote_ident(c.relname) AS name FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relkind IN ('r','p') AND NOT EXISTS (SELECT 1 FROM pg_depend d JOIN pg_extension e ON e.oid=d.refobjid WHERE d.classid='pg_class'::regclass AND d.objid=c.oid AND d.refclassid='pg_extension'::regclass AND d.deptype='e') ORDER BY c.relname",
      );
      if (!tables.rows.some(row => row.name === 'public.audit_logs')) throw new Error('Apply the API migrations to an empty demo database first');
      for (const table of tables.rows) await client.query(`LOCK TABLE ${table.name} IN SHARE ROW EXCLUSIVE MODE`);
      const existing = await client.query('SELECT action, target_type, metadata FROM public.audit_logs WHERE id=$1', [marker]);
      if (existing.rowCount) {
        const row = existing.rows[0];
        if (row.action !== 'local_demo.seeded.v1' || row.target_type !== 'local_demo' || row.metadata?.fixture !== 'showtime-local-demo-v1') {
          throw new Error('Demo marker collision');
        }
        await client.query('COMMIT');
        return 'already-seeded';
      }
      // Extension data may be prepopulated, but never adopt an application-named
      // fixture table claimed by an extension.
      const requiredTables = ['users', 'auth_credentials', 'player_profiles', 'teams', 'team_memberships', 'matches', 'match_proposals', 'match_participants', 'attendance', 'venues', 'bookings', 'consents', 'notifications', 'audit_logs', 'open_games', 'open_game_applications'];
      for (const name of requiredTables) {
        if (!tables.rows.some(row => row.name === `public.${name}`)) throw new Error(`Missing or extension-owned application table: ${name}`);
      }
      for (const table of tables.rows) {
        if ((await client.query(`SELECT 1 FROM ${table.name} LIMIT 1`)).rowCount) {
          throw new Error(`Demo database is not empty (${table.name}); refusing to adopt existing data`);
        }
      }
      await insertFixtures(client, new Date());
      await client.query("INSERT INTO public.audit_logs (id, action, target_type, reason, metadata) VALUES ($1,'local_demo.seeded.v1','local_demo','isolated local fixtures',$2)", [marker, JSON.stringify({ fixture: 'showtime-local-demo-v1' })]);
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

async function insertFixtures(c: Client, now: Date): Promise<void> {
  const names = [
    'Alex Costa', 'Rita Silva', 'João Santos', 'Inês Martins', 'Tiago Ferreira', 'Marta Lopes', 'Bruno Rocha',
    'Sara Pinto', 'Pedro Alves', 'Ana Ribeiro', 'Miguel Sousa', 'Carla Dias', 'Rui Gomes', 'Lara Cruz',
    'Diogo Neves', 'Sofia Melo', 'André Reis', 'Beatriz Maia', 'Nuno Lima', 'Eva Matos', 'Hugo Nunes',
  ];
  const positions = ['midfielder', 'goalkeeper', 'defender', 'defender', 'midfielder', 'forward', 'forward'];
  const eligibility = demoEligibility(now);
  const userCreated = days(now, -75);
  const profileCreated = days(now, -74);
  const teamCreated = days(now, -73);
  const membershipCreated = days(now, -72);
  for (let i = 0; i < names.length; i++) {
    const user = demoId(1, i + 1);
    await c.query('INSERT INTO public.users (id,external_auth_id,date_of_birth,eligibility,eligibility_policy_version,created_at,updated_at) VALUES ($1,$2,$3,$4,$5,$6,$6)', [user, `local-demo:user:${i + 1}`, eligibility.dateOfBirth, eligibility.category, eligibility.policyVersion, userCreated]);
    await c.query('INSERT INTO public.player_profiles (id,user_id,display_name,preferred_positions,skill_level,availability,approximate_location,created_at,updated_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$8)', [demoId(2, i + 1), user, names[i], JSON.stringify([positions[i % 7]]), 'intermediate', JSON.stringify({ weekends: true }), JSON.stringify({ region: 'Lisbon' }), profileCreated]);
  }
  const salt = randomBytes(16).toString('hex');
  const passwordHash = `${salt}:${((await scrypt(demoPassword, salt, 64)) as Buffer).toString('hex')}`;
  await c.query("INSERT INTO public.auth_credentials (user_id,email,phone,password_hash,phone_verified,registration_role) VALUES ($1,$2,'+15550100101',$3,true,'squadCaptain')", [demoId(1, 1), demoEmail, passwordHash]);
  await c.query("INSERT INTO public.consents (id,user_id,purpose,granted,policy_version) VALUES ($1,$2,'community_terms',true,'registration-v1')", [demoId(3, 1), demoId(1, 1)]);
  const teamNames = ['Demo Lisbon Falcons', 'Demo Riverside Athletic', 'Demo Bairro United'];
  for (let team = 0; team < 3; team++) {
    await c.query("INSERT INTO public.teams (id,name,region,description,visibility,supported_formats,created_at,updated_at) VALUES ($1,$2,'Lisbon','Synthetic local demo team','public',$3,$4,$4)", [demoId(4, team + 1), teamNames[team], JSON.stringify(['5v5', '7v7']), teamCreated]);
    for (let member = 0; member < 7; member++) {
      const index = team * 7 + member + 1;
      await c.query('INSERT INTO public.team_memberships (id,team_id,user_id,role,position,created_at,updated_at) VALUES ($1,$2,$3,$4,$5,$6,$6)', [demoId(5, index), demoId(4, team + 1), demoId(1, index), member === 0 ? 'captain' : 'member', positions[member], membershipCreated]);
    }
  }
  const fixtures = [
    { host: 1, opponent: 2, status: 'completed', offset: -35 },
    { host: 3, opponent: 1, status: 'completed', offset: -14 },
    { host: 1, opponent: 2, status: 'confirmed', offset: 7 },
    { host: 1, opponent: null, status: 'open', offset: 21 },
    { host: 3, opponent: null, status: 'open', offset: 28 },
    { host: 1, opponent: 3, status: 'negotiation', offset: 35 },
  ];
  for (let i = 0; i < fixtures.length; i++) {
    const f = fixtures[i]; const match = demoId(6, i + 1); const scheduled = days(now, f.offset);
    const field = 'Demo Riverside Pitch';
    const created = f.offset < 0 ? days(now, f.offset - 14) : now.toISOString();
    const updated = f.offset < 0 ? days(now, f.offset + 1) : now.toISOString();
    const version = f.status === 'negotiation' ? 2 : f.opponent ? 4 : 1;
    await c.query('INSERT INTO public.matches (id,host_team_id,opponent_team_id,format,status,skill_level,scheduled_at,region,field_name,field_status,version,created_at,updated_at) VALUES ($1,$2,$3,\'7v7\',$4,\'intermediate\',$5,\'Lisbon\',$6,$7,$8,$9,$10)', [match, demoId(4, f.host), f.opponent ? demoId(4, f.opponent) : null, f.status, scheduled, field, f.status === 'completed' ? 'confirmed' : 'in_confirmation', version, created, updated]);
    const accepted = f.status === 'completed' || f.status === 'confirmed';
    await c.query('INSERT INTO public.match_proposals (id,match_id,version,proposed_by_user_id,proposed_by_team_id,accepted_by_team_id,terms,decision,created_at,updated_at) VALUES ($1,$2,1,$3,$4,$5,$6,$7,$8,$8)', [demoId(7, i + 1), match, demoId(1, (f.host - 1) * 7 + 1), demoId(4, f.host), accepted && f.opponent ? demoId(4, f.opponent) : null, JSON.stringify({ scheduledAt: scheduled, region: 'Lisbon', field }), accepted ? 'accepted' : null, created]);
    if (f.opponent) {
      for (const team of [f.host, f.opponent]) {
        for (let member = 0; member < 7; member++) {
          const user = (team - 1) * 7 + member + 1;
          const item = (i + 1) * 100 + user;
          await c.query('INSERT INTO public.match_participants (id,match_id,user_id,team_id,position,created_at,updated_at) VALUES ($1,$2,$3,$4,$5,$6,$6)', [demoId(8, item), match, demoId(1, user), demoId(4, team), positions[member], created]);
          await c.query("INSERT INTO public.attendance (id,match_id,user_id,status,responded_at,created_at,updated_at) VALUES ($1,$2,$3,'confirmed',$4,$4,$4)", [demoId(9, item), match, demoId(1, user), created]);
        }
      }
    }
  }
  await c.query("INSERT INTO public.venues (id,name,region,address,supported_formats,booking_method,source,verification_level) VALUES ($1,'Demo Riverside Pitch','Lisbon','Synthetic local address',$2,'external','local_demo','unverified')", [demoId(10, 1), JSON.stringify(['5v5', '7v7'])]);
  await c.query("INSERT INTO public.bookings (id,match_id,venue_id,status,authority,requested_at) VALUES ($1,$2,$3,'externally_declared','user_declared',$4)", [demoId(11, 1), demoId(6, 3), demoId(10, 1), now]);
  for (let i = 1; i <= 2; i++) {
    await c.query("INSERT INTO public.open_games (id,organizer_id,title,format,region,location,scheduled_at,capacity,approval_required,visibility,required_positions) VALUES ($1,$2,$3,'5v5','Lisbon','Demo Riverside Pitch',$4,10,true,'public',$5)", [demoId(12, i), demoId(1, i === 1 ? 1 : 8), i === 1 ? 'Demo Friday Five' : 'Demo Sunday Kickabout', days(now, i * 10), JSON.stringify(['goalkeeper', 'forward'])]);
  }
  for (const [i, game, user, status] of [[1, 1, 2, 'approved'], [2, 1, 8, 'pending'], [3, 2, 1, 'approved']] as const) {
    await c.query('INSERT INTO public.open_game_applications (id,game_id,user_id,position,status) VALUES ($1,$2,$3,$4,$5)', [demoId(13, i), demoId(12, game), demoId(1, user), positions[(user - 1) % 7], status]);
  }
  await c.query("INSERT INTO public.notifications (id,user_id,type,payload) VALUES ($1,$2,'game.application',$3)", [demoId(14, 1), demoId(1, 1), JSON.stringify({ gameId: demoId(12, 1), status: 'pending' })]);
}
