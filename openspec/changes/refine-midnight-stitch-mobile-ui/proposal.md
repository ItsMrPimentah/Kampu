# Proposal

## Why

The mobile client has the correct route structure and local discovery flows, but several surfaces still look like generic Material screens rather than the approved Google Stitch Midnight/SRE experience. This refactor will make the current UIs visually coherent with the Stitch project while preserving existing navigation, eligibility, local/mock behavior, and domain contracts.

## What Changes

- Establish the Stitch Midnight visual system as the single presentation source for supported mobile screens.
- Refine the authenticated shell into the Stitch console pattern: compact sticky header, safe-area-aware content, pill-shaped bottom dock, active/inactive destination treatments, and consistent iconography.
- Refine Home/Discover, Challenges, challenge negotiation, Pitches, Squad, registration, onboarding, and existing feature hubs to use the Stitch surface hierarchy, typography, spacing, status badges, cards, filters, and action treatments.
- Align the design tokens with the Stitch references: void/carbon/gunmetal surfaces, steel/frost text, iris/periwinkle gradient actions, emerald/amber telemetry states, Space Grotesk display/label type, and Inter body/data type.
- Add reusable presentation primitives for headers, console cards, status pills, format badges, source badges, telemetry banners, filter chips, primary/ghost buttons, and the navigation dock.
- Replace visual-only remote font/icon assumptions with bundled or platform-safe local equivalents; retain local placeholder imagery and fallback rendering.
- Preserve all current route locations, onboarding/registration callbacks, age and youth-safety behavior, local fixture interactions, booking authority labels, and existing feature-hub functionality.
- Add screenshot-oriented widget coverage for mobile widths, safe areas, active navigation, status variants, and visual regressions without introducing backend or API changes.

## Capabilities

### New Capabilities

- `mobile-visual-system`: Defines the observable Midnight/Stitch presentation language, reusable mobile surface patterns, accessibility contrast/touch requirements, and visual-state treatment across the existing mobile flows.

### Modified Capabilities

<!-- Existing domain requirements remain unchanged. This change refines presentation and does not alter identity, match, venue, payment, or safety contracts. -->

## Impact

- Flutter presentation code under `apps/mobile/lib/`, especially theme tokens, navigation shell, onboarding/registration, discovery, challenge, pitch, squad, and existing hub screens.
- Mobile assets and font/icon declarations under `apps/mobile/assets/` and `apps/mobile/pubspec.yaml`.
- New and updated widget/golden-style tests under `apps/mobile/test/`.
- No backend, database, authentication, payment provider, venue provider, or domain contract changes.
- Reference source: Stitch project `projects/10729709610488881069` (“Amateur Football Community Platform”), including the Home Feed, Pitch Discovery & Smart Scheduler, Team Challenge & Negotiation, Register, Team Roster, and shared design theme screens.
