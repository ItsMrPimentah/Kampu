import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash, randomBytes } from 'node:crypto';
import { Pool, type PoolClient } from 'pg';
import { AuthService } from '../identity/auth.service';

const formats = new Set(['5v5', '7v7', '11v11']);
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const hash = (value: string) => createHash('sha256').update(value).digest('hex');
function id(value: unknown): string { if (typeof value !== 'string' || !uuid.test(value)) throw new BadRequestException('Invalid identifier'); return value; }
function text(value: unknown, name: string, max = 120): string { if (typeof value !== 'string' || !value.trim() || value.trim().length > max) throw new BadRequestException(`Invalid ${name}`); return value.trim(); }
function format(value: unknown): string { if (typeof value !== 'string' || !formats.has(value)) throw new BadRequestException('Unsupported format'); return value; }
function future(value: unknown): string { if (typeof value !== 'string' || !Number.isFinite(Date.parse(value)) || Date.parse(value) <= Date.now()) throw new BadRequestException('Choose a future match time'); return value; }

@Injectable()
export class CommunityService {
  private readonly pool = new Pool({ connectionString: process.env.DATABASE_URL });
  constructor(private readonly auth: AuthService) {}
  async onModuleDestroy() { await this.pool.end(); }
  async actor(header?: string): Promise<string> {
    const match = /^Bearer ([A-Za-z0-9_-]+)$/.exec(header ?? '');
    if (!match) throw new ForbiddenException('Sign in required');
    return (await this.auth.session(match[1])).user_id;
  }
  private async notify(c: PoolClient, userIds: string[], type: string, payload: Record<string, unknown>, actorId: string) {
    for (const recipient of new Set(userIds)) {
      if (recipient !== actorId) await c.query('INSERT INTO notifications (user_id,type,payload) VALUES ($1,$2,$3)', [recipient,type,JSON.stringify(payload)]);
    }
  }
  private async tx<T>(fn: (c: PoolClient) => Promise<T>): Promise<T> {
    const c = await this.pool.connect();
    try { await c.query('BEGIN'); const result = await fn(c); await c.query('COMMIT'); return result; }
    catch (error) { await c.query('ROLLBACK'); if ((error as {code?: string}).code === '23505') throw new ConflictException('This action was already completed'); throw error; }
    finally { c.release(); }
  }
  private async captain(c: PoolClient, teamId: string, userId: string) {
    const result = await c.query("SELECT 1 FROM team_memberships WHERE team_id=$1 AND user_id=$2 AND role='captain' AND active=true", [teamId, userId]);
    if (!result.rowCount) throw new ForbiddenException('Captain permission required');
  }

  async teams(userId: string) {
    return (await this.pool.query(`SELECT t.*, m.role AS my_role, (SELECT count(*)::int FROM team_memberships x WHERE x.team_id=t.id AND x.active) AS member_count
      FROM teams t LEFT JOIN team_memberships m ON m.team_id=t.id AND m.user_id=$1 AND m.active
      WHERE t.visibility='public' OR m.user_id IS NOT NULL ORDER BY t.created_at DESC LIMIT 100`, [userId])).rows;
  }
  async createTeam(userId: string, body: Record<string, unknown>) {
    const name = text(body.name, 'name'); const region = text(body.region, 'region', 80);
    const selected = Array.isArray(body.formats) ? body.formats.map(format) : [format(body.format)];
    if (!selected.length) throw new BadRequestException('Select a format');
    const visibility = body.visibility === 'private' ? 'private' : 'public';
    const description = typeof body.description === 'string' ? body.description.trim().slice(0, 1000) : '';
    return this.tx(async c => {
      const team = (await c.query('INSERT INTO teams (name,region,supported_formats,visibility,description) VALUES ($1,$2,$3,$4,$5) RETURNING *', [name, region, JSON.stringify(selected), visibility, description])).rows[0];
      await c.query("INSERT INTO team_memberships (team_id,user_id,role) VALUES ($1,$2,'captain')", [team.id, userId]);
      return team;
    });
  }
  async roster(userId: string, teamId: string) {
    id(teamId);
    const team = await this.pool.query(`SELECT t.* FROM teams t WHERE t.id=$1 AND (t.visibility='public' OR EXISTS (SELECT 1 FROM team_memberships m WHERE m.team_id=t.id AND m.user_id=$2 AND m.active))`, [teamId,userId]);
    if (!team.rowCount) throw new NotFoundException('Team not found');
    const members = await this.pool.query(`SELECT m.user_id,m.role,m.position,p.display_name FROM team_memberships m JOIN player_profiles p ON p.user_id=m.user_id WHERE m.team_id=$1 AND m.active ORDER BY m.created_at`, [teamId]);
    const myRole = (await this.pool.query('SELECT role FROM team_memberships WHERE team_id=$1 AND user_id=$2 AND active=true', [teamId,userId])).rows[0]?.role;
    return { team: team.rows[0], members: members.rows, myRole: myRole ?? null };
  }
  async requestJoin(userId: string, teamId: string) {
    id(teamId);
    return this.tx(async c => {
      const team = await c.query("SELECT id FROM teams WHERE id=$1 AND visibility='public' FOR UPDATE", [teamId]);
      if (!team.rowCount) throw new NotFoundException('Public team not found');
      if ((await c.query('SELECT 1 FROM team_memberships WHERE team_id=$1 AND user_id=$2 AND active', [teamId,userId])).rowCount) throw new ConflictException('Already a member');
      const request = (await c.query(`INSERT INTO team_join_requests (team_id,user_id) VALUES ($1,$2) ON CONFLICT (team_id,user_id) DO UPDATE SET status='pending', created_at=now() RETURNING *`, [teamId,userId])).rows[0];
      const captains = (await c.query("SELECT user_id FROM team_memberships WHERE team_id=$1 AND role='captain' AND active",[teamId])).rows.map(row => row.user_id as string);
      await this.notify(c,captains,'team.join_request',{teamId},userId);
      return request;
    });
  }
  async teamRequests(userId: string, teamId: string) {
    id(teamId); return this.tx(async c => { await this.captain(c,teamId,userId); return (await c.query(`SELECT r.*,p.display_name FROM team_join_requests r JOIN player_profiles p ON p.user_id=r.user_id WHERE team_id=$1 AND status='pending' ORDER BY r.created_at`,[teamId])).rows; });
  }
  async decideJoin(userId: string, teamId: string, requestId: string, approve: boolean) {
    id(teamId); id(requestId); return this.tx(async c => {
      await this.captain(c,teamId,userId);
      const request = (await c.query("SELECT * FROM team_join_requests WHERE id=$1 AND team_id=$2 AND status='pending' FOR UPDATE",[requestId,teamId])).rows[0];
      if (!request) throw new NotFoundException('Request not found');
      await c.query('UPDATE team_join_requests SET status=$1 WHERE id=$2',[approve?'approved':'rejected',requestId]);
      if (approve) await c.query("INSERT INTO team_memberships (team_id,user_id,role,active) VALUES ($1,$2,'member',true) ON CONFLICT (team_id,user_id) DO UPDATE SET active=true,role='member'",[teamId,request.user_id]);
      await this.notify(c,[request.user_id],approve?'team.join_approved':'team.join_rejected',{teamId},userId);
      return { status: approve?'approved':'rejected' };
    });
  }
  async invite(userId: string, teamId: string) {
    id(teamId); return this.tx(async c => {
      await this.captain(c,teamId,userId); const token = randomBytes(24).toString('base64url');
      await c.query("INSERT INTO team_invites (team_id,created_by,token_hash,expires_at) VALUES ($1,$2,$3,now()+interval '7 days')",[teamId,userId,hash(token)]);
      return { token, expiresInDays: 7 };
    });
  }
  async acceptInvite(userId: string, token: string) {
    if (!/^[\w-]{32}$/.test(token)) throw new BadRequestException('Invalid invitation');
    return this.tx(async c => {
      const invite = (await c.query('SELECT * FROM team_invites WHERE token_hash=$1 AND expires_at>now()',[hash(token)])).rows[0];
      if (!invite) throw new NotFoundException('Invitation expired or not found');
      await c.query("INSERT INTO team_memberships (team_id,user_id,role,active) VALUES ($1,$2,'member',true) ON CONFLICT (team_id,user_id) DO UPDATE SET active=true",[invite.team_id,userId]);
      return { teamId: invite.team_id };
    });
  }
  async member(userId: string, teamId: string, memberId: string, body: Record<string, unknown>) {
    id(teamId); id(memberId); return this.tx(async c => {
      await this.captain(c,teamId,userId);
      if (memberId === userId && (body.active === false || body.role === 'member' || body.role === 'manager')) throw new BadRequestException('Captain cannot demote or remove themselves');
      if (body.role !== undefined && !['member','manager'].includes(String(body.role))) throw new BadRequestException('Invalid role');
      if (body.position !== undefined && (typeof body.position !== 'string' || body.position.length > 32)) throw new BadRequestException('Invalid position');
      if (body.active !== undefined && typeof body.active !== 'boolean') throw new BadRequestException('Invalid active status');
      const result = await c.query(`UPDATE team_memberships SET role=COALESCE($3,role),position=COALESCE($4,position),active=COALESCE($5,active),updated_at=now() WHERE team_id=$1 AND user_id=$2 RETURNING user_id,role,position,active`,[teamId,memberId,body.role??null,body.position??null,body.active??null]);
      if (!result.rowCount) throw new NotFoundException('Member not found'); return result.rows[0];
    });
  }
  async leaveTeam(userId: string, teamId: string) {
    id(teamId); const result = await this.pool.query("UPDATE team_memberships SET active=false,updated_at=now() WHERE team_id=$1 AND user_id=$2 AND active=true AND role <> 'captain' RETURNING active",[teamId,userId]);
    if (!result.rowCount) throw new ForbiddenException('Unable to leave this team');
    return result.rows[0];
  }
  async notifications(userId: string) {
    return (await this.pool.query('SELECT id,type,payload,created_at FROM notifications WHERE user_id=$1 ORDER BY created_at DESC LIMIT 100',[userId])).rows;
  }
  async updateTeamFormats(userId: string, teamId: string, body: Record<string, unknown>) {
    id(teamId); if (!Array.isArray(body.formats) || body.formats.length === 0) throw new BadRequestException('Select a format');
    const selected = [...new Set(body.formats.map(format))];
    return this.tx(async c => {
      await this.captain(c,teamId,userId);
      return (await c.query('UPDATE teams SET supported_formats=$2,updated_at=now() WHERE id=$1 RETURNING *',[teamId,JSON.stringify(selected)])).rows[0];
    });
  }

  async challenges(userId: string) {
    return (await this.pool.query(`SELECT m.*,h.name AS host_name,o.name AS opponent_name FROM matches m JOIN teams h ON h.id=m.host_team_id LEFT JOIN teams o ON o.id=m.opponent_team_id
      WHERE (m.status='open' AND h.visibility='public') OR EXISTS (SELECT 1 FROM team_memberships tm WHERE tm.user_id=$1 AND tm.active AND tm.team_id IN (m.host_team_id,m.opponent_team_id)) ORDER BY m.created_at DESC LIMIT 100`,[userId])).rows;
  }
  async createChallenge(userId: string, body: Record<string, unknown>) {
    const teamId=id(body.teamId); const matchFormat=format(body.format); const scheduledAt=future(body.scheduledAt); const region=text(body.region,'region',80);
    const field = typeof body.field === 'string' ? body.field.trim().slice(0,120) : '';
    return this.tx(async c => {
      await this.captain(c,teamId,userId);
      const team = (await c.query('SELECT supported_formats FROM teams WHERE id=$1',[teamId])).rows[0];
      if (!team || !team.supported_formats.includes(matchFormat)) throw new BadRequestException('Team does not support this format');
      const match = (await c.query("INSERT INTO matches (host_team_id,format,status,scheduled_at,region,field_name) VALUES ($1,$2,'open',$3,$4,$5) RETURNING *",[teamId,matchFormat,scheduledAt,region,field])).rows[0];
      await c.query('INSERT INTO match_proposals (match_id,version,proposed_by_user_id,proposed_by_team_id,terms) VALUES ($1,1,$2,$3,$4)',[match.id,userId,teamId,JSON.stringify({scheduledAt,region,field})]);
      return match;
    });
  }
  async challenge(userId: string, matchId: string) {
    id(matchId); const match = (await this.pool.query(`SELECT m.*,h.name AS host_name,o.name AS opponent_name FROM matches m JOIN teams h ON h.id=m.host_team_id LEFT JOIN teams o ON o.id=m.opponent_team_id
      WHERE m.id=$1 AND ((m.status='open' AND h.visibility='public') OR EXISTS (SELECT 1 FROM team_memberships tm WHERE tm.user_id=$2 AND tm.active AND tm.team_id IN (m.host_team_id,m.opponent_team_id)))`,[matchId,userId])).rows[0];
    if (!match) throw new NotFoundException('Challenge not found');
    const proposals=(await this.pool.query('SELECT * FROM match_proposals WHERE match_id=$1 ORDER BY version',[matchId])).rows;
    const votes=(await this.pool.query('SELECT * FROM challenge_field_votes WHERE match_id=$1 ORDER BY created_at DESC',[matchId])).rows;
    return { match, proposals, votes };
  }
  async challengeAction(userId: string, matchId: string, action: string, body: Record<string, unknown>) {
    id(matchId); const teamId=id(body.teamId);
    return this.tx(async c => {
      await this.captain(c,teamId,userId);
      const match=(await c.query('SELECT * FROM matches WHERE id=$1 FOR UPDATE',[matchId])).rows[0];
      if (!match) throw new NotFoundException('Challenge not found');
      if (action === 'join') {
        if (match.status !== 'open' || match.opponent_team_id || match.host_team_id === teamId) throw new ConflictException('Challenge unavailable');
        const team = (await c.query('SELECT supported_formats FROM teams WHERE id=$1',[teamId])).rows[0];
        if (!team || !team.supported_formats.includes(match.format)) throw new ConflictException('Team does not support this format');
        await c.query("UPDATE matches SET opponent_team_id=$2,status='negotiation',version=version+1 WHERE id=$1",[matchId,teamId]);
      } else {
        if (![match.host_team_id,match.opponent_team_id].includes(teamId)) throw new ForbiddenException('Team is not part of this challenge');
        if (action === 'counter') {
          if (!['negotiation','agreed','scheduling'].includes(match.status)) throw new ConflictException('Cannot counter in this state');
          const time=future(body.scheduledAt); const region=text(body.region,'region',80); const field=text(body.field,'field');
          if (['agreed','scheduling'].includes(match.status) && field !== (match.field_name ?? '')) throw new ConflictException('Field changes after agreement require a field vote');
          const version=Number(match.version)+1;
          await c.query("UPDATE match_proposals SET decision='superseded' WHERE match_id=$1 AND decision IS NULL",[matchId]);
          await c.query('INSERT INTO match_proposals (match_id,version,proposed_by_user_id,proposed_by_team_id,terms) VALUES ($1,$2,$3,$4,$5)',[matchId,version,userId,teamId,JSON.stringify({scheduledAt:time,region,field})]);
          await c.query("UPDATE matches SET status='negotiation',version=$2 WHERE id=$1",[matchId,version]);
        } else if (action === 'accept') {
          if (!match.opponent_team_id || match.status !== 'negotiation') throw new ConflictException('No proposal to accept');
          const proposal=(await c.query('SELECT * FROM match_proposals WHERE match_id=$1 ORDER BY version DESC LIMIT 1',[matchId])).rows[0];
          if (proposal.proposed_by_team_id === teamId) throw new ForbiddenException('The other captain must accept');
          await c.query("UPDATE match_proposals SET decision='accepted',accepted_by_team_id=$2 WHERE id=$1",[proposal.id,teamId]);
          await c.query("UPDATE matches SET status='agreed',scheduled_at=$2,region=$3,field_name=$4,version=version+1 WHERE id=$1",[matchId,proposal.terms.scheduledAt,proposal.terms.region,proposal.terms.field]);
        } else if (action === 'decline' || action === 'cancel') {
          if (!['open','negotiation','agreed','scheduling'].includes(match.status)) throw new ConflictException('Cannot cancel in this state');
          await c.query("UPDATE matches SET status='cancelled',version=version+1 WHERE id=$1",[matchId]);
        } else if (action === 'confirm') {
          if (!['agreed','scheduling'].includes(match.status)) throw new ConflictException('Terms must be agreed first');
          await c.query("UPDATE matches SET status='confirmed',version=version+1 WHERE id=$1",[matchId]);
        } else if (action === 'field-status') {
          if (!['agreed','scheduling','confirmed'].includes(match.status)) throw new ConflictException('Terms must be agreed first');
          if (!['in_confirmation','confirmed'].includes(String(body.status))) throw new BadRequestException('Invalid field status');
          await c.query('UPDATE matches SET field_status=$2,version=version+1 WHERE id=$1',[matchId,body.status]);
        } else if (action === 'field-proposal') {
          if (!match.opponent_team_id || !['agreed','scheduling','confirmed'].includes(match.status)) throw new ConflictException('A two-team match is required');
          if (Date.parse(match.scheduled_at) - Date.now() <= 48 * 3600000) throw new ConflictException('Field vote deadline has passed');
          await c.query('INSERT INTO challenge_field_votes (match_id,proposed_field,proposed_by_team_id) VALUES ($1,$2,$3)',[matchId,text(body.field,'field'),teamId]);
        } else if (action === 'field-approve') {
          if (Date.parse(match.scheduled_at) - Date.now() <= 48 * 3600000) throw new ConflictException('Field vote deadline has passed');
          const vote=(await c.query("SELECT * FROM challenge_field_votes WHERE match_id=$1 AND status='pending' FOR UPDATE",[matchId])).rows[0];
          if (!vote || vote.proposed_by_team_id === teamId) throw new ForbiddenException('The other captain must approve');
          await c.query("UPDATE challenge_field_votes SET status='approved',approved_by_team_id=$2 WHERE id=$1",[vote.id,teamId]);
          await c.query("UPDATE matches SET field_name=$2,field_status='in_confirmation',version=version+1 WHERE id=$1",[matchId,vote.proposed_field]);
        } else throw new BadRequestException('Unknown challenge action');
      }
      const recipients = (await c.query("SELECT user_id FROM team_memberships WHERE active=true AND role='captain' AND team_id IN ($1,$2)",[match.host_team_id, match.opponent_team_id])).rows.map(row => row.user_id as string);
      await this.notify(c,recipients,`challenge.${action}`,{matchId},userId);
      return (await c.query('SELECT * FROM matches WHERE id=$1',[matchId])).rows[0];
    });
  }

  async games(userId: string) {
    return (await this.pool.query(`SELECT g.*,p.display_name AS organizer_name,
      (SELECT count(*)::int FROM open_game_applications a WHERE a.game_id=g.id AND a.status='approved') AS approved_count,
      (SELECT status FROM open_game_applications a WHERE a.game_id=g.id AND a.user_id=$1) AS my_status, (g.organizer_id=$1) AS is_organizer
      FROM open_games g JOIN player_profiles p ON p.user_id=g.organizer_id
      WHERE g.visibility='public' OR g.organizer_id=$1 OR EXISTS (SELECT 1 FROM open_game_applications a WHERE a.game_id=g.id AND a.user_id=$1 AND a.status IN ('pending','waitlisted','approved')) ORDER BY g.scheduled_at LIMIT 100`,[userId])).rows;
  }
  async createGame(userId: string, body: Record<string, unknown>) {
    const title=text(body.title,'title'); const region=text(body.region,'region',80); const location=text(body.location,'location'); const scheduledAt=future(body.scheduledAt); const matchFormat=format(body.format);
    const capacity=Number(body.capacity); if (!Number.isInteger(capacity) || capacity < 1 || capacity > 100) throw new BadRequestException('Invalid capacity');
    if (body.approvalRequired !== undefined && typeof body.approvalRequired !== 'boolean') throw new BadRequestException('Invalid participation mode');
    const positions = Array.isArray(body.requiredPositions) ? body.requiredPositions.map(v => text(v,'position',32)).slice(0,20) : [];
    return (await this.pool.query(`INSERT INTO open_games (organizer_id,title,format,region,location,scheduled_at,capacity,approval_required,visibility,required_positions) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,[userId,title,matchFormat,region,location,scheduledAt,capacity,body.approvalRequired??true,body.visibility==='private'?'private':'public',JSON.stringify(positions)])).rows[0];
  }
  async game(userId: string, gameId: string) {
    id(gameId);
    const result = await this.pool.query(`SELECT g.*,p.display_name AS organizer_name,
      (SELECT count(*)::int FROM open_game_applications a WHERE a.game_id=g.id AND a.status='approved') AS approved_count,
      (SELECT status FROM open_game_applications a WHERE a.game_id=g.id AND a.user_id=$2) AS my_status, (g.organizer_id=$2) AS is_organizer
      FROM open_games g JOIN player_profiles p ON p.user_id=g.organizer_id
      WHERE g.id=$1 AND (g.visibility='public' OR g.organizer_id=$2 OR EXISTS (SELECT 1 FROM open_game_applications a WHERE a.game_id=g.id AND a.user_id=$2 AND a.status IN ('pending','waitlisted','approved')))`,[gameId,userId]);
    if (!result.rowCount) throw new NotFoundException('Game not found'); return result.rows[0];
  }
  async gameInvite(userId: string, gameId: string) {
    id(gameId); return this.tx(async c => {
      const game = (await c.query('SELECT * FROM open_games WHERE id=$1 FOR UPDATE',[gameId])).rows[0];
      if (!game || game.organizer_id !== userId) throw new ForbiddenException('Organizer permission required');
      if (Date.parse(game.scheduled_at) <= Date.now()) throw new ConflictException('Game has started');
      if (game.status !== 'open') throw new ConflictException('Game is closed');
      const token = randomBytes(24).toString('base64url');
      await c.query("INSERT INTO open_game_invites (game_id,token_hash,expires_at) VALUES ($1,$2,now()+interval '7 days')",[gameId,hash(token)]);
      return { token, expiresInDays: 7 };
    });
  }
  async finishGame(userId: string, gameId: string, action: string) {
    id(gameId); if (!['cancel','complete'].includes(action)) throw new BadRequestException('Invalid action');
    return this.tx(async c => {
      const game = (await c.query('SELECT * FROM open_games WHERE id=$1 FOR UPDATE',[gameId])).rows[0];
      if (!game || game.organizer_id !== userId) throw new ForbiddenException('Organizer permission required');
      if (game.status !== 'open') throw new ConflictException('Game already closed');
      if (action === 'complete' && Date.parse(game.scheduled_at) > Date.now()) throw new ConflictException('Game has not started');
      const result = await c.query('UPDATE open_games SET status=$2 WHERE id=$1 RETURNING *',[gameId,action === 'cancel' ? 'cancelled' : 'completed']);
      const players = (await c.query("SELECT user_id FROM open_game_applications WHERE game_id=$1 AND status IN ('approved','pending','waitlisted')",[gameId])).rows.map(row => row.user_id as string);
      await this.notify(c,players,`game.${action}`,{gameId},userId);
      return result.rows[0];
    });
  }
  async applyGameInvite(userId: string, token: string) {
    if (!/^[\w-]{32}$/.test(token)) throw new BadRequestException('Invalid invitation');
    const invite = (await this.pool.query('SELECT game_id FROM open_game_invites WHERE token_hash=$1 AND expires_at>now()',[hash(token)])).rows[0];
    if (!invite) throw new NotFoundException('Invitation expired or not found');
    return this.applyGame(userId, invite.game_id, true);
  }
  async applyGame(userId: string, gameId: string, invited = false) {
    id(gameId); return this.tx(async c => {
      const game=(await c.query('SELECT * FROM open_games WHERE id=$1 FOR UPDATE',[gameId])).rows[0];
      if (!game || (game.visibility !== 'public' && !invited)) throw new NotFoundException('Game not found');
      if (game.status !== 'open') throw new ConflictException('Game is closed');
      if (game.organizer_id === userId) throw new ConflictException('Organizer cannot apply');
      if (Date.parse(game.scheduled_at) <= Date.now()) throw new ConflictException('Game has started');
      const count=Number((await c.query("SELECT count(*) FROM open_game_applications WHERE game_id=$1 AND status='approved'",[gameId])).rows[0].count);
      const status=count>=game.capacity?'waitlisted':game.approval_required?'pending':'approved';
      const result=await c.query(`INSERT INTO open_game_applications (game_id,user_id,status) VALUES ($1,$2,$3) ON CONFLICT (game_id,user_id) DO UPDATE SET status=EXCLUDED.status,created_at=now(),updated_at=now() WHERE open_game_applications.status IN ('rejected','withdrawn') RETURNING *`,[gameId,userId,status]);
      if (!result.rowCount) throw new ConflictException('Already joined or applied');
      await this.notify(c,[game.organizer_id],'game.application',{gameId,status},userId);
      return result.rows[0];
    });
  }
  async applications(userId: string, gameId: string) {
    id(gameId); const game=(await this.pool.query('SELECT * FROM open_games WHERE id=$1 AND organizer_id=$2',[gameId,userId])).rows[0];
    if (!game) throw new ForbiddenException('Organizer permission required');
    return (await this.pool.query('SELECT a.*,p.display_name FROM open_game_applications a JOIN player_profiles p ON p.user_id=a.user_id WHERE a.game_id=$1 ORDER BY a.created_at',[gameId])).rows;
  }
  async decideGame(userId: string, gameId: string, applicationId: string, approve: boolean) {
    id(gameId); id(applicationId); return this.tx(async c => {
      const game=(await c.query('SELECT * FROM open_games WHERE id=$1 FOR UPDATE',[gameId])).rows[0];
      if (!game || game.organizer_id !== userId) throw new ForbiddenException('Organizer permission required');
      if (game.status !== 'open') throw new ConflictException('Game is closed');
      if (Date.parse(game.scheduled_at) <= Date.now()) throw new ConflictException('Game has started');
      const application=(await c.query("SELECT * FROM open_game_applications WHERE id=$1 AND game_id=$2 AND status IN ('pending','waitlisted') FOR UPDATE",[applicationId,gameId])).rows[0];
      if (!application) throw new NotFoundException('Application not found');
      if (approve) {
        const count=Number((await c.query("SELECT count(*) FROM open_game_applications WHERE game_id=$1 AND status='approved'",[gameId])).rows[0].count);
        if (count>=game.capacity) throw new ConflictException('Game is full');
      }
      const updated = (await c.query('UPDATE open_game_applications SET status=$2,updated_at=now() WHERE id=$1 RETURNING *',[applicationId,approve?'approved':'rejected'])).rows[0];
      await this.notify(c,[application.user_id],approve?'game.approved':'game.rejected',{gameId},userId);
      return updated;
    });
  }
  async withdrawGame(userId: string, gameId: string) {
    id(gameId); return this.tx(async c => {
      const game = (await c.query('SELECT * FROM open_games WHERE id=$1 FOR UPDATE',[gameId])).rows[0];
      if (!game) throw new NotFoundException('Game not found');
      const previous = (await c.query("SELECT status FROM open_game_applications WHERE game_id=$1 AND user_id=$2 AND status IN ('approved','pending','waitlisted') FOR UPDATE",[gameId,userId])).rows[0];
      if (!previous) throw new NotFoundException('Application not found');
      const result = await c.query("UPDATE open_game_applications SET status='withdrawn',updated_at=now() WHERE game_id=$1 AND user_id=$2 RETURNING status",[gameId,userId]);
      if (previous.status === 'approved') {
        const waiting = (await c.query("SELECT user_id FROM open_game_applications WHERE game_id=$1 AND status='waitlisted'",[gameId])).rows.map(row => row.user_id as string);
        await this.notify(c,waiting,'game.slot_available',{gameId},userId);
      }
      return result.rows[0];
    });
  }
  async removeGamePlayer(userId: string, gameId: string, applicationId: string) {
    id(gameId); id(applicationId); return this.tx(async c => {
      const game = (await c.query('SELECT * FROM open_games WHERE id=$1 FOR UPDATE',[gameId])).rows[0];
      if (!game || game.organizer_id !== userId) throw new ForbiddenException('Organizer permission required');
      const result = await c.query("UPDATE open_game_applications SET status='withdrawn',updated_at=now() WHERE id=$1 AND game_id=$2 AND status='approved' RETURNING status",[applicationId,gameId]);
      if (!result.rowCount) throw new NotFoundException('Participant not found');
      const waiting = (await c.query("SELECT user_id FROM open_game_applications WHERE game_id=$1 AND status='waitlisted'",[gameId])).rows.map(row => row.user_id as string);
      await this.notify(c,waiting,'game.slot_available',{gameId},userId);
      return result.rows[0];
    });
  }
}
