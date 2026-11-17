import assert from 'node:assert/strict';
import test from 'node:test';
import { AdvertisingPolicyService, type AdvertisingRemoteConfig } from '../src/modules/advertising/advertising.service';

const config = (overrides: Partial<AdvertisingRemoteConfig> = {}): AdvertisingRemoteConfig => ({
  enabled: true,
  policyVersion: 'ads-v1',
  eligibleSurfaces: ['home', 'discovery'],
  allowNonPersonalizedYouth: true,
  allowNonPersonalizedUnknown: false,
  allowNonPersonalizedAdults: false,
  allowPersonalizedAdults: true,
  ...overrides,
});

test('uses conservative no-ad behavior without remote configuration', () => {
  const service = new AdvertisingPolicyService();
  assert.deepEqual(service.evaluate({ userId: 'user-1', eligibility: 'adult', surface: 'home' }), {
    requestAds: false,
    personalized: false,
    reason: 'configuration_unavailable',
  });
});

test('allows only non-personalized youth advertising when configured', () => {
  const service = new AdvertisingPolicyService();
  service.updateRemoteConfig(config());

  const decision = service.evaluate({ userId: 'youth-1', eligibility: 'youth', surface: 'discovery' });
  assert.equal(decision.requestAds, true);
  assert.equal(decision.personalized, false);
});

test('blocks unknown age unless remote policy explicitly permits non-personalized ads', () => {
  const service = new AdvertisingPolicyService();
  service.updateRemoteConfig(config());
  assert.equal(service.evaluate({ userId: 'unknown-1', surface: 'home' }).reason, 'age_unknown');

  service.updateRemoteConfig(config({ allowNonPersonalizedUnknown: true }));
  assert.deepEqual(service.evaluate({ userId: 'unknown-1', surface: 'home' }).personalized, false);
  assert.equal(service.evaluate({ userId: 'unknown-1', surface: 'home' }).requestAds, true);
});

test('requires current-version adult consent for personalized advertising', () => {
  const service = new AdvertisingPolicyService();
  service.updateRemoteConfig(config());

  assert.equal(service.evaluate({ userId: 'adult-1', eligibility: 'adult', surface: 'home' }).reason, 'consent_required');
  service.recordConsent('adult-1', true, 'ads-old');
  assert.equal(service.evaluate({ userId: 'adult-1', eligibility: 'adult', surface: 'home' }).reason, 'consent_required');
  service.recordConsent('adult-1', true, 'ads-v1');
  const decision = service.evaluate({ userId: 'adult-1', eligibility: 'adult', surface: 'home' });
  assert.equal(decision.requestAds, true);
  assert.equal(decision.personalized, true);

  service.recordConsent('adult-1', false, 'ads-v1');
  assert.equal(service.evaluate({ userId: 'adult-1', eligibility: 'adult', surface: 'home' }).requestAds, false);
});

test('never requests ads in critical workflows or disabled surfaces', () => {
  const service = new AdvertisingPolicyService();
  service.updateRemoteConfig(config({
    eligibleSurfaces: ['home', 'booking_checkout', 'payment_confirmation', 'safety_reporting'],
    allowNonPersonalizedAdults: true,
  }));

  assert.equal(service.evaluate({ userId: 'adult-1', eligibility: 'adult', surface: 'booking_checkout' }).reason, 'critical_workflow');
  assert.equal(service.evaluate({ userId: 'adult-1', eligibility: 'adult', surface: 'payment_confirmation' }).requestAds, false);
  assert.equal(service.evaluate({ userId: 'adult-1', eligibility: 'adult', surface: 'profile' }).reason, 'surface_not_eligible');

  service.updateRemoteConfig(config({ enabled: false, allowNonPersonalizedAdults: true }));
  assert.equal(service.evaluate({ userId: 'adult-1', eligibility: 'adult', surface: 'home' }).reason, 'disabled');
});
