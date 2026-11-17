# Tasks

## Resolved MVP configuration

- Pilot regions are Lisbon and Setúbal, Portugal, with PlayArena as the initial native venue partner.
- Stripe is enabled in sandbox mode only until the MVP is approved for production payment processing.
- Disputes are captain-first; the MVP does not promise a platform-support SLA, while the captain review deadline remains configurable.
- Initial formats are 5v5, 7v7, 11v11, futsal, and futevoley 2v2. Fusion teams are represented per game without merging their underlying teams; each captain continues to manage that game’s details and payments.
- Date of birth is self-declared for the pilot, with no additional age-verification provider.

## 1. Repository and platform foundation

- [x] 1.1 Scaffold the Flutter mobile app and NestJS modular monolith with Better Auth, Drizzle, PostgreSQL/PostGIS, Redis, and MinIO configuration, and verify local development services start with the documented command.
- [x] 1.2 Define shared API contracts, domain-event envelopes, error codes, feature-flag configuration, and environment validation, and verify contract tests reject missing or invalid required configuration.
- [x] 1.3 Create the initial PostgreSQL/PostGIS migration structure and Drizzle schema conventions for identity, teams, matches, bookings, payments, disputes, notifications, analytics, consent, and audit records, and verify migrations apply to a clean database.
- [x] 1.4 Add transactional outbox and idempotency primitives shared by domain modules, and verify an event and its idempotency key are committed atomically with the originating transaction.

## 2. Identity, eligibility, and authorization

- [x] 2.1 Implement self-declared date-of-birth onboarding that rejects users under 16 and assigns `youth` for ages 16–17 or `adult` for ages 18+, and verify boundary-age and invalid-date tests pass without creating a guardian workflow.
- [x] 2.2 Implement server-side authorization guards and policy services for identity, age category, team membership, captain permissions, organizer permissions, moderation, support, and booking authority, and verify unauthorized API requests receive consistent denial responses.
- [x] 2.3 Implement auditable eligibility and sensitive-authorization decision records containing actor, action, target, timestamp, policy version, and minimal reason data, and verify audit records omit unnecessary personal information.
- [x] 2.4 Add the mobile onboarding and session flows for eligible accounts, including clear under-16 rejection and youth/adult policy handling, and verify an authenticated user can complete onboarding only after eligibility is established.

## 3. Player profiles and teams

- [x] 3.1 Implement player profiles with display identity, preferred positions, skill level, availability, and approximate location using privacy-aware response projections, and verify profile create/update and youth-location tests pass.
- [x] 3.2 Implement team creation and team-scoped memberships, invitations, roles, permissions, leaving, and captain removal, and verify a player can belong to multiple teams without cross-team membership changes.
- [x] 3.3 Implement team administration authorization and record rejected unauthorized setting or membership changes in the audit stream, and verify captain and explicitly delegated permissions work while ordinary members are denied.
- [x] 3.4 Implement configurable format support and roster-readiness calculations for the initial formats and starting roster requirements, and verify incomplete teams are not discoverable as ready for a selected format.
- [x] 3.5 Build mobile profile, team, invitation, membership, and readiness screens, and verify the primary team-management flows work against the API in widget or integration tests.

## 4. Match formats, challenges, Open Games, and Fusion teams

- [x] 4.1 Implement canonical format configuration for 5v5, 7v7, 11v11, futsal, and futevoley 2v2, including roster requirements and validation metadata, and verify unsupported formats are rejected while each initial format is accepted.
- [x] 4.2 Implement Team vs Team challenge aggregates and lifecycle transitions from draft through open, negotiation, agreement, scheduling, confirmation, completion, cancellation, and expiry, and verify invalid transitions cannot be performed by clients.
- [x] 4.3 Implement single-opponent selection, self-challenge prevention, versioned proposals, counteroffers, material-change reapproval, and optimistic concurrency, and verify competing concurrent opponent selections produce one success and one conflict.
- [x] 4.4 Implement eligible challenge and Open Game discovery using approximate location, format, availability, capacity, and age/privacy policy filters, and verify youth results use privacy-preserving projections.
- [x] 4.5 Implement Open Game slots, required positions, applications, organizer approval, capacity limits, and optional waiting lists, and verify duplicate approvals and over-capacity enrollment are prevented.
- [x] 4.6 Implement Fusion game participation as a per-match association of otherwise separate teams, preserving each captain’s authority over game details and contributions, and verify the association does not merge team memberships or permissions.
- [x] 4.7 Implement attendance requests, participant attendance states, no-show recording, and idempotent organizer completion, and verify one completion transition emits one completion event.
- [x] 4.8 Build mobile discovery, challenge negotiation, Open Game, roster, Fusion, attendance, and completion flows, and verify an end-to-end test covers publication through completion.

## 5. Venue catalog and booking gateway

- [x] 5.1 Implement format-aware venue catalog records with Lisbon and Setúbal region support, PlayArena pilot configuration, booking method, source, verification level, and information timestamps, and verify venue search returns source and freshness metadata.
- [x] 5.2 Implement stale-information detection, approximate venue/user location projections, and booking/challenge state separation, and verify expired availability is labeled stale and never presented as provider-confirmed.
- [x] 5.3 Define the Booking Gateway connector interface for discovery, external handoff, native reservation, confirmation, cancellation, refund, idempotency, and health reporting, and verify a fake connector satisfies the canonical contract.
- [x] 5.4 Implement external booking declarations with venue, time, source URL, external reference, receipt metadata, user-declared authority, and validation errors, and verify incomplete declarations are rejected and complete declarations remain non-provider-verified.
- [x] 5.5 Implement the PlayArena connector in sandbox/pilot mode for availability lookup, slot selection, reservation, confirmation, cancellation, and failure mapping, and verify signed or trusted provider responses alone can create provider-confirmed state.
- [x] 5.6 Implement booking lifecycle transitions, request idempotency, provider-event deduplication, retry/expiry handling, and unauthorized-confirmation rejection, and verify repeated provider events create one reservation and one state transition.
- [x] 5.7 Build mobile venue search, booking-source/status, external declaration, and native reservation screens, and verify failed reservations offer an actionable alternative without claiming confirmation.

## 6. Booking payments, contributions, and disputes

- [x] 6.1 Implement separate booking-payment, participant-contribution, and attendance records with the required statuses, amounts, currencies, actor/source fields, provider references, and audit timestamps, and verify unpaid contributions never alter booking confirmation or attendance state.
- [x] 6.2 Implement captain guarantor acceptance for eligible captains aged 16+ and full-captain-payment or assigned-contribution models, and verify assigned contributions reconcile to the collectable amount after configured fees and rounding.
- [x] 6.3 Implement Stripe sandbox payment intents and refund mapping behind a feature flag, including pending, processing, succeeded, failed, cancelled, refunded, disputed, and outstanding states, and verify production Stripe credentials or live-mode processing are refused by configuration validation.
- [x] 6.4 Implement signed Stripe webhook verification, provider-event inbox deduplication, transactional/idempotent payment transitions, and reconciliation records, and verify duplicate or reordered webhook deliveries do not create duplicate financial records.
- [x] 6.5 Implement captain-reported direct contribution assertions as `paid_to_captain_reported` without wallet, escrow, custody, or provider-transaction balances, and verify participants can see the payment source and platform-held balances remain absent.
- [x] 6.6 Implement participant disputes for captain-reported contributions, captain-first resolution, configurable review deadline escalation, participant-requested escalation, notifications, and append-only dispute audit history without promising a support SLA, and verify booking and attendance remain unchanged during review.
- [x] 6.7 Build mobile guarantor, payment, contribution, direct-payment report, dispute, and resolution flows, and verify payment failure, captain-reported, disputed, resolved-unpaid, refund, and outstanding states are displayed distinctly.

## 7. Safety, communication, advertising, notifications, and analytics

- [x] 7.1 Implement youth privacy projections, restricted adult-to-youth discovery and messaging policies, team/match communication contexts, blocking, reporting, and moderator case access, and verify prohibited discovery and conversations are rejected while authorized contexts remain available.
- [x] 7.2 Implement notification templates and outbox delivery for challenge proposals/counteroffers, approvals, material changes, booking results, payment failures, disputes, cancellations, attendance, and no-shows, and verify notifications omit precise youth locations, private reports, and unauthorized payment details.
- [x] 7.3 Implement age-aware advertising policy evaluation, adult consent versioning, no personalized ads for youth or unknown age, critical-workflow exclusions, remote configuration, and no-ad fallback, and verify clients do not request ads when policy or configuration is unavailable.
- [x] 7.4 Implement analytics events for publication, opponent agreement, schedule agreement, booking declaration, provider confirmation, payment completion, attendance, completion, cancellation, and no-show, and verify each event retains source aggregate/version and is emitted idempotently.
- [x] 7.5 Implement operator metrics for the match funnel, booking/payment reliability, disputes, refunds, cancellations, and no-shows with age-aware aggregation and consent checks, and verify reports distinguish published, agreed, booked, funded, attended, and completed matches without exposing individual youth data.
- [x] 7.6 Build in-app notification, consent, privacy, safety-reporting, and ad-policy surfaces, and verify critical booking/payment/reporting workflows contain no advertisement and show safe notification content.

## 8. Pilot operations and integration verification

- [x] 8.1 Implement the minimum operator controls for Lisbon/Setúbal and PlayArena venue configuration, feature flags, connector health, booking exceptions, moderation actions, dispute review, and audit review, and verify operator authorization is enforced for each action.
- [x] 8.2 Add seed and fixture data for non-sensitive development users, teams, supported formats, Fusion games, PlayArena sandbox venues, Stripe sandbox events, and dispute cases, and verify the seed process is deterministic and contains no production secrets.
- [x] 8.3 Add end-to-end coverage for the primary vertical slice from self-declared age eligibility through team creation, challenge/Fusion setup, PlayArena booking, Stripe sandbox payment, attendance, dispute handling, and completed-match analytics, and verify failure paths never overstate booking or payment confirmation.
- [x] 8.4 Add security, authorization, idempotency, privacy, and migration checks to CI and document local setup, sandbox-only payment operation, pilot-region assumptions, and rollback feature flags, and verify the documented CI and local commands pass on a clean checkout.

## Workflow follow-up

- Review the implemented change against the OpenSpec requirements and run the project verification suite.
- Archive the change after implementation and review are complete.
