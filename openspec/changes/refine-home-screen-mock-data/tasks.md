# Tasks

## 1. Stitch reference and Home preview data

- [x] 1.1 Retrieve and validate the Google Stitch Home Feed reference from project `projects/10729709610488881069`, record the section/data-field mapping for implementation, and verify the selected reference and required visual deviations are documented before UI work begins.
- [x] 1.2 Extend the immutable discovery presentation models with the Home context required by the design—preview identity/avatar fallback, active team, eligibility/location summary, notification summary, local snapshot metadata, and existing fixture/challenge/open-game content—while preserving current consumers; verify model tests cover complete construction and existing discovery behavior.
- [x] 1.3 Expand the deterministic local fixtures/repository with stable identifiers, ordering, timestamps, populated and full-capacity examples, challenge statuses, and explicit local/cached metadata; verify repeated loads return identical values and a completeness test detects missing Home display dependencies.

## 2. Stitch Home composition

- [x] 2.1 Recompose `HomeScreen` into the Stitch Home Feed reading order—header/context, telemetry, upcoming fixture, discovery filters, challenges, open games, and secondary team entry—using existing Midnight/Stitch primitives and safe bottom spacing; verify a Home widget test finds the expected section order and no horizontal overflow.
- [x] 2.2 Add the mocked user/team, eligibility/location, notification, and avatar/fallback presentation while keeping the existing notification and team navigation commands; verify widget tests render each populated context value without network or authenticated-profile data.
- [x] 2.3 Refine fixture, challenge, and open-game cards, filters, badges, and local CTA treatments to match the Stitch hierarchy while preserving current route callbacks and capacity rules; verify tests cover format selection, challenge/open-game navigation, disabled full-game actions, and the existing join/challenge feedback.

## 3. Preview states and accessibility

- [x] 3.1 Add explicit Home presentation handling for loading, offline/cached snapshot, filtered results, empty sections, refresh feedback, and local action status without provider-confirmed or durable-state wording; verify widget tests cover every state and keep unrelated Home sections usable.
- [x] 3.2 Add meaningful semantics, selected/enabled states, minimum touch targets, bounded text, and resilient local image/icon fallbacks for Home controls and cards; verify accessibility/widget tests expose labels without color-only meaning and render missing optional imagery safely.
- [x] 3.3 Exercise the Home composition at 360dp, 390dp, and 430dp widths with a bottom safe-area inset and representative long/mock labels; verify no overflow, clipped CTA, or content hidden behind the authenticated navigation dock.

## 4. Documentation and integration verification

- [x] 4.1 Update the Home-focused implementation notes or test documentation with the Stitch reference, local mock-data boundary, offline/authority wording, and visual review procedure; verify every documented reference and command is actionable for a maintainer.
- [ ] 4.2 Run the focused discovery/model/widget tests plus the complete mobile test suite after integrating the Home changes; verify existing navigation, eligibility, accessibility, fixture, and hub tests remain green.
- [x] 4.3 Run `dart format --set-exit-if-changed`, `flutter analyze`, and the supported Home screenshot/widget checks, then compare stable Home anchors against the Stitch reference; verify no formatting, analysis, overflow, or visual acceptance issue remains.
