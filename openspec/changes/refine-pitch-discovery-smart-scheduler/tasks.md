# Tasks

## 1. Reference and local fixtures

- [x] 1.1 Re-fetch and inspect project `10729709610488881069` screen `245ad80116ea4d0293c73567a3677282` before UI work; record source and review the Midnight tokens, Flutter guidelines and existing components against `design.md`.
- [x] 1.2 Adapt pitch fixture data and any required models with coherent full dates, distinct formats/surfaces/distances and native/external/available/pending/sold-out cases; verify deterministic data, displayed timestamps and shared Home/challenge consumers with focused tests.

## 2. Scheduler behavior

- [x] 2.1 Implement controller-owned combined search, full-date, format, surface and distance filters, reset paths, date-specific slots and derived counts; test intersections, case-insensitive search, same day across months/years, reset and no matches.
- [x] 2.2 Preserve slot selection and native local reservation, external feedback, local retry and demo notification acknowledgement; test eligibility, stale selection clearing, local-only state, reset on disposal and absence of external confirmation.
- [x] 2.3 Derive selected-slot prices and any rounded split estimate from fixture values and roster size; test changes across prices and unsupported roster sizes. Migrate changed screen state to Freezed and regenerate outputs using the project skill; verify generated files and controller tests.

## 3. Flutter presentation

- [x] 3.1 Build the Stitch-aligned Midnight header/status, search, scheduler, venue cards and empty state using existing shared widgets and shell; verify populated, sold-out fixture, empty, alternative-date and clear-filter interactions in focused widget tests.
- [x] 3.2 Replace simulated live sync, provider, guarantee and alert claims with truthful local-demo wording; test retry, native confirmation, external action and alert feedback and confirm no provider or notification integration is invoked.
- [ ] 3.3 Support 360/390/430dp, safe areas, enlarged text, dock clearance, semantic labels and selected states; run responsive/semantics widget tests and check required text contrast.

## 4. Integration and visual acceptance

- [ ] 4.1 Capture rendered populated and empty Flutter states at representative widths and compare them directly with the Stitch reference for hierarchy, scheduler, cards, dock, colors and content; document intentional truthfulness, branding, assets and layout deviations, or report a blocked capture explicitly.
- [x] 4.2 Run affected Flutter tests including existing shared fixture and navigation coverage, then use `run-project-quality-gates` for formatting, tests and analysis via the prescribed workflow; review generated output and final diff for unrelated edits.

## Verification follow-up

- Shell widget tests cover 360/390/430dp at 1.5× text and selected slot semantics; they do not prove last-action dock clearance or constitute a complete rendered contrast audit.
- The user-supplied `stitch-screenshots/pitch-discovery-smart-scheduler.jpg` was reviewed directly. The scheduler, local status strip, search and filter controls, selected slot, cost and cards were refined against it; three bundled sample thumbnails are cropped from that reference. Header and navigation were explicitly excluded from the requested polish.
- Captured the updated top, selected and empty states on iPhone 17 Pro (402 logical pixels) and inspected 1.5× text. The enlarged image label is readable. A one-pixel dock overflow remains at 1.5×; the shared navigation is outside the requested scope. Other widths have widget tests but not simulator captures.
- Simulator build succeeded with host Xcode 26.4 and Flutter 3.47.9; the Devbox/Nix SDK still failed. Captured the actual `/pitches` route at 402 logical pixels on iPhone 17 Pro, both populated and empty. Compared the captures with the Stitch HTML: Midnight surfaces, the date strip, venue cards and slot grid are recognizable; the screen retains a taller, more accessible scheduler, a ShowTime dock, local-demo copy and bundled placeholder images instead of the reference's hosted pitch photos. Empty-state grouping, useful alternative dates and selected cost presentation were refined after the comparison.
- Visual coverage remains partial: the Stitch screenshot download was truncated, and simulator captures at the other target widths, enlarged text, selected-cost state and final dock clearance remain outstanding. Source color-pair checks are not a complete rendered contrast audit.
- Follow-up: captured populated, selected and empty states on iPhone 17 Pro (402 logical pixels), including selected slots at 1.5× text. Slot rows now align despite wrapped status text; the shared dock adapts to enlarged text and the previously observed 1-pixel overflow no longer appears. Widget tests cover slot alignment at 1×/1.5×/2× and dock containment at 1.5×/2×. Other simulator widths and final-action dock clearance remain unverified.
- Adapt follow-up: widget tests verify the last pitch action clears the dock and can be activated with 34dp bottom safe area at 360/390/430dp and 1×/1.5×/2× text. Dock labels are checked against truncation at each size and remain on one line at enlarged sizes. An iPhone 17 Pro simulator capture with a 360dp constrained app and simulated 2× text confirms the reflowed dock visually; 390/430dp and physical-device renders remain unverified. This is not a full rendered contrast audit.
