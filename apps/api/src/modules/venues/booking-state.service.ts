export type BookingState = 'not_requested' | 'searching' | 'slot_selected' | 'pending_payment' | 'pending_provider_confirmation' | 'externally_declared' | 'confirmed' | 'failed' | 'cancelled' | 'refunded';

export interface BookingStateRecord {
  id: string;
  matchId: string;
  challengeStatus: string;
  bookingStatus: BookingState;
  providerConfirmed: boolean;
  source: 'user_declared' | 'provider' | 'unavailable';
  updatedAt: string;
}

export class BookingStateError extends Error {}

export class BookingStateService {
  private readonly bookings = new Map<string, BookingStateRecord>();

  create(id: string, matchId: string, challengeStatus: string): BookingStateRecord {
    const booking: BookingStateRecord = { id, matchId, challengeStatus, bookingStatus: 'not_requested', providerConfirmed: false, source: 'unavailable', updatedAt: new Date().toISOString() };
    this.bookings.set(id, booking);
    return booking;
  }

  transition(id: string, status: BookingState, source: BookingStateRecord['source'] = 'unavailable', trustedProvider = false): BookingStateRecord {
    const booking = this.bookings.get(id);
    if (!booking) throw new BookingStateError('Booking not found');
    if (status === 'confirmed' && (!trustedProvider || source !== 'provider')) throw new BookingStateError('Provider confirmation requires a trusted provider response');
    booking.bookingStatus = status;
    booking.source = source;
    booking.providerConfirmed = status === 'confirmed' && trustedProvider && source === 'provider';
    booking.updatedAt = new Date().toISOString();
    return booking;
  }

  get(id: string): BookingStateRecord | undefined { return this.bookings.get(id); }
}
