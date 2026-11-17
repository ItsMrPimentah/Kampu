# Tasks

## 1. Registration foundation and Pitch Pulse tokens

- [x] 1.1 Add a registration domain/presentation model for Player, Squad Captain, and Guardian roles, normalized form payloads, field errors, pending state, and navigation callbacks; verify the model compiles and role selection is constrained to one value.
- [x] 1.2 Add registration-scoped Pitch Pulse design tokens and Material 3 theme extensions for the Stitch colors, Space Grotesk/Inter typography mapping, spacing, 10px/16px/full radii, field heights, borders, and CTA gradient; verify token values are covered by a focused theme/widget test.
- [x] 1.3 Add the date-format adapter and registration validators around `evaluateEligibility`, including displayed `DD / MM / YYYY` input conversion, required-field checks, email/phone checks, password-strength calculation, and consent validation; verify invalid dates, future dates, under-16, age-16/17, and age-18+ cases pass unit tests without duplicating age-policy math.

## 2. Stitch registration screen and role interaction

- [x] 2.1 Implement the scrollable mobile registration shell with the 56dp top bar, back/help actions, step indicator, identity header, section spacing, and login handoff using the Pitch Pulse tokens; verify a widget test finds the required Stitch content and renders at narrow mobile constraints without horizontal overflow.
- [x] 2.2 Implement accessible mutually exclusive role cards for Player, Squad Captain, and Guardian with Player selected by default, selected border/glow/indicator, and radio semantics; verify widget tests cover initial selection, switching roles, and semantic checked states.
- [x] 2.3 Implement reusable themed field, country-prefix selector, youth-status notice, safety notice, terms checkbox, and iris-gradient primary CTA components; verify widget tests cover labels, focus/error presentation, control minimum sizes, and CTA disabled/enabled appearance.

## 3. Validation, safety state, and navigation behavior

- [x] 3.1 Wire full-name, date-of-birth, phone, email, password visibility/strength, and terms state into the screen controller; verify submitting incomplete data keeps the user on the screen and associates actionable errors with each invalid field.
- [x] 3.2 Add youth/adult status presentation and under-16 rejection using the existing eligibility decisions; verify youth users see protection status without a guardian-consent prerequisite, adults do not see youth-only messaging, and underage users cannot invoke continuation.
- [x] 3.3 Implement single-fire continuation, pending-state handling, back/help/login callbacks, and normalized submission payload delivery without logging credentials; verify callbacks fire only for valid input and repeated taps do not create duplicate submissions.

## 4. Entry-flow integration and verification

- [x] 4.1 Add the registration route/entry point to the mobile authentication/onboarding flow while preserving the existing eligibility-first behavior and back navigation; verify the app can open registration and return without breaking the existing onboarding widget test.
- [x] 4.2 Add responsive and accessibility widget coverage at 360dp and 430dp widths for scrollability, labels, focus order, role semantics, and keyboard-safe CTA reachability; verify tests pass without overflow or missing semantics.
- [x] 4.3 Run `fvm flutter analyze` and `fvm flutter test` from `apps/mobile`, resolve regressions, and verify the final register-screen widget suite passes alongside the existing mobile tests.
