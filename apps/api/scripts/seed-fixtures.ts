export const seedTimestamp = '2026-01-01T00:00:00.000Z';

export const seedIds = {
  adultCaptain: '00000000-0000-4000-8000-000000000001',
  youthPlayer: '00000000-0000-4000-8000-000000000002',
  operator: '00000000-0000-4000-8000-000000000003',
  lisbonTeam: '00000000-0000-4000-8000-000000000011',
  setubalTeam: '00000000-0000-4000-8000-000000000012',
  match: '00000000-0000-4000-8000-000000000021',
  lisbonVenue: '00000000-0000-4000-8000-000000000031',
  setubalVenue: '00000000-0000-4000-8000-000000000032',
  booking: '00000000-0000-4000-8000-000000000041',
  paymentOrder: '00000000-0000-4000-8000-000000000051',
  contribution: '00000000-0000-4000-8000-000000000061',
  dispute: '00000000-0000-4000-8000-000000000071',
  outboxEvent: '00000000-0000-4000-8000-000000000081',
  analyticsEvent: '00000000-0000-4000-8000-000000000091',
  notification: '00000000-0000-4000-8000-000000000101',
  audit: '00000000-0000-4000-8000-000000000111',
} as const;

export const seedFixtures = {
  users: [
    { id: seedIds.adultCaptain, externalAuthId: 'seed:adult-captain', dateOfBirth: '1990-04-12', eligibility: 'adult' as const },
    { id: seedIds.youthPlayer, externalAuthId: 'seed:youth-player', dateOfBirth: '2008-06-24', eligibility: 'youth' as const },
    { id: seedIds.operator, externalAuthId: 'seed:operator', dateOfBirth: '1985-09-10', eligibility: 'adult' as const },
  ],
  teams: [
    { id: seedIds.lisbonTeam, name: 'Seed Lisbon Falcons', region: 'Lisbon', formats: ['5v5', '7v7'] },
    { id: seedIds.setubalTeam, name: 'Seed Setúbal Strikers', region: 'Setúbal', formats: ['5v5'] },
  ],
  venues: [
    { id: seedIds.lisbonVenue, name: 'PlayArena Lisbon', region: 'Lisbon', latitude: 38.748, longitude: -9.150, formats: ['5v5', '7v7'], validUntil: '2027-01-01T00:00:00.000Z' },
    { id: seedIds.setubalVenue, name: 'PlayArena Setúbal', region: 'Setúbal', latitude: 38.524, longitude: -8.893, formats: ['5v5'], validUntil: '2027-01-01T00:00:00.000Z' },
  ],
  stripeSandboxEvent: {
    id: 'evt_seed_stripe_payment_succeeded',
    providerReference: 'pi_seed_sandbox_payment',
    eventType: 'stripe.sandbox.payment_succeeded',
  },
} as const;
