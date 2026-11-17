import { createHmac, timingSafeEqual } from 'node:crypto';
import type { BookingGatewayConnector, ProviderEvent, ReservationRequest, ReservationResult, VenueSearchRequest, AvailabilitySlot } from './booking-gateway';

const pilotRegions = new Set(['Lisbon', 'Setúbal']);
const pilotFormats = new Set(['5v5', '7v7', '11v11', 'futsal', 'futevoley_2v2']);

export class PlayArenaConnector implements BookingGatewayConnector {
  readonly providerName = 'PlayArena';
  private readonly idempotent = new Map<string, ReservationResult>();

  constructor(private readonly webhookSecret = 'playarena-sandbox-secret') {}

  async searchAvailability(request: VenueSearchRequest): Promise<AvailabilitySlot[]> {
    if (!pilotRegions.has(request.region) || !pilotFormats.has(request.format)) return [];
    return [{ providerSlotId: `playarena-${request.region}-${request.format}`, startsAt: request.startsAt, endsAt: request.startsAt, venueName: `PlayArena ${request.region}`, providerReference: 'playarena-sandbox' }];
  }

  async createReservation(request: ReservationRequest): Promise<ReservationResult> {
    const existing = this.idempotent.get(request.idempotencyKey);
    if (existing) return existing;
    const result: ReservationResult = {
      providerReference: `pa-${request.providerSlotId}`,
      status: 'pending_provider_confirmation',
      slot: { providerSlotId: request.providerSlotId, startsAt: new Date().toISOString(), endsAt: new Date().toISOString(), venueName: request.venueId, providerReference: 'playarena-sandbox' },
    };
    this.idempotent.set(request.idempotencyKey, result);
    return result;
  }

  async handleProviderEvent(event: ProviderEvent): Promise<ReservationResult> {
    if (!this.verify(event)) throw new Error('Invalid PlayArena provider signature');
    return { providerReference: event.providerReference, status: event.status === 'confirmed' ? 'confirmed' : event.status === 'cancelled' ? 'cancelled' : event.status === 'refunded' ? 'refunded' : 'failed', slot: { providerSlotId: event.providerReference, startsAt: event.occurredAt, endsAt: event.occurredAt, venueName: 'PlayArena' } };
  }

  async cancel(providerReference: string, idempotencyKey: string): Promise<ReservationResult> { return { providerReference, status: 'cancelled', slot: this.slot(providerReference, idempotencyKey) }; }
  async refund(providerReference: string, _amount: number, idempotencyKey: string): Promise<ReservationResult> { return { providerReference, status: 'refunded', slot: this.slot(providerReference, idempotencyKey) }; }
  async health(): Promise<{ healthy: boolean; checkedAt: string }> { return { healthy: true, checkedAt: new Date().toISOString() }; }

  sign(event: Omit<ProviderEvent, 'signature'>): string {
    return createHmac('sha256', this.webhookSecret).update(this.payload(event)).digest('hex');
  }

  private verify(event: ProviderEvent): boolean {
    const expected = Buffer.from(this.sign({ eventId: event.eventId, providerReference: event.providerReference, status: event.status, occurredAt: event.occurredAt }));
    const actual = Buffer.from(event.signature);
    return expected.length === actual.length && timingSafeEqual(expected, actual);
  }

  private payload(event: Omit<ProviderEvent, 'signature'>): string { return `${event.eventId}:${event.providerReference}:${event.status}:${event.occurredAt}`; }
  private slot(providerReference: string, id: string): AvailabilitySlot { return { providerSlotId: id, startsAt: new Date().toISOString(), endsAt: new Date().toISOString(), venueName: 'PlayArena', providerReference }; }
}
