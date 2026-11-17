# Proposal

## Why

The authenticated Flutter experience currently exposes separate, basic feature hubs through ad hoc `MaterialPageRoute` navigation and does not provide a coherent Home/Discover destination. The approved Stitch screens define a cohesive Midnight mobile experience for discovery, pitch scheduling, and challenge negotiation, so the client needs a route-driven shell that presents those flows consistently while remaining usable with local/mock data before backend integration.

## What Changes

- Add a Midnight-branded authenticated mobile shell based on the Stitch design system.
- Make the Stitch match-discovery screen the authenticated Home/Discover destination.
- Add the Stitch pitch discovery and smart scheduler as the Pitches destination.
- Add the Stitch challenge negotiation view as a challenge detail route.
- Replace ad hoc authenticated navigation with `go_router` and a shared `ShellRoute`.
- Add a Navigation controller that maps route locations to the four mobile destinations and issues route navigation commands without duplicating GoRouter state.
- Provide four primary destinations: Discover, Challenges, Pitches, and Squad.
- Keep existing team, match, venue, payment, and safety capabilities reachable through the new shell or nested routes where applicable.
- Replace the existing authenticated purple presentation with Midnight tokens, including void/carbon/gunmetal surfaces, iris/periwinkle actions, steel/frost text, and emerald/amber status treatments.
- Use bundled/local icons, fonts, and image assets; remove runtime dependence on remote Stitch image URLs or Google Fonts for these screens.
- Use local immutable mock data for fixtures, challenges, open games, venues, slots, and negotiation history.
- Support local empty, offline-snapshot, booking-status, and interaction states in the mobile UI.
- Keep the implementation explicitly mobile-only; Web, desktop, Windows, and tablet layouts are out of scope.
- **BREAKING**: Replace the current authenticated navigation entry points and `MaterialPageRoute`-based shell navigation with GoRouter route locations.

## Capabilities

### New Capabilities

- `mobile-navigation`: Authenticated mobile shell, GoRouter route structure, ShellRoute behavior, navigation-controller coordination, and destination selection.
- `mobile-discovery-experience`: Midnight Home/Discover, pitch scheduling, local snapshot rendering, and challenge-detail presentation behavior.

### Modified Capabilities

<!-- Existing domain requirements remain unchanged. The UI consumes existing match, venue, team, and notification behavior without changing their server-side contracts. -->

## Impact

- Flutter app entrypoint and authenticated shell under `apps/mobile/lib/`.
- New route configuration, navigation controller, Midnight design tokens, local asset registry, mock presentation models, and screen widgets.
- Existing match, team, venue, payment, and safety screens will require route integration and potentially Midnight theme adaptation.
- `apps/mobile/pubspec.yaml` will gain the GoRouter dependency and any locally bundled asset/font declarations required by the design.
- Existing widget and feature tests will need route-aware setup; new tests will cover shell destinations, selected navigation state, deep links/detail routes, mock interactions, and local/offline states.
- No backend API, database schema, payment provider, or domain contract changes are included.
