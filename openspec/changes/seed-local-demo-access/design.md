# Design

## Context

The checked-in migrations define real users, credentials, profiles, teams, memberships, matches, attendance, venues, bookings and community games. The existing seed is unguarded, has no login credential and includes stale dates. Community API data is persisted; several other product modules and mobile preview fixtures are in-memory. The current schema has no match scores or results.

## Goals / Non-Goals

**Goals:** Provide repeatable, representative local access through real authentication and API contracts. Make completed matches findable in existing authenticated UI.

**Non-Goals:** No remote Supabase or production changes, global demo auth bypass, SMS, real transactions, claims that in-memory modules are seeded, or invented scores.

## Decisions

- Add a separate guarded demo command; do not extend or run the unguarded existing seed. Require explicit development/test environment, opt-in and an explicit dedicated database on a local address; reject production, remote targets and ambiguous connection parameters before opening a connection.
- Seed a uniquely named fixture graph transactionally using stable IDs and insert-only behavior with collision validation, preserving user changes on reruns. Never blanket-delete or change unrelated records. A fresh disposable database provides reset; document fixtures do not automatically refresh schedules on rerun.
- Seed a synthetic captain with scrypt-compatible credentials and verified status solely in the disposable database. Use real login, session and authorization; do not modify runtime auth or integrate a mock verifier.
- Seed valid future and completed matches and related participants and proposals, teams, roster, open games, venues and coherent illustrative finance/notification data as appropriate to the existing migrations. Never issue real provider requests or unprocessed outbox events.
- Adapt existing community challenge presentation minimally for clear completed-history visibility, using existing Midnight widgets and applicable home-feed/teams Stitch references `a319e14690984f9c8509ccd3efcc3200` and `65d94f88fc434010a8c6b1e7d28e07d0`. Preserve existing API and behaviors; no fabricated result UI.

## Risks / Trade-offs

- [Only part of the app uses persisted schema] → Document which screens consume API data and which remain preview or in-memory.
- [Accidental use on non-disposable data] → Restrictive loopback target, explicit opt-in, independent local cluster identity checks, fail on collision, no destructive reset. Loopback alone cannot rule out remote port forwarding.
- [Future fixture dates become stale] → Calculate at first seed and instruct recreating the disposable database for a fresh demo.
- [No live PostGIS] → Run automated guard/unit tests and report database-backed test limitations accurately if unavailable.

## Verification

On isolated loopback PostgreSQL 16/PostGIS 3.5 clusters, migration, seeded login, community roster/challenges/games, insert-only rerun and collision refusal passed. The documented loopback demo API was separately verified over HTTP with a real login and authenticated endpoints. The API suite passed with seven PostgreSQL-dependent tests skipped when run separately against an unavailable port; the dedicated demo integration and collision tests were run independently. Flutter format, analysis and 112 tests passed. No device-level visual comparison was performed.
