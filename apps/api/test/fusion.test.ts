import assert from 'node:assert/strict';
import test from 'node:test';
import { FusionError, FusionService } from '../src/modules/matches/fusion.service';

test('associates separate teams without merging authority or payment records', () => {
  const service = new FusionService();
  const game = service.create('match-1', [{ teamId: 'team-a', captainId: 'captain-a' }, { teamId: 'team-b', captainId: 'captain-b' }]);
  service.updateTeamDetails(game.id, 'captain-a', { color: 'green' });
  service.recordContribution(game.id, 'captain-b', 'player-b', 5);
  const stored = service.get(game.id)!;
  assert.deepEqual(stored.teams.map((team) => team.teamId), ['team-a', 'team-b']);
  assert.deepEqual(stored.teams[0].details, { color: 'green' });
  assert.deepEqual(stored.teams[1].contributions, { 'player-b': 5 });
});

test('prevents duplicate teams and cross-captain updates', () => {
  const service = new FusionService();
  assert.throws(() => service.create('match-1', [{ teamId: 'team-a', captainId: 'captain-a' }, { teamId: 'team-a', captainId: 'captain-b' }]), /distinct/);
  const game = service.create('match-1', [{ teamId: 'team-a', captainId: 'captain-a' }, { teamId: 'team-b', captainId: 'captain-b' }]);
  assert.throws(() => service.updateTeamDetails(game.id, 'captain-c', {}), FusionError);
});
