import assert from 'node:assert/strict';
import test from 'node:test';
import { PaymentLedgerService } from '../src/modules/payments/ledger.service';

test('keeps booking payment, contribution, and attendance states separate', () => {
  const service = new PaymentLedgerService();
  const payment = service.createPayment({ bookingId: 'booking-1', guarantorId: 'captain', amount: 50, currency: 'EUR', bookingStatus: 'confirmed', attendanceStatus: 'pending' });
  const contribution = service.assignContribution(payment.id, 'player-1', 25);
  assert.equal(contribution.status, 'outstanding');
  assert.equal(service.getPayment(payment.id)?.bookingStatus, 'confirmed');
  assert.equal(service.getPayment(payment.id)?.attendanceStatus, 'pending');
});

test('accepts youth captain guarantee and captain-reported contributions', () => {
  const service = new PaymentLedgerService();
  const payment = service.createPayment({ bookingId: 'booking-1', guarantorId: 'captain', amount: 50, currency: 'EUR' });
  assert.equal(service.acceptGuarantee(payment.id, 'captain', 'youth').captainGuaranteeAccepted, true);
  const contribution = service.assignContribution(payment.id, 'player-1', 25);
  assert.equal(service.reportDirectPayment(contribution.id, 'captain').source, 'captain_reported');
});

test('reconciles assigned contributions after fees and rounding', () => {
  const service = new PaymentLedgerService();
  const payment = service.createPayment({ bookingId: 'booking-2', guarantorId: 'captain', amount: 50, currency: 'EUR' });
  service.assignContribution(payment.id, 'player-1', 24.99);
  service.assignContribution(payment.id, 'player-2', 24.01);
  assert.equal(service.reconcileAssignments(payment.id, 1), true);
});
