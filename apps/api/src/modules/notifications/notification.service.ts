import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import type { DomainEvent } from '../../shared/domain-events';

export type NotificationEventType =
  | 'challenge.proposed'
  | 'challenge.counteroffered'
  | 'challenge.approved'
  | 'challenge.material_changed'
  | 'booking.confirmed'
  | 'booking.failed'
  | 'payment.failed'
  | 'dispute.escalated'
  | 'match.cancelled'
  | 'attendance.requested'
  | 'attendance.no_show';

export type NotificationEligibility = 'youth' | 'adult' | 'unknown';

export interface NotificationRecipient {
  userId: string;
  eligibility?: NotificationEligibility;
  canViewPaymentDetails?: boolean;
  canViewPreciseVenue?: boolean;
}

export interface NotificationRecord {
  id: string;
  userId: string;
  type: NotificationEventType;
  title: string;
  body: string;
  payload: Record<string, unknown>;
  sourceEventId: string;
  deliveredAt: string;
}

interface NotificationTemplate {
  title: string;
  body: (context: NotificationContext) => string;
}

interface NotificationContext {
  event: DomainEvent<Record<string, unknown>>;
  recipient: NotificationRecipient;
  payload: Record<string, unknown>;
}

const templates: Record<NotificationEventType, NotificationTemplate> = {
  'challenge.proposed': {
    title: 'New challenge proposal',
    body: ({ payload }) => `Review the new challenge proposal for ${payload.matchLabel}.`,
  },
  'challenge.counteroffered': {
    title: 'Counteroffer received',
    body: ({ payload }) => `Review the changed conditions for ${payload.matchLabel}.`,
  },
  'challenge.approved': {
    title: 'Challenge approved',
    body: ({ payload }) => `${payload.matchLabel} was approved by the other captain.`,
  },
  'challenge.material_changed': {
    title: 'Challenge conditions changed',
    body: ({ payload }) => `The conditions for ${payload.matchLabel} changed. Review them before confirmation.`,
  },
  'booking.confirmed': {
    title: 'Venue booking confirmed',
    body: ({ payload }) => `The venue booking for ${payload.matchLabel} is confirmed.`,
  },
  'booking.failed': {
    title: 'Booking failed',
    body: ({ payload }) => `The booking for ${payload.matchLabel} could not be confirmed. Choose another slot or declare an external booking.`,
  },
  'payment.failed': {
    title: 'Payment failed',
    body: ({ payload }) => `The payment for ${payload.matchLabel} failed. Review the payment status and next action.`,
  },
  'dispute.escalated': {
    title: 'Payment dispute escalated',
    body: ({ payload }) => `The payment dispute for ${payload.matchLabel} was escalated to support.`,
  },
  'match.cancelled': {
    title: 'Match cancelled',
    body: ({ payload }) => `${payload.matchLabel} was cancelled.`,
  },
  'attendance.requested': {
    title: 'Attendance requested',
    body: ({ payload }) => `Please confirm whether you can attend ${payload.matchLabel}.`,
  },
  'attendance.no_show': {
    title: 'No-show recorded',
    body: ({ payload }) => `A no-show was recorded for ${payload.matchLabel}.`,
  },
};

@Injectable()
export class NotificationService {
  private readonly records = new Map<string, NotificationRecord>();
  private readonly deliveredKeys = new Set<string>();

  deliverFromOutbox(
    event: DomainEvent<Record<string, unknown>>,
    recipients: NotificationRecipient[],
  ): NotificationRecord[] {
    const template = templates[event.type as NotificationEventType];
    if (!template) return [];

    const delivered: NotificationRecord[] = [];
    for (const recipient of recipients) {
      if (!recipient.userId) continue;
      const deliveryKey = `${event.id}:${recipient.userId}`;
      if (this.deliveredKeys.has(deliveryKey)) continue;

      const payload = safeNotificationPayload(event, recipient);
      const context: NotificationContext = { event, recipient, payload };
      const record: NotificationRecord = {
        id: randomUUID(),
        userId: recipient.userId,
        type: event.type as NotificationEventType,
        title: template.title,
        body: template.body(context),
        payload,
        sourceEventId: event.id,
        deliveredAt: new Date().toISOString(),
      };

      this.records.set(record.id, record);
      this.deliveredKeys.add(deliveryKey);
      delivered.push(record);
    }
    return delivered;
  }

  forUser(userId: string): NotificationRecord[] {
    return [...this.records.values()].filter((record) => record.userId === userId);
  }
}

function safeNotificationPayload(
  event: DomainEvent<Record<string, unknown>>,
  recipient: NotificationRecipient,
): Record<string, unknown> {
  const source = event.payload ?? {};
  const payload: Record<string, unknown> = {
    aggregateId: event.aggregateId,
    aggregateType: event.aggregateType,
    eventType: event.type,
    matchLabel: stringValue(source.matchLabel) ?? 'your match',
  };

  copyString(source, payload, 'format');
  copyString(source, payload, 'status');
  copyString(source, payload, 'timeLabel');
  copyString(source, payload, 'region');
  copyString(source, payload, 'approximateLocation');

  if (recipient.eligibility !== 'youth' && recipient.canViewPreciseVenue) {
    copyString(source, payload, 'venueName');
  }

  if (recipient.canViewPaymentDetails) {
    copyString(source, payload, 'amount');
    copyString(source, payload, 'currency');
    copyString(source, payload, 'providerReference');
  }

  return payload;
}

function copyString(source: Record<string, unknown>, target: Record<string, unknown>, key: string): void {
  const value = stringValue(source[key]);
  if (value !== undefined) target[key] = value;
}

function stringValue(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim() ? value.trim() : undefined;
}
