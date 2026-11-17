import { Module } from '@nestjs/common';
import { PaymentLedgerService } from './ledger.service';
import { StripeSandboxService } from './stripe-sandbox.service';
import { StripeWebhookService } from './stripe-webhook.service';
import { DisputeService } from './dispute.service';

@Module({
  providers: [PaymentLedgerService, StripeSandboxService, StripeWebhookService, DisputeService],
  exports: [PaymentLedgerService, StripeSandboxService, StripeWebhookService, DisputeService],
})
export class PaymentsModule {}
