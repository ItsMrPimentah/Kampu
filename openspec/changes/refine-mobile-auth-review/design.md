# Design

## Context

The current working tree is undergoing an unrelated Flutter migration. Preserve those edits. Stitch references are login `e64567a85b79497abc5152f8cc23b7d8`, registration `6bcb4180bff5453ab06b5fbf86598461`, and OTP `1cdfda65eb81493da0a91ca88067b1cc` in project `10729709610488881069`. The review was source-level; exact visual fidelity is not verified by a current capture.

## Goals / Non-Goals

**Goals:** Improve confirmed usability and visual hierarchy while keeping auth and navigation behavior reliable.

**Non-Goals:** No server changes, invented reset or legal links, invented cooldowns, unsupported number edits, or new age policy.

## Decisions

- Reuse native Flutter inputs and Midnight components. Keep the existing single OTP input, preserving autofill, paste, and accessibility; six decorative slots are not worth risking these behaviors in this focused pass.
- Distinguish known failed SMS delivery from unknown delivery. The session endpoint does not supply delivery status, so do not infer successful delivery on restoration or failure on login.
- Validate six digits locally, retain the server as authoritative, and use action-specific generic errors without inventing a rate limit duration.
- Use neutral phone imagery and actionable navigation controls. Keep the existing consent semantics and do not invent URLs for missing legal documents.
- Retain project-approved Inter and the existing pilot country defaults rather than copying mock-only claims and integrations.
- Sign-in refinement: use a centered ShowTime header, geometric emblem and matchday badge, muted copy, locally styled recessed phone/email selector and labeled input fields, 12dp action corners, and a subtle Midnight grid and glow, guided by login Stitch `e64567a85b79497abc5152f8cc23b7d8`. Retain functional Flutter input semantics, keyboard, autofill, password visibility, loading, and registration callback. Do not copy unsupported password recovery, social/biometric login, persistence toggle, remote assets, or claims. Keep Inter as a documented font deviation.

## Risks / Trade-offs

- [Unverified visual fidelity] → Run responsive widget tests and report lack of rendered screenshot comparison if unavailable.
- [Unknown backend failures] → Do not claim specific server error categories without contract support.

## Verification

Focused widget and controller tests and the full Flutter format, test, and analysis gates passed. Widget layout tests cover 360–430dp and enlarged text, but no current device screenshots were compared with Stitch; visual fidelity and device-level SMS autofill remain unverified.

Sign-in follow-up: focused tests and all Flutter gates passed, including 360–430dp and up to 2× text. The attempted iOS simulator build failed with `-objc_abi_version '-Xlinker' not supported`, so no rendered Stitch comparison was possible. The badge sits below the heading, unlike the reference; the CTA gradient is darkened for text contrast. The phone field includes persistent international-code guidance.
