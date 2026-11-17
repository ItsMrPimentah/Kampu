# Tasks

## 1. Stitch foundation and reusable primitives

- [x] 1.1 Reconcile the Midnight theme tokens with the selected Stitch project theme, including void/carbon/gunmetal surfaces, steel/frost text, iris/periwinkle actions, emerald/amber telemetry colors, Space Grotesk/Inter/JetBrains Mono roles, spacing, radii, and rim-light gradients while preserving `PitchPulseTheme` compatibility; verify theme unit tests cover token values, readable text styles, contrast-sensitive states, and existing registration expectations.
- [x] 1.2 Add reusable Stitch presentation primitives for console app bars, carbon cards, status/source pills, format badges, telemetry banners, filter chips, primary/ghost/destructive buttons, and resilient local image frames; verify widget tests cover minimum 44dp action targets, semantic labels, selected states, and missing-image fallbacks.
- [x] 1.3 Add the local asset/font/icon registry and package only approved or platform-safe resources needed by supported screens; verify an asset audit finds no runtime Google Fonts, Material Symbols web-font, remote image, or hosted URL dependency in the supported mobile presentation code.

## 2. Shared shell and navigation presentation

- [x] 2.1 Replace the stock authenticated `NavigationBar` presentation with the Stitch floating pill dock, compact shared header treatment, active/inactive destination styling, and safe-area-aware content while leaving `NavigationController` and route locations unchanged; verify shell widget tests at 360dp, 390dp, and 430dp widths with bottom insets.
- [x] 2.2 Apply shared shell/header/back treatments to primary and detail routes without changing deep-link or back-stack behavior; verify route widget tests that direct Home, Challenges, Pitches, and Squad navigation selects exactly one active destination and detail routes return to their parent.
- [x] 2.3 Add accessibility semantics and focus/activation coverage for dock destinations, header actions, back actions, and status affordances; verify semantics tests expose meaningful labels and selected states without relying on color alone.

## 3. Discovery and pitch visual refactor

- [x] 3.1 Refine Home/Discover to the Stitch Match Discovery & Home Feed composition with a compact brand header, fixture hero card, format/filter chips, challenge cards, open-game cards, local feedback, and consistent CTA treatments while preserving existing fixture and join/challenge actions; verify widget tests for rendering, actions, loading/empty/status states, and narrow-width layout.
- [x] 3.2 Refine Pitches to the Stitch Pitch Discovery & Smart Scheduler composition with offline telemetry, date/format/surface/distance controls, venue cards, slot summaries, native/external badges, and floating navigation; verify widget tests that filters update local results and all card actions retain their existing authority wording.
- [x] 3.3 Apply explicit Stitch visual treatments to available, pending, confirmed, external, sold-out, cached, retry, alternative-date, and notify-on-drop states; verify tests that native reservation never appears provider-confirmed, external actions open provider flow, and empty states retain usable local alternatives.

## 4. Negotiation, onboarding, and existing surface refactor

- [x] 4.1 Refine Challenges and challenge negotiation detail to the Stitch team challenge screens with ordered revision cards, changed-term diffs, status pills, message treatment, tactical comparison, and sticky decision actions; verify accept, decline, counter, snackbar, back, and local-state tests continue to pass.
- [x] 4.2 Refine registration and onboarding to the Stitch registration hierarchy with compact top bars, role cards, field treatments, age/youth status, consent, help/login/back handoffs, and gradient continuation CTA while preserving validation and eligibility behavior; verify existing registration, eligibility, accessibility, and narrow-width tests.
- [x] 4.3 Refine Squad, team, match, venue, payment, and safety hubs with shared Stitch cards, headers, badges, controls, and status language without redesigning their domain workflows; verify existing hub tests plus route integration tests for opening and returning from each hub.

## 5. Visual regression and release verification

- [x] 5.1 Add representative golden or screenshot-oriented widget coverage for the shell, Home hero, pitch card, challenge detail, registration header, and key status variants at 360dp, 390dp, and 430dp widths; verify baselines render without overflow, clipped controls, or unsafe bottom-dock overlap.
- [x] 5.2 Document the Stitch reference project, token source-of-truth decision, local-resource policy, screenshot review workflow, and any intentionally deferred backend/asset work in the mobile implementation notes; verify the documented commands and reference identifiers are actionable for a future maintainer.
- [x] 5.3 Run `dart format --set-exit-if-changed`, `flutter analyze`, the complete Flutter test suite, and the supported mobile screenshot/widget checks; verify all complete without errors and that route, onboarding, safety, local fixture, booking-authority, and visual-regression coverage remains green.

## Workflow follow-up

- Review the visual baselines against the Stitch project screens before archiving the change.
- Archive the change after implementation verification is complete.
