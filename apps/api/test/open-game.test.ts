import assert from 'node:assert/strict';
import test from 'node:test';
import { OpenGameError, OpenGameService } from '../src/modules/matches/open-game.service';

test('manages applications, capacity, and waiting list promotion', () => {
  const service = new OpenGameService();
  const game = service.create({ organizerId: 'organizer', format: '5v5', capacity: 1, requiredPositions: ['goalkeeper'], waitingListEnabled: true });
  const first = service.apply(game.id, 'player-1', 'goalkeeper');
  const second = service.apply(game.id, 'player-2', 'defender');
  assert.equal(service.approve(game.id, 'organizer', first.id).status, 'approved');
  assert.equal(service.approve(game.id, 'organizer', second.id).status, 'waitlisted');
  service.withdraw(game.id, 'player-1');
  assert.equal(service.get(game.id)?.applications.find((item) => item.playerId === 'player-2')?.status, 'approved');
});

test('prevents duplicate applications, over-capacity approvals, and unauthorized approval', () => {
  const service = new OpenGameService();
  const game = service.create({ organizerId: 'organizer', format: '7v7', capacity: 1, waitingListEnabled: false });
  const application = service.apply(game.id, 'player-1');
  assert.throws(() => service.apply(game.id, 'player-1'), /already/);
  assert.throws(() => service.approve(game.id, 'other-user', application.id), /Organizer/);
});
