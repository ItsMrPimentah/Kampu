export interface VenueSearchRequest {
  region: string;
  format: string;
  startsAt: string;
}

export interface AvailabilitySlot {
  providerSlotId: string;
  startsAt: string;
  endsAt: string;
  venueName: string;
  providerReference?: string;
}

export interface ReservationRequest {
  venueId: string;
  providerSlotId: string;
  idempotencyKey: string;
}

export interface ReservationResult {
  providerReference: string;
  status: 'pending_provider_confirmation' | 'confirmed' | 'failed' | 'cancelled' | 'refunded';
  slot: AvailabilitySlot;
}

export interface ProviderEvent {
  eventId: string;
  providerReference: string;
  status: 'confirmed' | 'cancelled' | 'failed' | 'refunded';
  occurredAt: string;
  signature: string;
}

export interface BookingGatewayConnector {
  readonly providerName: string;
  searchAvailability(request: VenueSearchRequest): Promise<AvailabilitySlot[]>;
  createReservation(request: ReservationRequest): Promise<ReservationResult>;
  handleProviderEvent(event: ProviderEvent): Promise<ReservationResult>;
  cancel(providerReference: string, idempotencyKey: string): Promise<ReservationResult>;
  refund(providerReference: string, amount: number, idempotencyKey: string): Promise<ReservationResult>;
  health(): Promise<{ healthy: boolean; checkedAt: string }>;
}

export function assertConnectorContract(connector: BookingGatewayConnector): void {
  if (!connector.providerName) throw new Error('Connector providerName is required');
  for (const method of ['searchAvailability', 'createReservation', 'handleProviderEvent', 'cancel', 'refund', 'health']) {
    if (typeof connector[method as keyof BookingGatewayConnector] !== 'function') throw new Error(`Connector method ${method} is required`);
  }
}
