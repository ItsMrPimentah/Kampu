import { createHmac, timingSafeEqual } from 'node:crypto';
import type { PaymentStatus } from './ledger.service';

export interface StripeWebhook {
  eventId: string;
  intentId: string;
  status: PaymentStatus;
  occurredAt: string;
  signature: string;
}

export interface ReconciliationRecord {
  eventId: string;
  intentId: string;
  status: PaymentStatus;
  processedAt: string;
}

export class StripeWebhookError extends Error {}

export class StripeWebhookService {
  private readonly processed = new Set<string>();
  private readonly reconciliation: ReconciliationRecord[] = [];

  constructor(private readonly secret = 'stripe-sandbox-webhook-secret') {}

  async handle(event: StripeWebhook): Promise<{ processed: boolean; record?: ReconciliationRecord }> {
    if (!this.verify(event)) throw new StripeWebhookError('Invalid Stripe webhook signature');
    if (this.processed.has(event.eventId)) return { processed: false };
    this.processed.add(event.eventId);
    const record: ReconciliationRecord = { eventId: event.eventId, intentId: event.intentId, status: event.status, processedAt: new Date().toISOString() };
    this.reconciliation.push(record);
    return { processed: true, record };
  }

  sign(event: Omit<StripeWebhook, 'signature'>): string { return createHmac('sha256', this.secret).update(`${event.eventId}:${event.intentId}:${event.status}:${event.occurredAt}`).digest('hex'); }
  records(): ReconciliationRecord[] { return [...this.reconciliation]; }
  private verify(event: StripeWebhook): boolean { const expected = Buffer.from(this.sign({ eventId: event.eventId, intentId: event.intentId, status: event.status, occurredAt: event.occurredAt })); const actual = Buffer.from(event.signature); return expected.length === actual.length && timingSafeEqual(expected, actual); }
}
