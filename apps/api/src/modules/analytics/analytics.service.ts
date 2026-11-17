import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import type { EligibilityCategory } from '../identity/eligibility';
import type { DomainEvent } from '../../shared/domain-events';

export type AnalyticsEventName =
  | 'challenge.published'
  | 'opponent.agreed'
  | 'schedule.agreed'
  | 'booking.declared'
  | 'booking.provider_confirmed'
  | 'payment.completed'
  | 'attendance.confirmed'
  | 'match.completed'
  | 'match.cancelled'
  | 'attendance.no_show'
  | 'booking.failed'
  | 'booking.cancelled'
  | 'payment.failed'
  | 'payment.refunded'
  | 'contribution.captain_reported'
  | 'dispute.opened'
  | 'dispute.escalated';

export interface AnalyticsEventRecord {
  id: string;
  name: AnalyticsEventName;
  aggregateType: string;
  aggregateId: string;
  aggregateVersion: number;
  payload: Record<string, unknown>;
  eligibilityCategory?: EligibilityCategory;
  occurredAt: string;
}

export interface AnalyticsAggregateSource {
  aggregateType: string;
  aggregateId: string;
  aggregateVersion: number;
}

@Injectable()
export class AnalyticsService {
  private readonly events = new Map<string, AnalyticsEventRecord>();

  record(
    name: AnalyticsEventName,
    source: AnalyticsAggregateSource,
    payload: Record<string, unknown> = {},
    eligibilityCategory?: EligibilityCategory,
  ): AnalyticsEventRecord {
    if (!source.aggregateType || !source.aggregateId || source.aggregateVersion < 1 || !Number.isInteger(source.aggregateVersion)) {
      throw new Error('Analytics events require a valid source aggregate and version');
    }

    const key = this.key(name, source);
    const existing = this.events.get(key);
    if (existing) return existing;

    const event: AnalyticsEventRecord = {
      id: randomUUID(),
      name,
      ...source,
      payload: { ...payload },
      eligibilityCategory,
      occurredAt: new Date().toISOString(),
    };
    this.events.set(key, event);
    return event;
  }

  recordDomainEvent(
    name: AnalyticsEventName,
    event: DomainEvent<Record<string, unknown>>,
    payload: Record<string, unknown> = {},
    eligibilityCategory?: EligibilityCategory,
  ): AnalyticsEventRecord {
    return this.record(name, event, payload, eligibilityCategory);
  }

  all(): AnalyticsEventRecord[] {
    return [...this.events.values()];
  }

  forAggregate(aggregateType: string, aggregateId: string): AnalyticsEventRecord[] {
    return this.all().filter((event) => event.aggregateType === aggregateType && event.aggregateId === aggregateId);
  }

  private key(name: AnalyticsEventName, source: AnalyticsAggregateSource): string {
    return `${name}:${source.aggregateType}:${source.aggregateId}:${source.aggregateVersion}`;
  }
}
