import type { EligibilityCategory } from '../identity/eligibility';
import { formatConfig, type FootballFormat } from '../teams/formats';

export type DiscoveryKind = 'challenge' | 'open_game';

export interface DiscoveryItem {
  id: string;
  kind: DiscoveryKind;
  format: FootballFormat;
  region: string;
  skillLevel?: string;
  availableCapacity: number;
  requiredPositions: string[];
  hostEligibility: EligibilityCategory;
  scheduledAt?: string;
}

export interface DiscoveryQuery {
  viewerEligibility: EligibilityCategory;
  region?: string;
  format?: string;
  skillLevel?: string;
  kind?: DiscoveryKind;
  minCapacity?: number;
}

export interface DiscoveryProjection extends Omit<DiscoveryItem, 'hostEligibility'> {
  locationPrecision: 'approximate_region';
  communicationContext: 'team_or_match_only';
}

export class DiscoveryService {
  private readonly items: DiscoveryItem[] = [];

  add(item: Omit<DiscoveryItem, 'format'> & { format: string }): void {
    formatConfig(item.format);
    this.items.push({ ...item, format: item.format as FootballFormat });
  }

  search(query: DiscoveryQuery): DiscoveryProjection[] {
    const minCapacity = query.minCapacity ?? 1;
    return this.items
      .filter((item) => item.availableCapacity >= minCapacity)
      .filter((item) => !query.region || item.region === query.region)
      .filter((item) => !query.format || item.format === query.format)
      .filter((item) => !query.skillLevel || item.skillLevel === query.skillLevel)
      .filter((item) => !query.kind || item.kind === query.kind)
      .filter((item) => !(query.viewerEligibility === 'adult' && item.hostEligibility === 'youth'))
      .map(({ hostEligibility: _hostEligibility, ...item }) => ({
        ...item,
        locationPrecision: 'approximate_region' as const,
        communicationContext: 'team_or_match_only' as const,
      }));
  }
}
