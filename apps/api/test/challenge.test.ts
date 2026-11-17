import assert from 'node:assert/strict';
import test from 'node:test';
import { ChallengeService } from '../src/modules/matches/challenge.service';

test('enforces the Team vs Team lifecycle', () => {
  const service = new ChallengeService();
  const challenge = service.create({ hostTeamId: 'team-a', format: '7v7', region: 'Lisbon' });
  service.transition(challenge.id, 'open', 1);
  service.transition(challenge.id, 'negotiation', 2);
  service.transition(challenge.id, 'agreed', 3);
  service.setSchedule(challenge.id, '2026-11-01T10:00:00.000Z', 4);
  service.transition(challenge.id, 'confirmed', 5);
  const completed = service.transition(challenge.id, 'completed', 6);
  assert.equal(completed.status, 'completed');
  assert.ok(completed.completedAt);
});

test('rejects invalid and stale transitions', () => {
  const service = new ChallengeService();
  const challenge = service.create({ hostTeamId: 'team-a', format: '5v5' });
  assert.throws(() => service.transition(challenge.id, 'completed', 1), /Cannot transition/);
  service.transition(challenge.id, 'open', 1);
  assert.throws(() => service.transition(challenge.id, 'negotiation', 1), /version conflict/);
  assert.throws(() => service.setSchedule(challenge.id, 'not-a-date', 2), /invalid/);
});
