import assert from 'node:assert/strict';
import test from 'node:test';
import { randomUUID } from 'node:crypto';
import { Pool } from 'pg';
import { CommunityService } from '../src/modules/community/community.service';
import { AuthService } from '../src/modules/identity/auth.service';

test('community workflows persist and serialize last-slot and field-vote decisions', async t => {
  const url = process.env.DATABASE_URL ?? 'postgres://showtime:showtime@localhost:5432/showtime';
  const pool = new Pool({ connectionString: url });
  try { await pool.query('SELECT 1'); } catch { await pool.end(); t.skip('PostgreSQL is not available'); return; }
  process.env.DATABASE_URL = url;
  const auth = new AuthService();
  const service = new CommunityService(auth);
  const users: string[] = []; const teamIds: string[] = []; const gameIds: string[] = []; const matchIds: string[] = [];
  try {
    for (let i=0;i<5;i++) {
      const user = (await pool.query("INSERT INTO users (external_auth_id,eligibility) VALUES ($1,'adult') RETURNING id",[`community-test:${randomUUID()}`])).rows[0].id;
      users.push(user); await pool.query('INSERT INTO player_profiles (user_id,display_name) VALUES ($1,$2)',[user,`Player ${i}`]);
    }
    const [captainA,captainB,playerA,playerB,outsider]=users;
    const first=await service.createTeam(captainA,{name:'First',region:'Lisbon',formats:['7v7']}); teamIds.push(first.id);
    const second=await service.createTeam(captainB,{name:'Second',region:'Lisbon',formats:['7v7']}); teamIds.push(second.id);
    await assert.rejects(() => service.member(outsider,first.id,captainA,{role:'member'}));
    const kickoff=new Date(Date.now()+7*86400000).toISOString();
    const match=await service.createChallenge(captainA,{teamId:first.id,format:'7v7',scheduledAt:kickoff,region:'Lisbon',field:'Pitch A'}); matchIds.push(match.id);
    await service.challengeAction(captainB,match.id,'join',{teamId:second.id});
    await assert.rejects(() => service.challengeAction(captainA,match.id,'accept',{teamId:first.id}));
    await service.challengeAction(captainB,match.id,'accept',{teamId:second.id});
    await service.challengeAction(captainA,match.id,'confirm',{teamId:first.id});
    await service.challengeAction(captainA,match.id,'field-proposal',{teamId:first.id,field:'Pitch B'});
    await assert.rejects(() => service.challengeAction(captainA,match.id,'field-approve',{teamId:first.id}));
    const updated=await service.challengeAction(captainB,match.id,'field-approve',{teamId:second.id});
    assert.equal(updated.field_name,'Pitch B'); assert.equal(updated.field_status,'in_confirmation');

    const game=await service.createGame(captainA,{title:'Test game',format:'5v5',region:'Lisbon',location:'Pitch',scheduledAt:kickoff,capacity:1,approvalRequired:false}); gameIds.push(game.id);
    const applications=await Promise.all([service.applyGame(playerA,game.id),service.applyGame(playerB,game.id)]);
    assert.deepEqual(applications.map(a=>a.status).sort(),['approved','waitlisted']);
    const approved=applications.find(a=>a.status==='approved')!; const waiting=applications.find(a=>a.status==='waitlisted')!;
    await service.removeGamePlayer(captainA,game.id,approved.id);
    assert.equal((await service.applications(captainA,game.id)).find(a=>a.id===waiting.id).status,'waitlisted');
    await assert.rejects(() => service.decideGame(outsider,game.id,waiting.id,true));
    assert.equal((await service.decideGame(captainA,game.id,waiting.id,true)).status,'approved');
  } finally {
    await pool.query('DELETE FROM notifications WHERE user_id = ANY($1::uuid[])',[users]);
    await pool.query('DELETE FROM open_game_applications WHERE game_id = ANY($1::uuid[])',[gameIds]);
    await pool.query('DELETE FROM open_games WHERE id = ANY($1::uuid[])',[gameIds]);
    await pool.query('DELETE FROM challenge_field_votes WHERE match_id = ANY($1::uuid[])',[matchIds]);
    await pool.query('DELETE FROM match_proposals WHERE match_id = ANY($1::uuid[])',[matchIds]);
    await pool.query('DELETE FROM matches WHERE id = ANY($1::uuid[])',[matchIds]);
    await pool.query('DELETE FROM team_memberships WHERE team_id = ANY($1::uuid[])',[teamIds]);
    await pool.query('DELETE FROM teams WHERE id = ANY($1::uuid[])',[teamIds]);
    await pool.query('DELETE FROM player_profiles WHERE user_id = ANY($1::uuid[])',[users]);
    await pool.query('DELETE FROM users WHERE id = ANY($1::uuid[])',[users]);
    await service.onModuleDestroy(); await auth.onModuleDestroy(); await pool.end();
  }
});
