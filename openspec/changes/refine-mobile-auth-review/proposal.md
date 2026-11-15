# Proposal

## Why

The Stitch review identified misleading verification feedback and a premature phone validation indicator, alongside authentication presentation and accessibility gaps. Correcting these makes the existing flows clearer without promising unsupported services.

## What Changes

- Refine the login, registration, and verification screens using the Midnight Stitch references and existing Flutter components.
- Present truthful SMS delivery and action-specific feedback, and validate OTP length before submission.
- Remove premature validation signals and improve registration branding and accessible navigation.
- Add focused tests and run the project's Flutter quality gates.

## Capabilities

### New Capabilities
- `mobile-auth-presentation`: Truthful, accessible presentation of the existing mobile authentication flow.

### Modified Capabilities

None in the current working tree.

## Impact

Flutter auth presentation, controllers, and tests. No API changes, new legal destinations, password recovery, or phone-edit flow are introduced. Existing OpenSpec deletions in the working tree are left untouched.
