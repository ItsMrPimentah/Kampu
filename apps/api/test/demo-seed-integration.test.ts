import assert from 'node:assert/strict';
import test from 'node:test';
import { Client } from 'pg';
import { demoConnection } from '../scripts/demo-guard';
import { demoEmail, demoId, demoPassword, seedLocalDemo } from '../scripts/demo-seed';
import { AuthService } from '../src/modules/identity/auth.service';
import { CommunityService } from '../src/modules/community/community.service';
import { evaluateEligibility } from '../src/modules/identity/eligibility';

test('isolated demo seed, normal login, community visibility and insert-only rerun', async t => {
  if (process.env.RUN_LOCAL_DEMO_INTEGRATION !== 'yes') {
    t.skip('Set RUN_LOCAL_DEMO_INTEGRATION=yes with an empty migrated dedicated local demo database');
    return;
  }
  const config = demoConnection(process.env);
  assert.equal(await seedLocalDemo(), 'seeded', 'Integration test requires a fresh, empty database');
  const client = new Client(config);
  await client.connect();
  // Both services use DATABASE_URL; set it exclusively to the validated demo URL.
  process.env.DATABASE_URL = process.env.DEMO_DATABASE_URL;
  const auth = new AuthService();
  const community = new CommunityService(auth);
  try {
    const login = await auth.login(demoEmail, demoPassword);
    assert.equal(login.verified, true);
    const actor = await community.actor(`Bearer ${login.token}`);
    assert.equal(actor, demoId(1, 1));
    assert.equal((await client.query('SELECT email FROM auth_credentials WHERE user_id=$1', [actor])).rows[0].email, demoEmail);
    const user = (await client.query('SELECT date_of_birth::text, eligibility, eligibility_policy_version FROM users WHERE id=$1', [actor])).rows[0];
    const eligibility = evaluateEligibility(user.date_of_birth);
    assert.equal(user.eligibility, eligibility.category);
    assert.equal(user.eligibility_policy_version, eligibility.policyVersion);
    const allUsers = await client.query('SELECT date_of_birth::text, eligibility, eligibility_policy_version FROM users');
    assert.equal(allUsers.rows.length, 21);
    for (const row of allUsers.rows) {
      const expected = evaluateEligibility(row.date_of_birth);
      assert.equal(row.eligibility, expected.category);
      assert.equal(row.eligibility_policy_version, expected.policyVersion);
    }
    const roster = await community.roster(actor, demoId(4, 1));
    assert.equal(roster.myRole, 'captain');
    assert.equal(roster.members.length, 7);
    const challenges = await community.challenges(actor);
    assert.equal(challenges.filter(row => row.status === 'completed').length, 2);
    assert.ok(challenges.some(row => row.status === 'confirmed' && new Date(row.scheduled_at) > new Date()));
    assert.ok(challenges.some(row => row.status === 'open'));
    assert.equal((await community.challenge(actor, demoId(6, 3))).proposals[0].decision, 'accepted');
    assert.equal((await community.games(actor)).length, 2);
    assert.equal((await community.applications(actor, demoId(12, 1))).length, 2);
    assert.equal((await community.notifications(actor)).length, 1);
    const participants = await client.query('SELECT count(*)::int AS count FROM match_participants WHERE match_id=$1', [demoId(6, 3)]);
    assert.equal(participants.rows[0].count, 14);
    const chronology = await client.query(`SELECT count(*)::int AS total, count(*) FILTER (WHERE u.created_at > m.created_at OR pr.created_at > m.created_at
        OR team.created_at > m.created_at OR membership.created_at > m.created_at
        OR p.created_at < m.created_at OR m.created_at >= m.scheduled_at)::int AS invalid FROM match_participants p
      JOIN matches m ON m.id=p.match_id JOIN users u ON u.id=p.user_id
      JOIN player_profiles pr ON pr.user_id=p.user_id JOIN teams team ON team.id=p.team_id
      JOIN team_memberships membership ON membership.team_id=p.team_id AND membership.user_id=p.user_id
      WHERE m.status='completed'`);
    assert.equal(chronology.rows[0].total, 28);
    assert.equal(chronology.rows[0].invalid, 0);
    const before = await client.query('SELECT scheduled_at FROM matches WHERE id=$1', [demoId(6, 3)]);
    await client.query("UPDATE teams SET name='Edited demo team' WHERE id=$1", [demoId(4, 1)]);
    assert.equal(await seedLocalDemo(), 'already-seeded');
    assert.equal((await client.query('SELECT name FROM teams WHERE id=$1', [demoId(4, 1)])).rows[0].name, 'Edited demo team');
    assert.deepEqual((await client.query('SELECT scheduled_at FROM matches WHERE id=$1', [demoId(6, 3)])).rows, before.rows);
    assert.equal((await client.query('SELECT count(*)::int AS count FROM users')).rows[0].count, 21);
    assert.equal((await client.query('SELECT count(*)::int AS count FROM outbox_events')).rows[0].count, 0);
    assert.equal((await client.query('SELECT count(*)::int AS count FROM payment_orders')).rows[0].count, 0);
  } finally {
    await community.onModuleDestroy();
    await auth.onModuleDestroy();
    await client.end();
  }
});

test('fresh demo database refuses pre-existing natural-key conflicts without partial inserts', async t => {
  if (process.env.RUN_LOCAL_DEMO_COLLISION_TEST !== 'yes') {
    t.skip('Set RUN_LOCAL_DEMO_COLLISION_TEST=yes with a separate empty migrated demo database');
    return;
  }
  const client = new Client(demoConnection(process.env));
  await client.connect();
  try {
    const identity = await client.query("SELECT current_database() AS db, COALESCE(inet_server_addr() = '127.0.0.1'::inet OR inet_server_addr() = '::1'::inet, false) AS local");
    assert.equal(identity.rows[0].db, 'showtime_demo');
    assert.equal(identity.rows[0].local, true);
    await client.query('BEGIN');
    try {
      const tables = await client.query<{ name: string }>("SELECT quote_ident(n.nspname) || '.' || quote_ident(c.relname) AS name FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relkind IN ('r','p') AND NOT EXISTS (SELECT 1 FROM pg_depend d JOIN pg_extension e ON e.oid=d.refobjid WHERE d.classid='pg_class'::regclass AND d.objid=c.oid AND d.refclassid='pg_extension'::regclass AND d.deptype='e') ORDER BY c.relname");
      for (const table of tables.rows) await client.query(`LOCK TABLE ${table.name} IN SHARE ROW EXCLUSIVE MODE`);
      for (const table of tables.rows) assert.equal((await client.query(`SELECT 1 FROM ${table.name} LIMIT 1`)).rowCount, 0, `Nonempty: ${table.name}`);
      await client.query("INSERT INTO users (external_auth_id) VALUES ('local-demo:user:1')");
      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }
    await assert.rejects(() => seedLocalDemo(), /not empty/);
    assert.equal((await client.query('SELECT count(*)::int AS count FROM users')).rows[0].count, 1);
    assert.equal((await client.query('SELECT count(*)::int AS count FROM teams')).rows[0].count, 0);
    assert.equal((await client.query('SELECT count(*)::int AS count FROM audit_logs')).rows[0].count, 0);
  } finally {
    await client.end();
  }
});
