import { Injectable } from '@nestjs/common';
import { AnalyticsService, type AnalyticsEventRecord } from './analytics.service';

export interface OperatorMetricsQuery {
  analyticsConsentGranted: boolean;
  includeYouthAggregate: boolean;
}

export interface OperatorMetrics {
  consentRequired: boolean;
  published: number;
  agreed: number;
  booked: number;
  funded: number;
  attended: number;
  completed: number;
  cancellations: number;
  bookingFailures: number;
  paymentFailures: number;
  refunds: number;
  disputes: number;
  captainReportedContributions: number;
  noShows: number;
}

@Injectable()
export class OperatorMetricsService {
  constructor(private readonly analytics: AnalyticsService) {}

  summarize(query: OperatorMetricsQuery): OperatorMetrics {
    const empty = (): OperatorMetrics => ({
      consentRequired: !query.analyticsConsentGranted,
      published: 0,
      agreed: 0,
      booked: 0,
      funded: 0,
      attended: 0,
      completed: 0,
      cancellations: 0,
      bookingFailures: 0,
      paymentFailures: 0,
      refunds: 0,
      disputes: 0,
      captainReportedContributions: 0,
      noShows: 0,
    });

    if (!query.analyticsConsentGranted) return empty();

    const metrics = empty();
    const events = this.analytics.all().filter((event) => this.isAllowed(event, query.includeYouthAggregate));
    for (const event of events) {
      switch (event.name) {
        case 'challenge.published': metrics.published += 1; break;
        case 'opponent.agreed':
        case 'schedule.agreed': metrics.agreed += 1; break;
        case 'booking.provider_confirmed': metrics.booked += 1; break;
        case 'payment.completed': metrics.funded += 1; break;
        case 'attendance.confirmed': metrics.attended += 1; break;
        case 'match.completed': metrics.completed += 1; break;
        case 'match.cancelled': metrics.cancellations += 1; break;
        case 'booking.failed': metrics.bookingFailures += 1; break;
        case 'payment.failed': metrics.paymentFailures += 1; break;
        case 'payment.refunded': metrics.refunds += 1; break;
        case 'dispute.opened':
        case 'dispute.escalated': metrics.disputes += 1; break;
        case 'contribution.captain_reported': metrics.captainReportedContributions += 1; break;
        case 'attendance.no_show': metrics.noShows += 1; break;
        case 'booking.declared':
          break;
      }
    }
    return metrics;
  }

  private isAllowed(event: AnalyticsEventRecord, includeYouthAggregate: boolean): boolean {
    if (event.eligibilityCategory === 'adult') return true;
    if (event.eligibilityCategory === 'youth') return includeYouthAggregate;
    return false;
  }
}
