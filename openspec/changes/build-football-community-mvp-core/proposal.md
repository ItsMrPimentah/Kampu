# Proposal

## Why

Amateur football organization is fragmented across messaging, personal contacts, venue websites, calendars, and informal payment arrangements. This change establishes the initial Football Community product core so eligible players can form teams, organize matches, secure venues, coordinate contributions, and record successfully played matches in one trusted workflow.

The initial release must support the approved commercial scope rather than treating bookings, captain-guaranteed payments, youth participation, or advertising as later additions. The product therefore needs explicit authority, safety, booking-verification, payment-status, and dispute rules before implementation begins.

## What Changes

- Establish a 16+ account-eligibility model; users under 16 cannot register or participate, and no parent/guardian consent workflow is introduced.
- Allow eligible users aged 16+ to create and manage teams, become captains, create Team vs Team challenges, and respond to challenges.
- Provide player profiles, team membership, Open Games, applications, attendance, blocking, reporting, moderation, and youth-safety restrictions.
- Support five-a-side, seven-a-side, and eleven-a-side match formats with format-aware discovery and roster validation.
- Implement challenge negotiation and lifecycle management, including a single selected opposing team and versioned proposal history.
- Provide venue discovery, external booking declarations, and native booking through at least one pilot venue integration.
- Distinguish user-declared, captain-reported, provider-confirmed, and failed booking/payment information.
- Make the captain the booking’s financial guarantor, including for 16–17-year-old captains.
- Track participant contributions without operating a wallet or unlicensed funds-custody service. Support provider-processed payments through signed, idempotent webhooks and direct payments reported by captains.
- Allow participants to dispute captain-reported payments. The captain resolves disputes first; unresolved disputes automatically escalate to platform support.
- Keep booking payment, participant contribution, and attendance states separate.
- Integrate age-aware advertising controls: no personalized advertising for 16–17-year-olds, with consent and policy controls for eligible adults.
- Provide essential notifications, audit records, operational controls for pilot bookings, and analytics distinguishing challenges, agreements, bookings, payments, attendance, and completed matches.

## Capabilities

### New Capabilities

- `identity-and-safety`: 16+ eligibility, youth restrictions, authentication boundaries, privacy, blocking, reporting, moderation, and auditability.
- `players-and-teams`: player profiles, team creation, team membership, captain permissions, and team administration.
- `match-coordination`: football formats, Team vs Team challenges, negotiation, Open Games, applications, attendance, and match completion.
- `venue-booking`: venue discovery, external booking declarations, native booking, provider authority, connector states, and booking operations.
- `booking-payments`: captain-guaranteed booking payment, participant contribution tracking, provider webhooks, direct captain-reported payments, disputes, refunds, and reconciliation.
- `advertising-eligibility`: age-aware advertising eligibility, consent, non-personalized advertising, and remotely controlled ad behavior.
- `notifications-and-analytics`: important lifecycle notifications, audit events, operational metrics, and completed-match measurement.

### Modified Capabilities

None. The repository has no existing capability specifications.

## Impact

- New Flutter mobile application modules for onboarding, community, teams, challenges, Open Games, venues, bookings, payments, notifications, safety, advertising, and analytics.
- New NestJS backend modules and APIs for domain operations, authorization, state transitions, moderation, booking connectors, payment webhooks, notifications, and analytics.
- New PostgreSQL/PostGIS schema and Drizzle data access for profiles, teams, matches, venues, bookings, payments, disputes, consent/eligibility records, events, and audit data.
- Better Auth and server-side authorization become the identity boundary; Redis, MinIO, and background processing support caching, documents, and asynchronous work.
- At least one authorized native venue integration and a payment provider integration are required for the launch path.
- Existing project context describes NestJS/PostgreSQL rather than the Supabase direction in the product brief; the design must resolve this by treating the repository stack as the implementation baseline unless a later architecture decision changes it.
- This is a greenfield foundation: no existing application code or capability specs were found, so implementation will require project scaffolding as well as domain features.
