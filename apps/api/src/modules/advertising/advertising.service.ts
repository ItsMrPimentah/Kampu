import { Injectable } from '@nestjs/common';
import type { EligibilityCategory } from '../identity/eligibility';

export type AdvertisingSurface =
  | 'home'
  | 'discovery'
  | 'profile'
  | 'match_feed'
  | 'booking_checkout'
  | 'payment_confirmation'
  | 'challenge_negotiation'
  | 'challenge_confirmation'
  | 'safety_reporting';

export interface AdvertisingRemoteConfig {
  enabled: boolean;
  policyVersion: string;
  eligibleSurfaces: AdvertisingSurface[];
  allowNonPersonalizedYouth: boolean;
  allowNonPersonalizedUnknown: boolean;
  allowNonPersonalizedAdults: boolean;
  allowPersonalizedAdults: boolean;
}

export interface AdvertisingConsent {
  userId: string;
  granted: boolean;
  policyVersion: string;
  recordedAt: string;
}

export interface AdvertisingDecision {
  requestAds: boolean;
  personalized: boolean;
  reason:
    | 'configuration_unavailable'
    | 'disabled'
    | 'critical_workflow'
    | 'surface_not_eligible'
    | 'youth_restricted'
    | 'age_unknown'
    | 'consent_required'
    | 'eligible';
  policyVersion?: string;
}

const criticalSurfaces = new Set<AdvertisingSurface>([
  'booking_checkout',
  'payment_confirmation',
  'challenge_negotiation',
  'challenge_confirmation',
  'safety_reporting',
]);

@Injectable()
export class AdvertisingPolicyService {
  private remoteConfig: AdvertisingRemoteConfig | undefined;
  private readonly consents = new Map<string, AdvertisingConsent>();

  updateRemoteConfig(config: AdvertisingRemoteConfig): AdvertisingRemoteConfig {
    if (!config.policyVersion.trim()) throw new Error('Advertising policy version is required');
    if (config.eligibleSurfaces.length === 0) throw new Error('Advertising surfaces are required');
    this.remoteConfig = { ...config, eligibleSurfaces: [...config.eligibleSurfaces] };
    return this.configuration()!;
  }

  configuration(): AdvertisingRemoteConfig | undefined {
    return this.remoteConfig && { ...this.remoteConfig, eligibleSurfaces: [...this.remoteConfig.eligibleSurfaces] };
  }

  recordConsent(userId: string, granted: boolean, policyVersion: string): AdvertisingConsent {
    if (!userId) throw new Error('Advertising consent requires a user');
    if (!policyVersion.trim()) throw new Error('Advertising consent requires a policy version');
    const consent: AdvertisingConsent = { userId, granted, policyVersion, recordedAt: new Date().toISOString() };
    this.consents.set(userId, consent);
    return consent;
  }

  consentFor(userId: string): AdvertisingConsent | undefined {
    return this.consents.get(userId);
  }

  evaluate(input: {
    userId: string;
    eligibility?: EligibilityCategory;
    surface: AdvertisingSurface;
  }): AdvertisingDecision {
    const config = this.remoteConfig;
    if (!config) return { requestAds: false, personalized: false, reason: 'configuration_unavailable' };
    if (!config.enabled) return { requestAds: false, personalized: false, reason: 'disabled', policyVersion: config.policyVersion };
    if (criticalSurfaces.has(input.surface)) return { requestAds: false, personalized: false, reason: 'critical_workflow', policyVersion: config.policyVersion };
    if (!config.eligibleSurfaces.includes(input.surface)) return { requestAds: false, personalized: false, reason: 'surface_not_eligible', policyVersion: config.policyVersion };

    if (input.eligibility === 'youth') {
      return config.allowNonPersonalizedYouth
        ? { requestAds: true, personalized: false, reason: 'eligible', policyVersion: config.policyVersion }
        : { requestAds: false, personalized: false, reason: 'youth_restricted', policyVersion: config.policyVersion };
    }

    if (!input.eligibility) {
      return config.allowNonPersonalizedUnknown
        ? { requestAds: true, personalized: false, reason: 'eligible', policyVersion: config.policyVersion }
        : { requestAds: false, personalized: false, reason: 'age_unknown', policyVersion: config.policyVersion };
    }

    const consent = this.consents.get(input.userId);
    const consentMatches = consent?.granted === true && consent.policyVersion === config.policyVersion;
    if (config.allowPersonalizedAdults && consentMatches) {
      return { requestAds: true, personalized: true, reason: 'eligible', policyVersion: config.policyVersion };
    }
    if (config.allowNonPersonalizedAdults) {
      return { requestAds: true, personalized: false, reason: 'eligible', policyVersion: config.policyVersion };
    }
    return { requestAds: false, personalized: false, reason: 'consent_required', policyVersion: config.policyVersion };
  }
}
