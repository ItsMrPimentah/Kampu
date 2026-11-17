import assert from 'node:assert/strict';
import test from 'node:test';
import { authorize } from '../src/modules/authz/policy';

test('requires authentication and established eligibility', () => {
  assert.equal(authorize({ action: 'community.access' }).allowed, false);
  assert.equal(authorize({ actor: { id: 'u1' }, action: 'community.access' }).reason, 'eligibility_required');
  assert.equal(authorize({ actor: { id: 'u1', eligibility: 'youth' }, action: 'community.access' }).allowed, true);
});

test('enforces team-scoped captain and delegated permissions', () => {
  const member = { id: 'u1', eligibility: 'adult' as const, teamMemberships: [{ teamId: 't1', role: 'member' as const }] };
  assert.equal(authorize({ actor: member, action: 'team.manage', teamId: 't1' }).allowed, false);
  assert.equal(authorize({ actor: { ...member, teamMemberships: [{ teamId: 't1', role: 'member', permissions: ['team.manage'] }] }, action: 'team.manage', teamId: 't1' }).allowed, true);
  assert.equal(authorize({ actor: { ...member, teamMemberships: [{ teamId: 't1', role: 'captain' }] }, action: 'booking.manage', teamId: 't1' }).allowed, true);
});

test('requires global roles for moderation and support', () => {
  const actor = { id: 'u1', eligibility: 'adult' as const };
  assert.equal(authorize({ actor, action: 'moderation.review' }).allowed, false);
  assert.equal(authorize({ actor: { ...actor, globalRoles: ['moderator'] }, action: 'moderation.review' }).allowed, true);
  assert.equal(authorize({ actor: { ...actor, globalRoles: ['support'] }, action: 'support.resolve' }).allowed, true);
});
