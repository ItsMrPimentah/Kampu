import type { EligibilityCategory } from '../identity/eligibility';

export interface PlayerProfileInput {
  userId: string;
  eligibility: EligibilityCategory;
  displayName: string;
  preferredPositions: string[];
  skillLevel?: string;
  availability: Record<string, unknown>;
  approximateLocation?: { region: string; latitude?: number; longitude?: number };
}

export interface PlayerProfile extends PlayerProfileInput {
  updatedAt: string;
}

export interface ProfileViewer {
  userId: string;
  eligibility?: EligibilityCategory;
  authorizedRelationship: boolean;
}

export interface ProfileProjection {
  userId: string;
  displayName: string;
  preferredPositions: string[];
  skillLevel?: string;
  availability: Record<string, unknown>;
  approximateLocation?: { region: string };
}

export class ProfileService {
  private readonly profiles = new Map<string, PlayerProfile>();

  save(input: PlayerProfileInput): PlayerProfile {
    if (!input.userId || !input.displayName.trim()) throw new Error('Display name is required');
    if (!input.eligibility) throw new Error('Eligibility is required');
    const profile: PlayerProfile = { ...input, displayName: input.displayName.trim(), updatedAt: new Date().toISOString() };
    this.profiles.set(input.userId, profile);
    return profile;
  }

  get(userId: string): PlayerProfile | undefined {
    return this.profiles.get(userId);
  }

  project(userId: string, viewer: ProfileViewer): ProfileProjection | undefined {
    const profile = this.profiles.get(userId);
    if (!profile) return undefined;
    const isYouth = profile.eligibility === 'youth';
    const canSeeRelationshipData = viewer.userId === userId || viewer.authorizedRelationship;
    return {
      userId: profile.userId,
      displayName: profile.displayName,
      preferredPositions: profile.preferredPositions,
      skillLevel: profile.skillLevel,
      availability: canSeeRelationshipData ? profile.availability : {},
      approximateLocation: profile.approximateLocation
        ? { region: profile.approximateLocation.region }
        : undefined,
    };
  }

  discover(viewer: ProfileViewer): ProfileProjection[] {
    return [...this.profiles.values()]
      .filter((profile) => !(profile.eligibility === 'youth' && viewer.eligibility === 'adult' && !viewer.authorizedRelationship))
      .map((profile) => this.project(profile.userId, viewer)!)
      .filter(Boolean);
  }
}
