# Proposal

## Why

The current Flutter Home screen has the route and Midnight primitives in place, but it does not yet present the complete Home Feed composition from the approved Google Stitch design. Its local snapshot covers only a subset of the data the designed screen needs, so important user-facing states such as profile/team context, notification context, location, and richer discovery content cannot be previewed reliably without backend data.

## What Changes

- Refine the authenticated Home/Discover screen to match the existing Stitch Home Feed structure, hierarchy, spacing, Midnight surfaces, typography, badges, filters, and action treatments while preserving the current route and navigation behavior.
- Add a complete deterministic local Home presentation snapshot containing every user-facing data dependency required by the design, including user identity/avatar fallback, active team context, eligibility/location context, notification summary, upcoming fixture, challenges, open games, roster/capacity values, and relevant timestamps.
- Keep all Home content sourced through a dedicated local presentation repository/fixture boundary so the screen can render without network access, authentication data, or backend services.
- Model explicit preview states for loading, offline/cached snapshot, empty sections, filtered results, and local action feedback so the designed screen can be reviewed across its meaningful states.
- Preserve existing Home interactions such as format filtering, opening challenge/match destinations, joining an open game, managing teams, and showing local feedback; update only their presentation and local state wiring as needed.
- Add focused widget/model coverage for the Home composition, deterministic mock data, accessibility labels, narrow mobile widths, and no-overflow behavior at the supported preview sizes.
- Do not change backend APIs, database contracts, authentication behavior, booking authority, or server-side match/team requirements.

## Capabilities

### New Capabilities

- `mobile-home-discovery`: Defines the authenticated Home/Discover presentation contract, complete local preview data, discovery states, and preserved Home interactions needed to review the Stitch-designed mobile feed before backend integration.

### Modified Capabilities

<!-- Existing match, team, venue, identity, and notification specifications remain unchanged; this change adds a presentation-layer preview capability without changing their domain requirements. -->

## Impact

- Flutter Home presentation code under `apps/mobile/lib/discovery/`, including the screen, local models, fixtures, and repository boundary.
- Shared Midnight/Stitch components only where Home needs missing visual or semantic treatments.
- Home-focused widget and unit tests under `apps/mobile/test/`, including deterministic fixture and layout/state coverage.
- Potentially the mobile implementation notes if the Home mock-data boundary or Stitch review workflow needs documenting.
- No backend, API, database, authentication, payment, venue-provider, or notification-service changes.
