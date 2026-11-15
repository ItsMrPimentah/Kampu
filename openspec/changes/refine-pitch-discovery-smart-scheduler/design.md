# Design

## Context

The verified source is Stitch project `10729709610488881069`, screen `245ad80116ea4d0293c73567a3677282`, “3. Pitch Discovery & Smart Scheduler (Midnight SRE)”, retrieved with its HTML and screenshot metadata. Its mobile reference is 780 × 3374; it is a long scroll with a dock, not a Flutter implementation. See `proposal.md` for motivation and the spec for behavioral acceptance.

The existing `/pitches` route renders `PitchesScreen` within `AuthenticatedShell`. It uses `PitchesController` and `LocalFixtures.load()`, which also supplies Home and other previews. The current controller filters venues by day-of-month but the card renders all their dates, and has session-only slot state, retry and notification flags. `PitchVenue` currently has one format and surface, a source, asset, distance and slots; slots have full timestamps, price and state. Current fixtures include Campo do Oriente (native artificial 5v5), Riverside Sports (external natural 7v7), and Alvalade Indoor (native indoor futsal, sold out). The screen currently has no search and shows a hard-coded sync claim.

## Goals / Non-Goals

**Goals:** Map the reference to existing Flutter architecture, provide useful deterministic preview filters and preserve local interaction affordances. Verify both visible behavior and rendered hierarchy.

**Non-Goals:** Provider availability or deep links, network sync, location services, real alerts, real holds or durable reservations. Stitch's HTML and hosted assets are reference material only.

## Decisions

### Visual mapping

- Use this screen's Midnight SRE styling, not the distinct project-level green Pitch Pulse theme. Reuse `context.midnight`, `StitchTopBar`, `StitchTelemetryBanner`, `StitchCard`, `StitchStatusPill`, filter components and the existing shell where appropriate. Reference canvas `#0F101A`, carbon `#151621`, gunmetal `#1F2433`, iris `#5B63D3`/`#7C87F7`, emerald `#10E575` and amber `#F59E0B`; use bundled Inter and available mono fallback instead of hosted fonts. Preserve contrast even where mock styling is too dim.
- Map the sticky header and telemetry strip, search/filter cluster, carbon scheduler panel with a four-date strip, three roster choices and horizontal surface chips, result heading, stacked cards and fixed four-item dock to native Flutter widgets. Keep distance control and all-format/all-date clearing available even though the mock compresses them. Respect safe areas and scrolling beneath the dock. Reuse ShowTime branding and existing navigation destinations rather than inventing the mock's PITCH·PRO brand or unrelated routes.
- Reference card detail: GreenField Park Arena (native, 3G, 3.2 km, 4.8, Pitch #4, amenities, 18:30/€70, 20:00/€80, 21:30/€65, selected best match and split cost), Metro Olympia Pitch (external natural grass, 5.1 km, 4.4, Field A, 19:00 and 20:30 at €90), and Urban Futsal Dome (native indoor, 6.8 km, 4.6, Court B, 17:00/€55 and 22:00/€50). Preserve the distinction between primary native and secondary external actions, thumbnail/amenity arrangement, slot grid, result/empty hierarchy, and iris selection treatment. Existing local venue names or adapted sample names are acceptable; fixture-backed details must be clearly sample data. Use bundled imagery or stable local placeholders, not remote Stitch URLs. Avoid displaying ratings or amenities unless supplied as fixture fields.
- The mock simultaneously selects 7v7 and 3G but displays natural and indoor venues. Initial demo filters instead default to a consistent all-results view so the three surface categories can appear together; subsequent selected filters genuinely constrain the cards. Its simulated “Results (3) / Sold Out” toggle is replaced by actual filtered results and an empty state, rather than a control that fabricates an unrelated result set. A fixture-sold-out venue can still appear as a match with an explicit demo unavailable state; zero results means no matching venue.

### Truthful status and actions

- Replace “Offline Snapshot / synced 14m ago”, “verified spots”, “Native Instant Booking”, “Hold Guaranteed”, “2 Slots Left”, “All Slots Booked”, “Notify On Drop” and “View on Provider Site” claims with explicit fixture/session wording, or omit them. Fixed fixture capture dates must not imply a successful synchronization. Counts and availability-like labels describe only sample slots. The external action reports that provider access is not connected; it does not launch a URL. Notification acknowledgement is a demo flag, not an actual alert. Retry retains or reloads fixture data with local-only feedback. Keep native eligible available/pending reservation behavior and show local confirmation, with no promise of provider confirmation or persistence. This is a deliberate deviation from fake live claims.
- Use alternatives in the empty panel only when actual fixture dates can be selected; choosing one updates the date and recomputes all other filters. A clear/adjust action always permits recovery. The mock's static October 2024 weekday/date combinations are internally inconsistent; derive labels from actual full fixture dates instead of copying them.

### Data and state

- Adapt `LocalFixtures` or introduce a pitch-specific local adapter while keeping Home, challenges and other existing consumers intact. Provide stable IDs and multiple coherent dates, native/external examples, available/pending/sold-out slots, distinct formats/surfaces/distances and at least one match and no-match combination. Include 5v5, 7v7, 11v11 and existing futsal as supported filter options when represented in fixtures; do not rename futsal as 11v11. Supply any card amenities, sample rating or pitch label through local data rather than hard-coding conflicting card content.
- Keep business state and combined filtering in the screen-scoped Riverpod controller, inject local data per Flutter guidelines and migrate changed screen state to Freezed with generated sources. Use Flutter Hooks only for ephemeral input/focus state. Compare full calendar dates, apply case-insensitive trimmed search against name/address, and apply format, surface and maximum distance together. Derive displayed slots and all counts from the same filtered data. Preserve available/pending/native and external behavior while clearing an inaccessible selection when criteria change. Ensure times include minutes and dates do not depend on today.
- Derive the cost row from the selected slot. If a split estimate is shown, use the displayed fixture total and actual roster size (e.g. 7v7 means 14 players), explicitly mark the rounded per-player amount as an estimate; do not reuse the mock's static €80/€5.70 when another slot is selected. If roster size is not defined, omit the estimate rather than inventing one.

## Risks / Trade-offs

- [Fixture changes affect shared preview screens] → Isolate pitch data changes or preserve Home/challenge fields and run their existing tests.
- [Reference contains fake certainty and inconsistent filters/dates] → Use fixture-derived labels and counts; document each visual/content deviation during review.
- [Narrow layouts, large text or dock hide controls] → Use adaptive wrap/scroll and bottom insets, check 360/390/430dp and enlarged text, semantics and contrast.
- [Rendered comparison differs from source capture dimensions or unavailable device] → Capture comparable Flutter states and inspect hierarchy/card styling against the Stitch screen; record device, sizes and specific differences. If a capture cannot be obtained, report the comparison as blocked rather than claiming success.

## Migration Plan

Implement as a local preview-only Flutter change, preserving `/pitches` and shared fixture consumers. Generate changed Dart sources through the project workflow and verify tests and quality gates. Roll back the Flutter changes and associated generated outputs together if needed; no backend migration or data migration is involved.
