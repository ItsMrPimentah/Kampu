import { randomUUID } from 'node:crypto';
import { formatConfig } from '../teams/formats';

export type BookingMethod = 'external' | 'native';
export type VerificationLevel = 'user_declared' | 'operator_verified' | 'provider_confirmed' | 'unavailable';

export interface Venue {
  id: string;
  name: string;
  region: 'Lisbon' | 'Setúbal';
  supportedFormats: string[];
  bookingMethod: BookingMethod;
  source: string;
  verificationLevel: VerificationLevel;
  informationUpdatedAt: string;
  informationValidUntil: string;
}

export interface VenueProjection extends Venue {
  stale: boolean;
  locationPrecision: 'venue_exact_for_authorized_participants' | 'region_only';
}

export class VenueService {
  private readonly venues = new Map<string, Venue>();

  create(input: Omit<Venue, 'id' | 'informationUpdatedAt'> & { informationUpdatedAt?: string }): Venue {
    if (!['Lisbon', 'Setúbal'].includes(input.region)) throw new Error('Venue is outside the pilot regions');
    input.supportedFormats.forEach((format) => formatConfig(format));
    if (!input.name || !input.source) throw new Error('Venue name and source are required');
    const venue: Venue = {
      ...input,
      id: randomUUID(),
      informationUpdatedAt: input.informationUpdatedAt ?? new Date().toISOString(),
    };
    this.venues.set(venue.id, venue);
    return venue;
  }

  seedPlayArena(region: 'Lisbon' | 'Setúbal', formats: string[]): Venue {
    return this.create({
      name: `PlayArena ${region}`,
      region,
      supportedFormats: formats,
      bookingMethod: 'native',
      source: 'PlayArena',
      verificationLevel: 'operator_verified',
      informationValidUntil: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
    });
  }

  search(query: { region?: 'Lisbon' | 'Setúbal'; format?: string; bookingMethod?: BookingMethod }): VenueProjection[] {
    if (query.format) formatConfig(query.format);
    return [...this.venues.values()]
      .filter((venue) => !query.region || venue.region === query.region)
      .filter((venue) => !query.format || venue.supportedFormats.includes(query.format))
      .filter((venue) => !query.bookingMethod || venue.bookingMethod === query.bookingMethod)
      .map((venue) => ({
        ...venue,
        stale: Date.parse(venue.informationValidUntil) <= Date.now(),
        locationPrecision: 'region_only' as const,
      }));
  }
}
