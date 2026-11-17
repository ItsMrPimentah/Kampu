import assert from 'node:assert/strict';
import test from 'node:test';
import { evaluateEligibility } from '../src/modules/identity/eligibility';
import { TeamService } from '../src/modules/teams/team.service';
import { ChallengeService } from '../src/modules/matches/challenge.service';
import { NegotiationService } from '../src/modules/matches/negotiation.service';
import { FusionService } from '../src/modules/matches/fusion.service';
import { AttendanceService } from '../src/modules/matches/attendance.service';
import { FakeBookingConnector } from '../src/modules/venues/fake-connector';
import { BookingService } from '../src/modules/venues/booking.service';
import { StripeSandboxService } from '../src/modules/payments/stripe-sandbox.service';
import { PaymentLedgerService } from '../src/modules/payments/ledger.service';
import { DisputeService } from '../src/modules/payments/dispute.service';
import { AnalyticsService } from '../src/modules/analytics/analytics.service';

test('covers the primary match vertical slice and preserves failed states', async () => {
  const now = new Date('2026-01-01T00:00:00.000Z');
  const adult = evaluateEligibility('1990-04-12', now);
  const youth = evaluateEligibility('2008-06-24', now);
  assert.equal(adult.category, 'adult');
  assert.equal(youth.category, 'youth');

  const teams = new TeamService();
  const home = teams.create({ userId: 'captain-1', eligibility: adult.category }, { name: 'Lisbon Falcons', region: 'Lisbon' });
  const away = teams.create({ userId: 'captain-2', eligibility: adult.category }, { name: 'Setúbal Strikers', region: 'Setúbal' });

  const challenges = new ChallengeService();
  let challenge = challenges.create({ hostTeamId: home.id, format: '5v5', region: 'Lisbon', paymentConditions: { amount: 50, currency: 'EUR' } });
  challenge = challenges.transition(challenge.id, 'open', challenge.version);

  const negotiation = new NegotiationService();
  let proposal = negotiation.create(home.id, '5v5', { region: 'Lisbon' });
  proposal = negotiation.selectOpponent(proposal.id, away.id, proposal.version);
  proposal = negotiation.approve(proposal.id, home.id, proposal.proposals.length, proposal.version);
  proposal = negotiation.approve(proposal.id, away.id, proposal.proposals.length, proposal.version);
  assert.equal(proposal.status, 'agreed');

  challenge = challenges.transition(challenge.id, 'negotiation', challenge.version);
  challenge = challenges.transition(challenge.id, 'agreed', challenge.version);
  challenge = challenges.setSchedule(challenge.id, '2026-06-20T15:00:00.000Z', challenge.version);
  challenge = challenges.transition(challenge.id, 'confirmed', challenge.version);

  const fusion = new FusionService();
  const fusionGame = fusion.create(challenge.id, [
    { teamId: home.id, captainId: 'captain-1' },
    { teamId: away.id, captainId: 'captain-2' },
  ]);
  fusion.updateTeamDetails(fusionGame.id, 'captain-1', { formation: '2-2' });
  fusion.recordContribution(fusionGame.id, 'captain-1', 'youth-player', 10);
  assert.equal(fusion.get(fusionGame.id)?.teams.length, 2);

  const booking = new BookingService(new FakeBookingConnector());
  const managedBooking = await booking.reserve({
    id: 'booking-1',
    matchId: challenge.id,
    venueId: 'PlayArena Lisbon',
    providerSlotId: 'slot-1',
    idempotencyKey: 'seed-booking-key',
    expiresAt: '2026-06-20T14:00:00.000Z',
  });
  assert.equal(managedBooking.status, 'pending_provider_confirmation');
  const confirmedBooking = await booking.applyProviderEvent(managedBooking.id, {
    eventId: 'provider-event-1',
    providerReference: managedBooking.providerReference!,
    status: 'confirmed',
    occurredAt: now.toISOString(),
    signature: 'trusted-test-signature',
  });
  assert.equal(confirmedBooking.status, 'confirmed');

  const stripe = new StripeSandboxService();
  const intent = stripe.create(50, 'EUR', true);
  stripe.transition(intent.id, 'processing');
  const paidIntent = stripe.transition(intent.id, 'succeeded');
  assert.equal(paidIntent.status, 'succeeded');

  const ledger = new PaymentLedgerService();
  const payment = ledger.createPayment({ bookingId: managedBooking.id, guarantorId: 'captain-1', amount: 50, currency: 'EUR' });
  ledger.acceptGuarantee(payment.id, 'captain-1', adult.category);
  const contribution = ledger.assignContribution(payment.id, 'youth-player', 25);
  const reported = ledger.reportDirectPayment(contribution.id, 'captain-1');
  assert.equal(reported.source, 'captain_reported');

  const disputes = new DisputeService();
  const dispute = disputes.open({
    contributionId: contribution.id,
    participantId: 'youth-player',
    captainId: 'captain-1',
    reason: 'Seeded dispute for end-to-end coverage',
    reviewDeadline: '2026-06-25T00:00:00.000Z',
  });
  assert.equal(disputes.resolve(dispute.id, 'captain-1', false).status, 'resolved_unpaid');
  assert.equal(ledger.getPayment(payment.id)?.bookingStatus, 'confirmed');

  const attendance = new AttendanceService();
  attendance.request(challenge.id, 'captain-1', ['captain-1', 'youth-player'], 'captain-1');
  attendance.respond(challenge.id, 'captain-1', 'confirmed');
  attendance.markNoShow(challenge.id, 'captain-1', 'youth-player', 'captain-1');
  const completion = attendance.complete(challenge.id, 'captain-1', 'captain-1');
  assert.equal(completion.name, 'match.completed');
  challenge = challenges.transition(challenge.id, 'completed', challenge.version);

  const analytics = new AnalyticsService();
  analytics.record('challenge.published', { aggregateType: 'match', aggregateId: challenge.id, aggregateVersion: 2 }, {}, adult.category);
  analytics.record('opponent.agreed', { aggregateType: 'match', aggregateId: challenge.id, aggregateVersion: 4 }, {}, adult.category);
  analytics.record('booking.provider_confirmed', { aggregateType: 'booking', aggregateId: managedBooking.id, aggregateVersion: 1 }, {}, adult.category);
  analytics.record('payment.completed', { aggregateType: 'payment', aggregateId: payment.id, aggregateVersion: 1 }, {}, adult.category);
  analytics.record('attendance.no_show', { aggregateType: 'match', aggregateId: challenge.id, aggregateVersion: 7 }, {}, youth.category);
  analytics.record('match.completed', { aggregateType: 'match', aggregateId: challenge.id, aggregateVersion: challenge.version }, {}, adult.category);
  assert.equal(analytics.forAggregate('match', challenge.id).length, 4);

  const failedBooking = await booking.reserve({
    id: 'booking-failed',
    matchId: challenge.id,
    venueId: 'PlayArena Lisbon',
    providerSlotId: 'slot-failed',
    idempotencyKey: 'failed-booking-key',
    expiresAt: '2026-06-20T14:00:00.000Z',
  });
  const failed = await booking.applyProviderEvent(failedBooking.id, {
    eventId: 'provider-event-failed',
    providerReference: failedBooking.providerReference!,
    status: 'failed',
    occurredAt: now.toISOString(),
    signature: 'trusted-test-signature',
  });
  assert.equal(failed.status, 'failed');

  const failedIntent = stripe.create(50, 'EUR', true);
  assert.equal(stripe.transition(failedIntent.id, 'failed').status, 'failed');
  assert.notEqual(failed.status, 'confirmed');
  assert.notEqual(stripe.get(failedIntent.id)?.status, 'succeeded');
});
