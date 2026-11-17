import { randomUUID } from 'node:crypto';

export type DisputeStatus = 'captain_review' | 'escalated' | 'resolved_paid' | 'resolved_unpaid';
export interface PaymentDispute { id: string; contributionId: string; participantId: string; captainId: string; reason: string; status: DisputeStatus; reviewDeadline: string; audit: Array<{ action: string; actorId: string; at: string }>; }
export class DisputeError extends Error {}

export class DisputeService {
  private readonly disputes = new Map<string, PaymentDispute>();
  open(input: { contributionId: string; participantId: string; captainId: string; reason: string; reviewDeadline: string }): PaymentDispute {
    const dispute: PaymentDispute = { id: randomUUID(), ...input, status: 'captain_review', audit: [{ action: 'opened', actorId: input.participantId, at: new Date().toISOString() }] };
    this.disputes.set(dispute.id, dispute); return dispute;
  }
  resolve(id: string, captainId: string, paid: boolean): PaymentDispute { const dispute = this.require(id); if (dispute.captainId !== captainId || dispute.status !== 'captain_review') throw new DisputeError('Captain review is required'); dispute.status = paid ? 'resolved_paid' : 'resolved_unpaid'; dispute.audit.push({ action: dispute.status, actorId: captainId, at: new Date().toISOString() }); return dispute; }
  escalate(id: string, actorId: string, now = new Date()): PaymentDispute { const dispute = this.require(id); if (dispute.status !== 'captain_review') return dispute; if (actorId !== dispute.participantId && Date.parse(dispute.reviewDeadline) > now.getTime()) throw new DisputeError('Review deadline has not expired'); dispute.status = 'escalated'; dispute.audit.push({ action: 'escalated', actorId, at: new Date().toISOString() }); return dispute; }
  get(id: string): PaymentDispute | undefined { return this.disputes.get(id); }
  private require(id: string): PaymentDispute { const dispute = this.disputes.get(id); if (!dispute) throw new DisputeError('Dispute not found'); return dispute; }
}
