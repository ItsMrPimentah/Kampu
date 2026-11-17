import assert from 'node:assert/strict';
import test from 'node:test';
import { NegotiationConflictError, NegotiationService } from '../src/modules/matches/negotiation.service';

test('selects one opponent and preserves versioned counteroffers', () => {
  const service = new NegotiationService();
  const negotiation = service.create('team-a', '5v5', { time: 'saturday' });
  service.selectOpponent(negotiation.id, 'team-b', 1);
  const counter = service.counteroffer(negotiation.id, 'team-b', { time: 'sunday' }, 2);
  service.approve(negotiation.id, 'team-a', counter.version, 3);
  const agreed = service.approve(negotiation.id, 'team-b', counter.version, 4);
  assert.equal(agreed.status, 'agreed');
  assert.equal(agreed.proposals.length, 2);
});

test('rejects self-challenges and concurrent competing opponents', () => {
  const service = new NegotiationService();
  const negotiation = service.create('team-a', '7v7');
  assert.throws(() => service.selectOpponent(negotiation.id, 'team-a', 1), /itself/);
  service.selectOpponent(negotiation.id, 'team-b', 1);
  assert.throws(() => service.selectOpponent(negotiation.id, 'team-c', 1), NegotiationConflictError);
  assert.throws(() => service.selectOpponent(negotiation.id, 'team-c', 2), /Only one/);
});
