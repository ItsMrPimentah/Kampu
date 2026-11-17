# Design

## Context

The authenticated Flutter shell already routes `/home` to `HomeScreen`, wraps it in the Midnight shell, and provides reusable Stitch primitives such as `StitchTopBar`, `StitchCard`, `StitchStatusPill`, `StitchFilterChip`, and `StitchGradientButton`. Home currently reads a `LocalPresentationData` snapshot containing one fixture, challenges, open games, venues, and a sync timestamp. It does not yet have a structured user/team context or all of the display values implied by the Stitch Home Feed.

The relevant visual authority is the Google Stitch project `projects/10729709610488881069` (“Amateur Football Community Platform”), specifically its Match Discovery & Home Feed screen and shared Midnight theme. The implementation must remain native Flutter, mobile-first, offline-safe, and compatible with the existing GoRouter/navigation and local presentation boundaries.

## Goals / Non-Goals

**Goals:**

- Map the Stitch Home Feed hierarchy to composable Flutter sections without changing the existing `/home` route or shell behavior.
- Make every Home display dependency available from one deterministic local preview snapshot, including user and team context as well as discovery content.
- Keep domain meanings and authority labels honest: local preview actions are not server persistence, payment confirmation, or provider confirmation.
- Reuse the existing Midnight theme and Stitch primitives, adding only narrowly scoped Home presentation support where an existing primitive is insufficient.
- Validate the composition, state matrix, semantics, and supported 360dp/390dp/430dp widths with focused tests.

**Non-Goals:**

- No backend service, authentication/profile API, database, or live notification integration.
- No new navigation architecture, route, domain contract, booking workflow, or match/team lifecycle behavior.
- No runtime network images, hosted fonts, or Stitch HTML/React code in the Flutter implementation.
- No requirement for pixel-identical rendering or for changing other authenticated destinations beyond shared component compatibility.

## Decisions

### Extend the existing local presentation boundary instead of adding a Home-only service

Add the missing Home context to the existing immutable presentation data model and fixture boundary rather than creating API-shaped repositories, screen-local constants, or a second mock system. The snapshot should cover a stable preview user, avatar/fallback identity, active team, eligibility/location summary, notification count, fixture/challenge/open-game content, and timestamps. Existing venue and challenge models remain reusable where they already represent Home data.

This keeps all preview data discoverable in one place and makes a later service-backed replacement possible without changing the screen contract. A new HTTP/mock server layer was rejected because it would add nondeterminism and contradict the current offline-safe presentation architecture. Scattering literals through widgets was rejected because it would make missing dependencies and fixture refreshes difficult to audit.

### Compose Home in the Stitch reading order

Organize the screen as a vertically scrolling feed with the following semantic order: compact branded/header context and notification affordance; user/team and location or eligibility context; local/offline telemetry; upcoming fixture hero; format/discovery filters; challenge section; open-game section; and stable team-management/secondary entry points. Keep the existing navigation dock outside the feed and reserve bottom padding for its safe-area footprint.

Use the existing Stitch components for cards, pills, chips, and gradient actions. If the Stitch reference uses imagery unavailable locally, use the existing resilient local image/fallback treatment and document the deviation rather than introducing a remote URL. Material/platform-safe icons are acceptable where Stitch icon assets are not packaged.

### Separate preview state from immutable content

Keep deterministic content in the local snapshot and represent transient preview state in the Home presentation state: loading, cached/offline labeling, selected format, joined-game status, challenge feedback, and refresh feedback. Empty results should be derived from the selected filter or an explicit empty fixture variant rather than by mutating the canonical fixture set.

This preserves repeatable fixture tests while allowing widget tests to exercise visible local transitions. A fake network client was rejected because the required states are presentation states, not transport behavior, and no backend call should be implied by the preview.

### Preserve existing navigation commands and domain semantics

Continue using the existing `NavigationController` callbacks for challenge, match/open-game, team, and notification destinations. Home-specific actions update only local presentation state and use explicit copy/update behavior for displayed feedback. Joining must remain disabled when capacity is full, and local success copy must identify the action as local/demo context. No Home card may label a mocked venue or reservation provider-confirmed.

This avoids route regressions and keeps the existing match-coordination, players-and-teams, venue-booking, and identity/safety specifications authoritative for domain behavior. Replacing the route graph or introducing Home-specific navigation state was rejected as unnecessary scope.

### Use fixed fixture time and representative state coverage

Fixtures should use stable identifiers, ordering, timestamps, capacities, and labels so repeated loads and screenshot/widget assertions are deterministic. The default snapshot should contain enough variety to exercise populated sections, available and full open-game capacity, at least one challenge status, and a meaningful upcoming fixture. Tests should additionally construct filtered and empty variants without relying on the wall clock.

The fixture should state its local/cached nature in the UI and avoid claiming live availability. This follows the existing venue-booking authority rules while keeping the Home preview visually useful.

### Validate semantics and layout rather than incidental pixels

Add model/fixture tests for deterministic completeness and widget tests for the Stitch section order, key labels, selected filters, navigation callbacks, local feedback, offline/empty states, and accessibility semantics. Render at 360dp, 390dp, and 430dp widths with a bottom safe-area inset and assert no overflow or hidden primary control. Screenshot/golden coverage may focus on stable Home anchors, but semantic behavior remains the primary regression contract.

The design reference is used for hierarchy, visual language, and component intent. Exact demo copy, unavailable imagery, and minor spacing differences may be adapted to the local fixture and Flutter constraints rather than copied from Stitch HTML.

## Risks / Trade-offs

- **[Risk]** The Home mock snapshot can drift from future Stitch design updates. → Keep fixture fields and section mapping explicit, reference the selected Home Feed screen in implementation notes, and review the stable Home anchors during visual checks.
- **[Risk]** More mock context may encourage code that assumes a real authenticated profile. → Name and document the data as preview-only, keep it behind the local presentation boundary, and avoid changing authentication/session contracts.
- **[Risk]** Dense Stitch content may overflow at narrow widths or under long localized labels. → Use flexible Flutter layouts, bounded text, scrolling sections, minimum touch targets, and width-specific widget coverage.
- **[Risk]** Local action feedback may be mistaken for durable state. → Use local/demo wording, avoid provider-confirmed language, and reset transient state when the Home widget/session is recreated.
- **[Risk]** Adding fields to shared presentation models can affect existing screens/tests. → Preserve existing fields and constructors where possible, use additive model changes, and run the complete mobile test suite.

## Migration Plan

1. Confirm the Home Feed reference and inventory the current Home sections, required display values, and reusable Stitch primitives.
2. Add the complete local Home context and deterministic fixture values without changing existing domain models or routes.
3. Refine the Home composition and state presentation using the existing Midnight/Stitch components and local fallback assets.
4. Add focused model, widget, semantics, filter/action, empty/offline, and width/safe-area coverage.
5. Run formatting, Flutter analysis, Home-focused tests, and the complete mobile suite; compare stable Home anchors against the Stitch reference.

Rollback is presentation-only: restore the previous Home widget composition and local snapshot shape while leaving the authenticated shell, route graph, and domain contracts unchanged. No data migration or backend rollback is required.

## Open Questions

None. The change intentionally treats the existing Stitch Home Feed as the design reference and the current local presentation repository as the mock-data boundary; exact backend field mapping can be handled when service integration begins.
