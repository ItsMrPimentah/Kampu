# Design

## Context

The Flutter app currently starts from `MaterialApp.home`, keeps onboarding and the authenticated shell in widget state, and uses `MaterialPageRoute` for transitions from `AuthenticatedShell`, `TeamHubScreen`, and `MatchHubScreen`. The authenticated shell is currently a single `Scaffold` with a Manage teams action. Existing domain screens and tests are organized under `apps/mobile/lib/` and `apps/mobile/test/`.

The repository already has domain contracts for match coordination, venue booking, players/teams, and notifications. This change consumes those behaviors from a mobile presentation layer; it does not change backend contracts. The Stitch screens are mobile designs using a Midnight palette, compact cards, local-style icons, and a shared four-destination navigation dock.

## Goals / Non-Goals

**Goals:**

- Establish a route-first authenticated mobile app shell using GoRouter and a shared ShellRoute.
- Keep onboarding/eligibility outside the authenticated shell and preserve redirect behavior for ineligible or unauthenticated state.
- Make GoRouter location the single source of truth for the active destination.
- Provide Midnight-styled Home/Discover, Pitches, and challenge negotiation experiences backed by deterministic local mock state.
- Keep existing team, match, venue, payment, and safety screens reachable while they are incrementally migrated.
- Use bundled/local icons and resources so the initial mobile experience does not depend on remote Stitch URLs or font requests.
- Support local offline, empty, booking-status, and negotiation interaction states.

**Non-Goals:**

- Backend, API, database, payment, authentication-provider, or notification-service changes.
- Real venue reservations, challenge messages, payments, or live availability.
- Web, desktop, Windows, tablet, or responsive multi-platform layouts.
- Replacing every existing feature screen with a new Stitch design in this change.
- Introducing a second navigation state store that can diverge from GoRouter.

## Decisions

### Use GoRouter with an authenticated ShellRoute

Add a GoRouter-based route graph with an onboarding route outside the shell and authenticated primary destinations inside it:

```text
/onboarding
/home
/challenges
/challenges/:challengeId
/pitches
/pitches/:pitchId
/squad
/matches
/venues
/payments
/safety
```

The authenticated shell will render a shared Midnight scaffold around the active child route. Primary tab routes should use stable locations and preserve the shell while detail routes are pushed above it. `go_router` is preferred over continued Navigator 1.0 usage because it provides declarative route matching, redirect support, deterministic deep-link behavior, and a natural ShellRoute boundary.

A single Navigator with manually coordinated `MaterialPageRoute` calls was considered, but it would preserve the current route/state drift and make the four-tab shell difficult to reason about. A nested Navigator-only solution was rejected because it would require duplicating route selection and back-stack semantics.

### Keep navigation controller subordinate to route state

Introduce a navigation controller as the command and presentation adapter for the shell. It will:

- map the current route location to a primary destination index;
- expose destination commands that call the configured router;
- handle tab reselection and destination-specific back-stack policy;
- never maintain an independent authoritative selected-index state.

This keeps navigation actions testable without allowing a controller boolean or index to disagree with the URL-like route location. A `ChangeNotifier` or equivalent observable adapter may be used for shell rebuilds, but the router location remains authoritative.

### Preserve onboarding as the root gate

The existing eligibility flow remains the first entry point. The app session/eligibility state will be supplied to the router and used by a redirect or route gate:

- eligible state may enter `/home`;
- onboarding/incomplete state resolves to `/onboarding`;
- authenticated detail routes cannot bypass the gate.

The current stateful `MaterialApp` transition is replaced by router configuration, but the existing onboarding validation behavior and tests remain valid.

### Use a mocked presentation layer instead of domain-service calls

Create immutable local presentation models for:

- upcoming fixtures;
- team challenges and negotiation revisions;
- open games and roster positions;
- pitch venues, sources, surfaces, slots, and booking states.

Views receive these models through local mock repositories or fixed fixtures. User actions update local state only and expose visible feedback. Dio, server persistence, and real notification dispatch are deliberately not involved.

The Challenges primary route will use a small mocked challenge list because the selected Stitch artifact is a negotiation detail screen rather than a challenge-list screen. Selecting an item opens `/challenges/:challengeId`.

### Centralize Midnight design tokens

Extend or replace the current `PitchPulseTheme` presentation layer with Midnight tokens shared by the shell and new screens:

- Void `#0F101A`
- Carbon `#151621`
- Gunmetal `#1F2433`
- Steel `#646E87`
- Steel-light `#939DB8`
- Frost `#C9D3EE`
- Iris `#5B63D3`
- Periwinkle `#7C87F7`
- Emerald signal and amber telemetry status colors

Inter remains the primary UI font. JetBrains Mono is used for prices, IDs, timestamps, filters, and telemetry. Theme helpers should provide card, pill, button, status, and navigation styles so individual screens do not duplicate color constants.

The existing authenticated purple presentation is replaced by Midnight. Registration/onboarding styling is migrated only where necessary to avoid breaking its validation-focused behavior; full visual redesign of registration is outside this change.

### Prefer local Material icons and bundled assets

Use Flutter's bundled Material icon font and local asset paths rather than remote Material Symbols or Stitch-hosted image URLs. Any venue/profile imagery needed by the mocked screens should be packaged locally, with fallback placeholders for missing assets. Startup or screen-entry code may precache local images used by Home and Pitches, while icon glyphs remain available without network access.

### Route existing hubs incrementally

Existing `TeamHubScreen`, `MatchHubScreen`, `VenueHubScreen`, `PaymentHubScreen`, and `NotificationSafetyScreen` remain usable. Their current direct pushes are replaced or wrapped by named routes where they are entered from the Midnight shell. This allows the new navigation architecture to land without requiring every existing feature to be redesigned at once.

## Risks / Trade-offs

- **[Risk]** Replacing `MaterialPageRoute` navigation can break existing widget tests and assumptions about `Navigator` stacks. → Keep onboarding and existing destination behavior covered by route tests; migrate entry points in small steps and preserve named parent routes.
- **[Risk]** GoRouter state and a navigation controller could diverge. → Make the current route location authoritative and limit the controller to route-to-index mapping and commands.
- **[Risk]** Mocked booking or negotiation states could imply real confirmation. → Label native, external, cached, pending, and confirmed states explicitly and never use provider-confirmed language for mocked/unverified data.
- **[Risk]** Local replacement assets may not match the Stitch screenshots exactly. → Prefer simple bundled placeholders/icons for the first pass and keep asset lookup centralized for later refinement.
- **[Risk]** The existing theme extension name and tests are coupled to `PitchPulseTheme`. → Preserve compatibility wrappers or migrate references deliberately while keeping theme token tests focused on observable colors and dimensions.
- **[Risk]** Static fixture content can become stale as the app evolves. → Keep all mocks in one presentation fixture module and document the data as demo-only.

## Migration Plan

1. Add the GoRouter dependency and introduce the route graph behind the existing app entry point.
2. Move onboarding and eligibility gating into the router-owned root flow.
3. Add the Midnight ShellRoute and route-backed navigation controller.
4. Add the Home/Discover route and local mock data, then route existing feature actions through the shell.
5. Add Pitches and challenge negotiation/detail routes, including local empty/offline states.
6. Migrate remaining existing hub links from direct `MaterialPageRoute` calls to route locations where they intersect the shell.
7. Add local resources and precache the assets used by the new screens.
8. Run the existing Flutter test suite plus route, shell, and interaction tests.

Rollback is limited to the client: restore the old `MaterialApp.home` authenticated shell and direct navigation entry points, remove the new router wiring, and retain the new screens as unused source files. No data migration or backend rollback is required.

## Open Questions

None. The challenge-list route is intentionally a small mocked intermediary that opens the provided Stitch negotiation detail screen, and all other scope decisions are recorded in the proposal and specs.
