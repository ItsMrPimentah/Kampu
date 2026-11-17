# Design

## Context

The repository is a greenfield project with no application code or existing capability specs. The project context establishes Flutter on mobile and NestJS, Better Auth, Drizzle, PostgreSQL/PostGIS, Redis, and MinIO on the backend. The product brief proposed Supabase, but this design uses the repository’s NestJS/PostgreSQL stack as the implementation baseline. See `proposal.md` for the product motivation and the capability deltas for observable behavior.

The release crosses identity, community, match coordination, venue authority, payments, advertising, notifications, and analytics. Those areas must remain independently stateful: agreement is not booking confirmation, a provider payment is not a participant contribution, and attendance is not payment.

## Goals / Non-Goals

**Goals:**

- Establish a modular backend and mobile foundation for the approved P0-MVP behavior.
- Enforce age, team, captain, venue, payment, and moderation authorization server-side.
- Preserve auditable state transitions and source/authority information for booking and payment data.
- Make provider integrations idempotent and replaceable through connector boundaries.
- Support a pilot venue without coupling the domain model to one provider’s API.
- Provide conservative defaults for youth advertising, stale availability, unknown payment status, and failed integrations.
- Support reliable lifecycle notifications and funnel analytics without exposing unnecessary youth data.

**Non-Goals:**

- Building leagues, tournaments, rankings, reputation systems, AI scheduling, or recurring subscriptions.
- Implementing a general-purpose wallet, escrow, stored-value balance, or funds-custody product.
- Treating direct captain-to-player payments as provider-verified transactions.
- Allowing AI or automation to finalize irreversible bookings or payments without user authorization.
- Supporting users under 16 or a guardian-managed account model.
- Replacing legal, payment-provider, app-store, venue-partner, or advertising-policy validation.

## Decisions

### Use a modular monolith as the initial service boundary

NestJS will host domain modules behind a single authenticated API and shared PostgreSQL database. Modules will have explicit service boundaries and event contracts without prematurely splitting into independently deployed services. This fits a greenfield pilot, keeps transactions local for critical state changes, and leaves provider connectors and asynchronous work replaceable.

Alternatives considered:

- **Microservices first:** rejected because it would add deployment and distributed-transaction complexity before product behavior is validated.
- **Supabase-first backend:** not selected because the repository context already establishes NestJS, Better Auth, Drizzle, Redis, and MinIO as the project stack.

### Separate domain aggregates and state machines

The core aggregates will be identity/eligibility, team membership, challenge/match, booking, payment order/contribution, dispute, notification, and analytics event. Each aggregate will own valid transitions and expose domain events rather than allowing clients to set arbitrary states.

The key relationships are:

```text
User -> Team Membership -> Challenge -> Match
                              |            |
                              v            v
                           Booking     Attendance
                              |
                              v
                      Payment Order
                       /          \
          Provider Transaction   Participant Contributions
                                      |
                                      v
                                   Dispute
```

A match may be agreed before a booking is confirmed. A booking may be confirmed while participant contributions remain outstanding because the captain guarantees the venue cost.

### Use server-side authorization with explicit policy inputs

Better Auth supplies identity. NestJS guards and domain services enforce authorization using user identity, age category, team membership, captain/team permissions, booking authority, support role, and moderation role. Client-side checks are convenience only.

Age eligibility will be derived from a validated date-of-birth policy and stored as the minimum necessary category (`youth` for 16–17 or `adult` for 18+), together with policy/version metadata. Users under 16 are rejected before community access. There is no guardian relationship model in the launch path.

Youth restrictions will be applied in discovery, communication, notification content, analytics, and advertising policy evaluation. Precise location will not be exposed through public youth surfaces.

### Model location with PostGIS and privacy-preserving projections

Store venue coordinates and user/team approximate location separately. Geospatial queries will use PostGIS for radius and format filtering. API responses will expose only the precision allowed by the viewer’s relationship and the user’s age policy. Exact venue coordinates may be available to authorized booking participants while user locations remain approximate.

### Use versioned proposals and optimistic concurrency for challenges

Challenge conditions will be represented by immutable proposal versions plus the current challenge state. Material changes create a new version and invalidate prior approvals where required. Update operations will carry a version or equivalent concurrency token so two captains cannot select incompatible opponents or approve stale terms.

### Put venue authority behind a Booking Gateway

The domain will depend on a connector interface with separate responsibilities for discovery, external booking handoff, and native booking. A connector maps provider-specific responses to canonical venue, availability, reservation, confirmation, cancellation, and refund states.

Connector calls will use request idempotency keys and persist raw provider references and normalized state. Provider-confirmed status will require a trusted response or signed event from an authorized connector/operator. External declarations remain visibly user-reported.

Redis-backed caching and scheduled refresh jobs will support availability snapshots, expiration, retries, and connector health without treating cached availability as a reservation hold.

### Treat booking payment and participant contribution as separate ledgers

The payment model will have a booking-level payment order for the captain’s guarantee and separate participant contribution records. Every financial record includes amount, currency, source, status, related booking, actor, provider reference when applicable, and audit timestamps.

Provider payment flows will use signed webhook verification, an inbox/idempotency table, and transactional state updates. Direct participant-to-captain payments create an informational `paid_to_captain_reported` assertion only; they do not create platform custody, wallet balances, or provider transactions.

Captains aged 16+ can accept financial responsibility in the same product flow as adult captains. Provider account and payment-method restrictions remain an external launch validation gate rather than a guardian workflow.

### Use captain-first disputes with automatic support escalation

A participant can dispute a captain-reported contribution. The captain is the first resolver. A configurable deadline job escalates unresolved cases to platform support, and participants can request early escalation. Dispute transitions are append-only in the audit trail and do not automatically cancel bookings or alter attendance.

Support can correct the platform record, but cannot automatically refund a direct payment that the platform never held. Provider disputes follow provider webhook and refund states.

### Use an outbox for notifications and analytics events

Transactional changes will write domain events to an outbox in the same database transaction. Workers will deliver push/in-app notifications through FCM/APNs adapters and publish analytics events after commit. Event consumers will be idempotent and retain the source aggregate and event version.

This prevents a successful booking or payment transition from being committed without a notification/measurement opportunity, while keeping external delivery failures from rolling back core transactions.

### Make advertising a policy decision, not a widget decision

A server-delivered or remotely controlled advertising policy will evaluate age category, consent state, surface, feature flag, and configuration version. The mobile client will only request ads after receiving an eligible decision. The default when policy or configuration is unavailable is no ads.

Ads will be excluded from checkout, payment confirmation, safety reporting, and important negotiation/confirmation surfaces. Adult consent records will include policy version and timestamps. Youth users will not receive personalized ads.

### Build feature flags and pilot operations into the first release

Booking connectors, payment modes, advertising, and selected surfaces will be independently flaggable. A minimum operator interface will support venue configuration, booking exceptions, support disputes, moderation actions, connector health, and audit review. Rollout will begin with an allowlisted pilot venue and region rather than assuming all venues are operationally equivalent.

## Risks / Trade-offs

- **Provider/payment terms reject a 16–17-year-old payer** -> Validate provider and venue terms before enabling youth captain payment; preserve the product permission model but fail safely with an actionable payment alternative rather than silently requiring a guardian.
- **External availability becomes stale** -> Display source and timestamp, expire snapshots, avoid availability guarantees, and retain external booking fallback.
- **Webhook duplication or reordering creates financial inconsistencies** -> Verify signatures, persist event identities, process transitions transactionally, and make handlers idempotent.
- **Captain-reported payments are inaccurate or abused** -> Label the source, notify participants, provide disputes, use captain-first review with automatic support escalation, and keep an immutable audit trail.
- **Distributed booking and payment transitions partially fail** -> Keep booking and payment states separate, use explicit pending/failed states, retry through jobs, and never infer provider confirmation from payment alone.
- **Youth safety restrictions are bypassed through notifications or search** -> Centralize policy evaluation, test every read surface, return privacy-preserving projections, and audit sensitive authorization decisions.
- **MVP breadth delays validation** -> Implement vertical slices in dependency order, gate external integrations behind flags, and use pilot release gates for native booking, payment reconciliation, safety review, and completion analytics.
- **Analytics exposes youth behavior or precise locations** -> Enforce role- and age-aware aggregation, minimize event payloads, and exclude optional collection without required consent.
- **Greenfield scaffolding expands unexpectedly** -> Keep the first implementation as a modular monolith with a documented module boundary; defer service extraction until measured operational needs justify it.

## Migration Plan

This is a greenfield change, so there is no production migration from existing application tables.

1. Establish repository structure and local development configuration for Flutter, NestJS, Drizzle, PostgreSQL/PostGIS, Redis, and MinIO.
2. Create foundational database migrations, seed only non-sensitive development data, and add server-side authorization primitives.
3. Deliver identity, team, and match coordination as the first vertical slice with feature flags and end-to-end tests.
4. Add venue catalog, external booking, and the pilot native connector with explicit provider verification states.
5. Add captain-guaranteed payment, provider webhooks, contribution reporting, dispute escalation, and reconciliation tests.
6. Add notifications, analytics, advertising policy, and operational dashboards with conservative defaults.
7. Run pilot validation and release gates for age policy, moderation, provider confirmation, payment failures/refunds, dispute handling, and completed-match measurement.

Rollback uses feature flags to disable native booking, payment collection, advertising, or affected connectors without deleting historical audit, booking, or payment records. Database migrations must be backward-compatible during staged rollout; irreversible data changes require a separately reviewed migration.

## Open Questions

- Which municipality/region and native venue partner are selected for the pilot?
- Which payment provider and payment methods are contractually available to 16–17-year-old captains?
- What exact captain dispute review deadline and support service-level target should be configured?
- What substitute limits and mixed-team rules apply to each football format?
- Which verification or anti-abuse level is required beyond self-declared date of birth for the pilot jurisdiction?
