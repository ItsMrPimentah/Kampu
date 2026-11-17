# Design

## Context

The mobile client currently uses `ThemeData.dark(useMaterial3: true)` and renders a minimal `OnboardingScreen` with a date-of-birth field before entering the authenticated shell. There is no registration form, authentication provider integration, or mobile design-token layer. The existing `evaluateEligibility` function is the policy source for valid dates, the 16+ minimum, and youth/adult classification.

The Stitch project `Amateur Football Community Platform` was inspected through the Stitch MCP. The target screen is `Auth 2: Register Screen (Midnight SRE)` and its current HTML uses the `Pitch Pulse` visual system: `#0F101A` void canvas, `#151621` carbon surfaces, `#1F2433` gunmetal borders, `#98A4F7` periwinkle focus/active color, Space Grotesk display/labels, Inter body text, 10px inputs, 16px cards, pill CTAs, and 16dp mobile margins.

## Goals / Non-Goals

**Goals:**

- Translate the Stitch screen into a native Flutter mobile experience without embedding web HTML or requiring a web runtime.
- Keep registration UI state, validation, and navigation callbacks testable independently from Better Auth or a network client.
- Reuse the existing age-policy calculation and make youth protection visible without adding a guardian-consent workflow.
- Establish reusable design tokens and components for future auth screens while matching the register reference.
- Preserve accessible semantics for role selection, labels, validation errors, and actions.

**Non-Goals:**

- Implement Better Auth, account persistence, OTP delivery, or server registration endpoints.
- Change the existing age policy, safety authorization rules, or backend schema.
- Add guardian authorization, wallet/payment behavior, or a new age-verification provider.
- Rebuild unrelated screens to the Stitch system in this change.

## Decisions

### Use a native Flutter screen with a presentation-state boundary

Create a registration screen and a small state/model boundary that owns role, input values, validation results, password visibility/strength, consent, and pending submission state. Expose callbacks for back, help, login, and valid continuation. This keeps the UI provider-agnostic and lets a later Better Auth integration consume a stable normalized payload.

**Alternative considered:** embedding the downloaded Stitch HTML in a WebView. Rejected because the app is Flutter-native, existing dependencies do not include a WebView, and WebView content would make accessibility, testing, theme integration, and platform navigation less predictable.

### Reuse `evaluateEligibility` as the registration age-policy authority

Normalize the register screen’s date input into the existing `YYYY-MM-DD` value expected by `evaluateEligibility`, or add a presentation adapter around the displayed `DD / MM / YYYY` format. Convert validation exceptions into field-level messages and a youth/adult status model. The adapter must preserve invalid-calendar-date and future-date handling rather than duplicating age math.

**Alternative considered:** calculating age directly in the new widget. Rejected because it risks divergent boundary behavior and would duplicate an existing tested policy function.

### Introduce a focused Pitch Pulse token layer over Material 3

Define reusable app-level colors, text styles, spacing, radii, and component constants derived from the live Stitch reference:

- Canvas: `#0F101A`; card/surface: `#151621`; recessed field: `#0F101A`.
- Border: `#1F2433`; primary active/focus: `#98A4F7`; iris: `#5B63D3`; gradient endpoint: `#7C87F7`.
- High-emphasis text: `#F9FAFB`; secondary text: `#C9D3EE`; muted text: `#646E87`.
- Space Grotesk for headings/labels and Inter-equivalent Flutter text for body/data copy, with display, headline, title, body, and label scales matching the Stitch sizes.
- 4px base spacing, 12px mobile gutters where needed, 16px mobile page margins, 10px field radius, 16px cards, 9999px CTA radius, and 48px minimum control height.

Use Material semantics and focus behavior, but style the controls with these tokens instead of relying on default Material colors. The primary CTA should use the Stitch iris-to-periwinkle gradient and restrained glow; cards should use tonal depth and hairline borders rather than generic elevation.

**Alternative considered:** replacing the app theme globally. Rejected for now because unrelated existing screens are not yet migrated and a global change would increase visual regression scope.

### Model roles as a finite, accessible selection

Represent Player, Squad Captain, and Guardian as a finite enum/value model. Render the entire card as the activation target and expose radio-group/radio semantics with a single selected value. Player is selected initially. The Guardian role is a registration role label only; it does not grant or require guardian authorization and cannot bypass the 16+ eligibility policy.

### Keep validation local and explicit

Validate on submit and, where useful, on field change after the first submit attempt. Use non-sensitive error state keyed by field; never log password values or include them in analytics/debug output. Password strength is a visual policy signal, not a server authorization claim. The submit callback receives a normalized payload only after all client requirements pass; the callback contract must allow a caller-provided pending/error result without coupling the widget to transport details.

### Preserve vertical mobile composition

Use a scrollable single-column layout with a fixed 56dp top bar, content max width appropriate for mobile, 16dp outer margins, 24dp section spacing, compact 12dp field spacing, and bottom padding for the CTA/login handoff. This follows the Stitch screen’s mobile-first hierarchy and avoids clipped content when the keyboard opens.

## Risks / Trade-offs

- **[Risk]** The Stitch reference includes web-specific visual effects and fonts that may not be available identically in Flutter. → Use system/fallback font mapping and tokenized approximations; validate screenshots at 360dp and 430dp instead of relying on pixel equality.
- **[Risk]** The reference copy describes guardian consent for minors, conflicting with the existing product policy. → Keep the role card but use the existing 16+ youth policy and explicitly exclude guardian authorization from behavior and acceptance tests.
- **[Risk]** Adding a new registration screen without a backend can create a misleading completion state. → Stop at a callback/verification handoff and represent pending/error states; do not claim account creation locally.
- **[Risk]** Migrating only the register screen creates temporary visual inconsistency. → Scope token ownership to registration and document the token layer so later auth screens can reuse it without changing unrelated screens.
- **[Risk]** A long form may be difficult to use with the keyboard. → Make the content scrollable, preserve field focus order, keep the primary action reachable, and cover narrow viewport/widget behavior in tests.

## Migration Plan

1. Add the tokenized registration components and screen behind a navigation callback; keep the existing onboarding flow as the source of eligibility policy.
2. Route the register entry point to the new screen while retaining a back action to the previous flow and a login callback for future authentication wiring.
3. Run Flutter analysis and widget tests, including age boundaries and registration validation.
4. If rollout exposes visual or navigation regressions, revert the registration route to the existing onboarding entry while preserving the isolated new components for follow-up.
5. When Better Auth is integrated later, connect the normalized continuation payload and pending/error callbacks without changing the visual contract.
