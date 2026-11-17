import assert from 'node:assert/strict';
import test from 'node:test';
import { OperatorAuthorizationError, OperatorControlService } from '../src/modules/operator/operator-control.service';

const operator = { id: 'operator-1', globalRoles: ['operator'] as const };

test('enforces operator authorization for pilot controls and audit review', () => {
  const service = new OperatorControlService();
  const regular = { id: 'user-1' };
  assert.throws(() => service.setFeatureFlag(regular, 'nativeBooking', true), OperatorAuthorizationError);
  assert.throws(() => service.auditEntries(regular), OperatorAuthorizationError);

  const venue = service.configureVenue(operator, { partner: 'PlayArena', region: 'Lisbon', enabled: true });
  service.setFeatureFlag(operator, 'nativeBooking', true);
  service.setConnectorHealth(operator, 'PlayArena', 'healthy');
  const exception = service.recordBookingException(operator, 'booking-1', 'Provider timeout');
  service.resolveBookingException(operator, exception.id);

  assert.equal(service.venue('PlayArena', 'Lisbon')?.enabled, true);
  assert.equal(service.featureFlag('nativeBooking'), true);
  assert.equal(service.connectorHealth('PlayArena')?.status, 'healthy');
  assert.equal(service.auditEntries(operator).length, 5);
  assert.equal(venue.region, 'Lisbon');
});

test('uses role-specific access for moderation and disputes', () => {
  const service = new OperatorControlService();
  const moderator = { id: 'moderator-1', globalRoles: ['moderator'] as const };
  const support = { id: 'support-1', globalRoles: ['support'] as const };

  const moderation = service.reviewModeration(moderator, 'case-1', 'restricted');
  const dispute = service.reviewDispute(support, 'dispute-1', 'escalated');
  assert.equal(moderation.decision, 'restricted');
  assert.equal(dispute.resolution, 'escalated');
  assert.throws(() => service.reviewDispute(moderator, 'dispute-2', 'resolved_paid'), OperatorAuthorizationError);
  assert.throws(() => service.reviewModeration(support, 'case-2', 'removed'), OperatorAuthorizationError);
});
