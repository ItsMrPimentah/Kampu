import { randomUUID } from 'node:crypto';

export type PaymentStatus = 'pending' | 'processing' | 'succeeded' | 'failed' | 'cancelled' | 'refunded' | 'disputed' | 'outstanding';
export type PaymentSource = 'provider' | 'captain_reported';

export interface BookingPayment {
  id: string;
  bookingId: string;
  guarantorId: string;
  amount: number;
  currency: string;
  status: PaymentStatus;
  provider?: string;
  providerReference?: string;
  captainGuaranteeAccepted: boolean;
  bookingStatus: string;
  attendanceStatus: string;
}

export interface ParticipantContribution {
  id: string;
  paymentId: string;
  participantId: string;
  amount: number;
  currency: string;
  status: PaymentStatus;
  source?: PaymentSource;
  providerReference?: string;
  reportedBy?: string;
}

export class LedgerError extends Error {}

export class PaymentLedgerService {
  private readonly payments = new Map<string, BookingPayment>();
  private readonly contributions = new Map<string, ParticipantContribution>();

  createPayment(input: { bookingId: string; guarantorId: string; amount: number; currency: string; bookingStatus?: string; attendanceStatus?: string }): BookingPayment {
    if (input.amount <= 0) throw new LedgerError('Payment amount must be positive');
    const payment: BookingPayment = { id: randomUUID(), bookingId: input.bookingId, guarantorId: input.guarantorId, amount: input.amount, currency: input.currency, status: 'pending', captainGuaranteeAccepted: false, bookingStatus: input.bookingStatus ?? 'confirmed', attendanceStatus: input.attendanceStatus ?? 'pending' };
    this.payments.set(payment.id, payment);
    return payment;
  }

  acceptGuarantee(paymentId: string, captainId: string, captainEligibility: 'youth' | 'adult'): BookingPayment {
    const payment = this.requirePayment(paymentId);
    if (payment.guarantorId !== captainId || !captainEligibility) throw new LedgerError('Eligible captain guarantor is required');
    payment.captainGuaranteeAccepted = true;
    return payment;
  }

  assignContribution(paymentId: string, participantId: string, amount: number): ParticipantContribution {
    const payment = this.requirePayment(paymentId);
    if (amount <= 0) throw new LedgerError('Contribution amount must be positive');
    const assigned = [...this.contributions.values()].filter((item) => item.paymentId === paymentId).reduce((sum, item) => sum + item.amount, 0);
    if (assigned + amount > payment.amount + 0.001) throw new LedgerError('Assigned contributions exceed the collectable amount');
    const contribution: ParticipantContribution = { id: randomUUID(), paymentId, participantId, amount, currency: payment.currency, status: 'outstanding' };
    this.contributions.set(contribution.id, contribution);
    return contribution;
  }

  reconcileAssignments(paymentId: string, fees = 0): boolean {
    const payment = this.requirePayment(paymentId);
    const expected = Math.round((payment.amount - fees) * 100) / 100;
    const assigned = Math.round([...this.contributions.values()].filter((item) => item.paymentId === paymentId).reduce((sum, item) => sum + item.amount, 0) * 100) / 100;
    if (assigned !== expected) throw new LedgerError(`Assigned contributions ${assigned.toFixed(2)} do not equal collectable amount ${expected.toFixed(2)}`);
    return true;
  }

  reportDirectPayment(contributionId: string, captainId: string): ParticipantContribution {
    const contribution = this.requireContribution(contributionId);
    const payment = this.requirePayment(contribution.paymentId);
    if (payment.guarantorId !== captainId) throw new LedgerError('Only the guarantor can report a direct payment');
    contribution.status = 'succeeded';
    contribution.source = 'captain_reported';
    contribution.reportedBy = captainId;
    return contribution;
  }

  getPayment(id: string): BookingPayment | undefined { return this.payments.get(id); }
  getContribution(id: string): ParticipantContribution | undefined { return this.contributions.get(id); }
  private requirePayment(id: string): BookingPayment { const payment = this.payments.get(id); if (!payment) throw new LedgerError('Payment not found'); return payment; }
  private requireContribution(id: string): ParticipantContribution { const contribution = this.contributions.get(id); if (!contribution) throw new LedgerError('Contribution not found'); return contribution; }
}
