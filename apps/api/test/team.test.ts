import assert from 'node:assert/strict';
import test from 'node:test';
import { TeamService } from '../src/modules/teams/team.service';

test('creates a captain-owned team and supports multiple team memberships', () => {
  const service = new TeamService();
  const captain = { userId: 'captain', eligibility: 'adult' as const };
  const teamA = service.create(captain, { name: 'Lisbon Lions', region: 'Lisbon' });
  const teamB = service.create(captain, { name: 'Setúbal United', region: 'Setúbal' });
  const invitation = service.invite(captain, teamA.id, 'player');
  service.acceptInvitation({ userId: 'player', eligibility: 'youth' }, invitation.id);
  const secondInvitation = service.invite(captain, teamB.id, 'player');
  service.acceptInvitation({ userId: 'player', eligibility: 'youth' }, secondInvitation.id);
  assert.equal(service.membershipsFor('player').length, 2);
  service.leave({ userId: 'player', eligibility: 'youth' }, teamA.id);
  assert.equal(service.membership(teamA.id, 'player')?.active, false);
  assert.equal(service.membership(teamB.id, 'player')?.active, true);
});

test('allows captain removal but keeps other members scoped to the team', () => {
  const service = new TeamService();
  const captain = { userId: 'captain', eligibility: 'adult' as const };
  const team = service.create(captain, { name: 'Pitch Pulse', region: 'Lisbon' });
  const invitation = service.invite(captain, team.id, 'player');
  service.acceptInvitation({ userId: 'player', eligibility: 'adult' }, invitation.id);
  service.removeMember(captain, team.id, 'player');
  assert.equal(service.membership(team.id, 'player')?.active, false);
});

test('audits rejected team administration attempts', () => {
  const service = new TeamService();
  const captain = { userId: 'captain', eligibility: 'adult' as const };
  const team = service.create(captain, { name: 'Audit FC', region: 'Lisbon' });
  const invitation = service.invite(captain, team.id, 'member');
  service.acceptInvitation({ userId: 'member', eligibility: 'adult' }, invitation.id);
  assert.throws(() => service.setSupportedFormats({ userId: 'member', eligibility: 'adult' }, team.id, ['5v5']), /permission/);
  assert.equal(service.authorizationFailures()[0].reason, 'team_permission_required');
});
