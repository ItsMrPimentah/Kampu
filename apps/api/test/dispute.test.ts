import assert from 'node:assert/strict';
import test from 'node:test';
import { DisputeService } from '../src/modules/payments/dispute.service';

test('uses captain-first review and escalation without changing match states', () => {
  const service = new DisputeService();
  const dispute = service.open({ contributionId: 'contribution-1', participantId: 'player', captainId: 'captain', reason: 'Payment was not received', reviewDeadline: '2026-01-01T00:00:00Z' });
  assert.equal(service.resolve(dispute.id, 'captain', false).status, 'resolved_unpaid');
  const escalated = service.open({ contributionId: 'contribution-2', participantId: 'player', captainId: 'captain', reason: 'Dispute', reviewDeadline: '2026-01-01T00:00:00Z' });
  assert.equal(service.escalate(escalated.id, 'player').status, 'escalated');
  assert.ok(service.get(escalated.id)?.audit.length);
});
