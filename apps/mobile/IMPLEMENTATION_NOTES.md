# Midnight mobile implementation notes

## Stitch reference

The visual source of truth is the Google Stitch project:

- **Project:** `projects/10729709610488881069`
- **Title:** Amateur Football Community Platform
- **Reference screens:** Match Discovery & Home Feed, Pitch Discovery & Smart Scheduler, Team Challenge & Negotiation, Register, Team Roster, and the shared Midnight theme.

The project design theme and selected screen references are authoritative. The current project-level Pitch Pulse system is transcribed in [`DESIGN.md`](DESIGN.md), with Flutter constants in `lib/shared/ui/pitch_pulse_tokens.dart`. The currently applied Midnight and registration themes represent older purple screen styling and are not the project-level Pitch Pulse palette. A previously downloaded project-level `DESIGN.md` contained unrelated Better Stack provenance and is not the source of the new transcription.

## Home Feed mapping

Authenticated users now use the PostgreSQL-backed community feed, team roster, challenge negotiation and open-game screens. Their card layout and hierarchy reference Stitch's Match Discovery (`a319e14690984f9c8509ccd3efcc3200`), Challenge Negotiation (`cc1f3878b7c645f4836043bfc1516066`) and Team Roster (`65d94f88fc434010a8c6b1e7d28e07d0`) screens. The older `LocalFixtures` feed remains available only through the legacy router used by existing preview tests. Guardian-consent UI in the original roster mock is not used because it conflicts with the product brief.

The community API requires an authenticated, phone-verified session. Run `npm --workspace apps/api run db:migrate` to apply `0002_community.sql`; this migration is additive. Team and game invitations currently share a copyable, seven-day invitation code, entered inside the app. Community notifications are stored in the in-app inbox; push delivery is not yet connected. Full geospatial discovery, match reminders, team emblem upload, attendance responses, and automated field-vote deadline outcomes remain follow-up work.

The legacy local-preview Home implementation follows the Stitch Match Discovery & Home Feed reference in this order:

1. Compact ShowTime header with notification affordance.
2. Preview user/team context with avatar fallback, eligibility, and location.
3. Cached/offline snapshot telemetry.
4. Upcoming fixture hero with format and venue metadata.
5. Format/discovery filter controls.
6. Team challenges with local challenge action feedback.
7. Open games with capacity, filtering, and local join feedback.
8. Stable team-management entry point before the authenticated navigation dock.

That preview consumes a deterministic local presentation snapshot: refresh, join, and challenge actions update only the preview session. Stitch-hosted imagery is represented by bundled assets or the existing local fallback frame; platform-safe Flutter icons are used where the exact Stitch icon asset is not packaged.

## Local resource policy

Supported mobile screens must render without runtime Google Fonts, Material Symbols web-fonts, hosted images, or other remote presentation URLs. Use `StitchAssets` for local resource paths, Flutter Material icon glyphs, bundled placeholder imagery, and stable error fallbacks. Inter, Space Grotesk, and JetBrains Mono are declared as semantic font roles with platform-safe fallbacks until approved font files are packaged.

## Visual review workflow

1. Run the screenshot-oriented widget checks at 360dp, 390dp, and 430dp widths.
2. Compare the shell, Home, Pitches, challenge detail, and registration compositions against the corresponding Stitch screen references.
3. Check active/inactive dock state, safe-area insets, card and badge contrast, status authority wording, and no-overflow behavior.
4. Run formatting, static analysis, and the complete Flutter suite before accepting a visual baseline update.

## Deferred integrations

- Replace the remaining local venue previews with venue services once backend contracts are available.
- Persist native reservation and negotiation decisions before presenting them as provider-confirmed or durable.
- Connect external venue actions to provider deep links and live availability refreshes.
- Replace bundled placeholder imagery with approved local venue/team imagery.
- Add licensed local font files if product licensing supplies them; do not reintroduce network font loading.

The GoRouter graph, Midnight shell, and local state boundaries preserve these integration points without changing backend or domain contracts.
