# Proposal

## Why

The existing local pitches preview supports basic filters and actions but does not yet express the Stitch smart-scheduler hierarchy or consistently distinguish demo state from real venue availability. A coherent, interactive preview will make the intended experience reviewable without implying a booking integration exists.

## What Changes

- Reshape the Flutter pitches screen around the verified Midnight Stitch search, scheduler, venue cards, empty state and existing navigation shell.
- Adapt deterministic local venue and slot fixtures to support meaningful combined search, date, format, surface and distance filters, selection and local actions.
- Keep retry, reservation, provider and notification feedback truthful and limited to the preview session; calculate counts and prices from displayed fixture state.
- Add responsive, accessible behavior and focused tests, and compare rendered Flutter screens with Stitch while documenting intentional differences.

## Capabilities

### New Capabilities

- `local-pitch-discovery`: Discover and interact with deterministic local pitch and scheduler fixtures in a truthful, accessible mobile preview.

### Modified Capabilities

None; the repository currently has no published OpenSpec capabilities.

## Impact

Future implementation affects the Flutter pitches screen and controller, discovery fixtures and models, shared UI where appropriate, and Flutter tests. Existing navigation and unrelated consumers of `LocalFixtures` must remain functional. No provider, notification, booking, geolocation, network or durable persistence integration is introduced by this change.
