import type { AvailabilitySlot, BookingGatewayConnector, ProviderEvent, ReservationRequest, ReservationResult, VenueSearchRequest } from './booking-gateway';

export class FakeBookingConnector implements BookingGatewayConnector {
  readonly providerName = 'fake';
  private readonly idempotent = new Map<string, ReservationResult>();

  async searchAvailability(request: VenueSearchRequest): Promise<AvailabilitySlot[]> {
    return [{ providerSlotId: `${request.region}-${request.format}`, startsAt: request.startsAt, endsAt: request.startsAt, venueName: 'Fake Pitch' }];
  }

  async createReservation(request: ReservationRequest): Promise<ReservationResult> {
    const previous = this.idempotent.get(request.idempotencyKey);
    if (previous) return previous;
    const result: ReservationResult = { providerReference: `fake-${request.providerSlotId}`, status: 'pending_provider_confirmation', slot: { providerSlotId: request.providerSlotId, startsAt: new Date().toISOString(), endsAt: new Date().toISOString(), venueName: request.venueId } };
    this.idempotent.set(request.idempotencyKey, result);
    return result;
  }

  async handleProviderEvent(event: ProviderEvent): Promise<ReservationResult> {
    return { providerReference: event.providerReference, status: event.status === 'confirmed' ? 'confirmed' : 'failed', slot: { providerSlotId: event.providerReference, startsAt: event.occurredAt, endsAt: event.occurredAt, venueName: 'Fake Pitch' } };
  }

  async cancel(providerReference: string, idempotencyKey: string): Promise<ReservationResult> {
    return { providerReference, status: 'failed', slot: { providerSlotId: idempotencyKey, startsAt: new Date().toISOString(), endsAt: new Date().toISOString(), venueName: 'Fake Pitch' } };
  }

  async refund(providerReference: string, _amount: number, idempotencyKey: string): Promise<ReservationResult> {
    return { providerReference, status: 'failed', slot: { providerSlotId: idempotencyKey, startsAt: new Date().toISOString(), endsAt: new Date().toISOString(), venueName: 'Fake Pitch' } };
  }

  async health(): Promise<{ healthy: boolean; checkedAt: string }> { return { healthy: true, checkedAt: new Date().toISOString() }; }
}
