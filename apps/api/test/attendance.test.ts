import assert from 'node:assert/strict';
import test from 'node:test';
import { AttendanceService } from '../src/modules/matches/attendance.service';

test('tracks attendance responses and no-shows', () => {
  const service = new AttendanceService();
  service.request('match-1', 'organizer', ['player-1', 'player-2'], 'organizer');
  assert.equal(service.respond('match-1', 'player-1', 'confirmed').status, 'confirmed');
  assert.equal(service.markNoShow('match-1', 'organizer', 'player-2', 'organizer').status, 'no_show');
});

test('makes completion idempotent and emits one event', () => {
  const service = new AttendanceService();
  const first = service.complete('match-1', 'organizer', 'organizer');
  const second = service.complete('match-1', 'organizer', 'organizer');
  assert.equal(first.id, second.id);
  assert.equal(service.events().length, 1);
});
