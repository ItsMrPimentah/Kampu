import { randomUUID } from 'node:crypto';
import type { PaymentStatus } from './ledger.service';

export interface SandboxPaymentIntent {
  id: string;
  amount: number;
  currency: string;
  status: PaymentStatus;
  provider: 'stripe_sandbox';
  providerReference: string;
  refundAmount: number;
}

export class StripeSandboxError extends Error {}

export class StripeSandboxService {
  private readonly intents = new Map<string, SandboxPaymentIntent>();

  create(amount: number, currency: string, paymentsEnabled: boolean): SandboxPaymentIntent {
    if (!paymentsEnabled) throw new StripeSandboxError('Payments feature is disabled');
    if (amount <= 0) throw new StripeSandboxError('Payment amount must be positive');
    const intent: SandboxPaymentIntent = { id: randomUUID(), amount, currency, status: 'pending', provider: 'stripe_sandbox', providerReference: `pi_test_${randomUUID()}`, refundAmount: 0 };
    this.intents.set(intent.id, intent);
    return intent;
  }

  transition(id: string, status: Exclude<PaymentStatus, 'outstanding'>): SandboxPaymentIntent {
    const intent = this.require(id);
    intent.status = status;
    return intent;
  }

  refund(id: string, amount: number): SandboxPaymentIntent {
    const intent = this.require(id);
    if (amount <= 0 || intent.refundAmount + amount > intent.amount) throw new StripeSandboxError('Refund amount exceeds payment');
    intent.refundAmount += amount;
    intent.status = 'refunded';
    return intent;
  }

  get(id: string): SandboxPaymentIntent | undefined { return this.intents.get(id); }
  private require(id: string): SandboxPaymentIntent { const intent = this.intents.get(id); if (!intent) throw new StripeSandboxError('Payment intent not found'); return intent; }
}
