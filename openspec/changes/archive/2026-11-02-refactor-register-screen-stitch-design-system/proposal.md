# Proposal

## Why

The mobile client currently starts with a minimal date-of-birth onboarding form and has no dedicated registration screen, while the updated Stitch design defines a complete, safety-aware player registration flow. Implementing the Stitch-authored register screen now will give eligible players a clear, branded entry point and establish the interaction and validation contract needed before authentication is connected to the backend.

## What Changes

- Add a dedicated mobile registration screen reachable from the onboarding/authentication entry flow.
- Implement the Stitch "Create Your Player Pass" composition for mobile: fixed top bar with back/help actions and step indicator, identity header, role selection cards, registration form, safety notices, terms consent, primary continuation CTA, and login handoff.
- Support the Stitch role choices: Player (default), Squad Captain, and Guardian, including selected/unselected visual states and accessible radio semantics.
- Capture and validate full name, date of birth, mobile number/country prefix, email, password, and community-terms consent before continuing.
- Surface age eligibility and youth-protection status using the existing 16+ eligibility rules; do not introduce a new guardian-consent policy that conflicts with the product’s current age-policy decision.
- Add password visibility and strength feedback, input error states, and actionable validation behavior without exposing credentials in logs or UI state beyond the field.
- Establish reusable Flutter theme tokens and registration components derived from the Stitch project’s Pitch Pulse design system.
- Add widget coverage for initial rendering, role selection, valid/invalid field states, age-policy boundaries, consent gating, and the login handoff.

## Capabilities

### New Capabilities

- `identity-and-safety`: Registration behavior for eligible players, role selection, age-aware protection messaging, consent, and safe validation of identity inputs.

### Modified Capabilities

None. No main capability specifications currently exist in `openspec/specs/`; this change introduces the registration behavior as a new capability contract.

## Impact

- Flutter mobile entry flow and new registration widgets under `apps/mobile/lib/`.
- Flutter theme configuration, reusable form/role components, validation state, and navigation callbacks.
- Mobile widget tests under `apps/mobile/test/`.
- No backend schema or API contract changes are planned; the screen should expose a callback/interface that can later connect to Better Auth without coupling the UI to a provider.
- Stitch reference inputs: project `Amateur Football Community Platform` (`10729709610488881069`), screen `Auth 2: Register Screen (Midnight SRE)`, and the `Pitch Pulse` design system. The implementation target is Flutter, so Tailwind/HTML details will be translated into platform-native equivalents.
