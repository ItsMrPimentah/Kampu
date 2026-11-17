# Design

## Context

The Flutter app already has a GoRouter-owned authenticated shell, local presentation fixtures, and a Midnight theme extension. The shell still uses the stock `NavigationBar`, while Home, Challenges, Pitches, and several legacy hubs mix generic Material widgets with only partial Midnight styling. Registration separately wraps itself in the compatibility `PitchPulseTheme`.

The Stitch project is `projects/10729709610488881069` (“Amateur Football Community Platform”). Its screen HTML and project design theme establish the mobile reference: `#0F101A` void, `#151621` carbon, `#1F2433` gunmetal, steel/frost text, iris/periwinkle actions, compact 390dp-first layouts, Inter/Space Grotesk/JetBrains Mono roles, telemetry banners, dense bordered cards, and a floating pill navigation dock. The downloaded project-level DESIGN.md has unrelated Better Stack provenance, so it is not treated as authoritative; the project `designTheme` and the selected Stitch screen references are the source of truth.

## Goals / Non-Goals

**Goals:**

- Create one reusable Flutter presentation layer that reproduces the Stitch visual grammar across authenticated, onboarding, registration, and legacy hub screens.
- Make mobile visual states explicit, accessible, and honest about local/offline/provider authority.
- Keep route locations, local fixture state transitions, eligibility policy, safety behavior, and existing callback contracts unchanged.
- Establish repeatable visual regression coverage at 360dp, 390dp, and 430dp widths with safe-area variants.

**Non-Goals:**

- No backend, API, database, payment, authentication-provider, or notification-service work.
- No new navigation architecture or domain model redesign.
- No web, desktop, tablet, Windows, or multi-platform responsive layouts.
- No runtime loading of Google Fonts, Material Symbols web fonts, remote Stitch images, or other network-hosted presentation resources.
- No requirement to make the current local fixture content identical to every text value in the Stitch mockups.

## Decisions

### Use the Stitch project theme and screen references as design authority

Centralize the palette, typography roles, spacing, radii, elevation, status colors, and CTA gradients in the existing Midnight theme layer. Add any missing tokens for surface tiers, status signals, text hierarchy, dock treatment, and rim-light effects rather than scattering literals through screens.

The project-level `designTheme` and the Home, Pitch Discovery, Challenge Negotiation, Register, and Team Roster screen references are preferred over the downloaded DESIGN.md because that markdown file contains an unrelated Better Stack extraction. This prevents a false visual baseline while preserving the exact Stitch project selected by the user.

Alternative considered: copy each screen’s HTML styling independently. Rejected because it would produce drift between routes and make accessibility, dark-surface contrast, and future Stitch updates expensive to maintain.

### Add reusable Stitch presentation primitives

Introduce a small presentation primitives layer for console app bars, pill navigation docks, carbon cards, telemetry banners, status/source pills, format badges, filter chips, primary/ghost/destructive buttons, and resilient local image frames. Primitives accept semantic colors and labels from the theme, expose minimum touch sizes, and avoid owning domain state.

Alternative considered: configure only global `ThemeData` and continue using stock cards/buttons/navigation. Rejected because the Stitch references rely on composed patterns—floating dock, compact telemetry rows, gradient/rim-light CTAs, and state badges—that global defaults cannot express consistently.

### Keep the existing route and state boundaries

Retain the current GoRouter graph and `NavigationController`; replace only the shell’s visual implementation and screen composition. Detail routes continue to render above the shell. Local repositories and screen-local interaction state remain the source of demo behavior, and visual components receive labels and callbacks instead of calling domain services.

Alternative considered: rebuild each screen as a new route-specific HTML-like surface. Rejected because it risks breaking deep links, back-stack behavior, onboarding gating, and existing widget tests for no visual benefit beyond what shared primitives provide.

### Use bundled/platform-safe resources

Package approved font files only when available under the project’s licensing constraints, with Inter, Space Grotesk, and JetBrains Mono fallbacks defined in the theme. Keep Material icon glyphs or bundled vector assets for iconography and use local placeholder/image assets with an error-builder fallback. Add an asset audit that fails if supported screens contain remote image or font URLs.

Alternative considered: preserve the Stitch HTML’s Google Fonts, Material Symbols, and hosted image URLs. Rejected because the mobile requirement is offline-safe and remote resources create nondeterministic first render and screenshot tests.

### Migrate surfaces in visual-risk order

Refactor in this order: theme/primitives, shell and dock, Home, Pitches, Challenges/detail, registration/onboarding, Squad and legacy hubs. Each stage keeps existing semantics and adds focused widget coverage before moving on. Use the Stitch screen labels and dimensions as review references rather than copying demo-only city/team content.

### Validate visual fidelity without coupling tests to incidental pixels

Add widget tests for token usage, labels, selected/inactive dock state, safe-area reachability, status variants, fallback imagery, and representative 360/390/430dp layouts. Add golden or screenshot baselines only for stable compositions (shell, Home hero, pitch card, challenge detail, registration header) and update them deliberately when the Stitch reference changes.

## Risks / Trade-offs

- **[Risk]** A shared primitive can over-generalize differences between Home, registration, and legacy hubs. → Keep primitives semantic and composable; screen-specific layout remains owned by each feature.
- **[Risk]** Bundled font files may be unavailable or carry licensing constraints. → Use platform-safe fallbacks and make font packaging an explicit asset task rather than silently fetching from the network.
- **[Risk]** Replacing `NavigationBar` can regress route selection or safe-area behavior. → Keep `NavigationController` as the route-derived authority and test every primary route plus detail back-stack behavior.
- **[Risk]** Visual state colors could imply provider confirmation or payment success. → Preserve semantic labels and authority wording from the existing domain specs; style never changes state meaning.
- **[Risk]** Existing registration tests rely on `PitchPulseTheme` names and dimensions. → Preserve compatibility wrappers while routing shared tokens through the Stitch layer and retain the current registration validation tests.
- **[Risk]** Golden tests become noisy across Flutter versions. → Prefer semantic/widget assertions for behavior and keep a small, intentionally scoped golden set for stable visual anchors.

## Migration Plan

1. Extend the Midnight token layer and define typography, status, shape, spacing, asset, and primitive contracts.
2. Implement the shared Stitch app bar, telemetry row, floating dock, cards, badges, chips, and button treatments without changing route commands.
3. Refine Home and Pitches against the selected Stitch references, preserving fixture and booking interactions.
4. Refine Challenges and negotiation detail, then registration/onboarding and Squad/legacy hubs, preserving existing callbacks and policy messaging.
5. Package/verify local fonts, icons, and imagery; remove remote resource assumptions from supported screens.
6. Add and run widget/golden coverage, accessibility checks, formatting, analysis, and the complete Flutter suite.

Rollback is presentation-only: retain the route graph and local state code, and revert screens to the previous Midnight primitives/theme wrappers if a visual regression blocks release. No data migration or backend rollback is required.

## Open Questions

None. The change assumes “current UIs” means the existing Flutter mobile surfaces in `apps/mobile/lib/`, and that the Stitch project listed above is the intended design source.
