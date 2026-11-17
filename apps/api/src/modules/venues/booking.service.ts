import type { BookingGatewayConnector, ProviderEvent, ReservationResult } from './booking-gateway';

export interface ManagedBooking {
  id: string;
  matchId: string;
  venueId: string;
  status: ReservationResult['status'];
  providerReference?: string;
  providerEvents: string[];
  idempotencyKey: string;
  expiresAt: string;
}

export class BookingLifecycleError extends Error {}

export class BookingService {
  private readonly bookings = new Map<string, ManagedBooking>();

  constructor(private readonly connector: BookingGatewayConnector) {}

  async reserve(input: { id: string; matchId: string; venueId: string; providerSlotId: string; idempotencyKey: string; expiresAt: string }): Promise<ManagedBooking> {
    const existing = [...this.bookings.values()].find((booking) => booking.idempotencyKey === input.idempotencyKey);
    if (existing) return existing;
    const result = await this.connector.createReservation({ venueId: input.venueId, providerSlotId: input.providerSlotId, idempotencyKey: input.idempotencyKey });
    const booking: ManagedBooking = { id: input.id, matchId: input.matchId, venueId: input.venueId, status: result.status, providerReference: result.providerReference, providerEvents: [], idempotencyKey: input.idempotencyKey, expiresAt: input.expiresAt };
    this.bookings.set(booking.id, booking);
    return booking;
  }

  async applyProviderEvent(id: string, event: ProviderEvent): Promise<ManagedBooking> {
    const booking = this.require(id);
    if (booking.providerEvents.includes(event.eventId)) return booking;
    const result = await this.connector.handleProviderEvent(event);
    booking.providerEvents.push(event.eventId);
    booking.status = result.status;
    booking.providerReference = result.providerReference;
    return booking;
  }

  confirmManually(_id: string): never { throw new BookingLifecycleError('Only an authorized provider or venue workflow can confirm a booking'); }

  expire(id: string, now = new Date()): ManagedBooking {
    const booking = this.require(id);
    if (booking.status === 'pending_provider_confirmation' && Date.parse(booking.expiresAt) <= now.getTime()) booking.status = 'failed';
    return booking;
  }

  get(id: string): ManagedBooking | undefined { return this.bookings.get(id); }
  private require(id: string): ManagedBooking { const booking = this.bookings.get(id); if (!booking) throw new BookingLifecycleError('Booking not found'); return booking; }
}
