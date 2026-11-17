# Tasks

## 1. Foundation and local presentation data

- [x] 1.1 Add the GoRouter dependency and declare the local icon, font, placeholder-image, and asset paths required by the mobile experience; verify with `flutter pub get` and `flutter analyze`.
- [x] 1.2 Add centralized Midnight theme tokens, typography, status colors, and reusable shell/card/button styles while preserving onboarding compatibility; verify with theme unit tests covering the required palette and readable text styles.
- [x] 1.3 Add immutable local presentation models and deterministic fixtures for fixtures, challenges, open games, venues, slots, and negotiation revisions; verify with unit tests that fixture loading is deterministic and performs no network or backend calls.

## 2. Router and authenticated shell

- [x] 2.1 Implement the root route graph with onboarding eligibility gating, `/home`, `/challenges`, `/pitches`, `/squad`, and the required detail routes; verify route tests for allowed entry, guarded entry, direct destination navigation, and unknown-route handling.
- [x] 2.2 Implement the shared Midnight authenticated ShellRoute with safe-area handling and four primary destinations; verify widget tests that each destination renders in the shell and that controls remain usable under bottom safe-area insets.
- [x] 2.3 Implement the NavigationController as a route-command and route-to-destination adapter without independent selected-tab authority; verify tests that direct route changes and navigation commands produce the same active destination.
- [x] 2.4 Migrate existing team, match, venue, payment, and safety entry points from direct `MaterialPageRoute` pushes to named route locations while preserving their existing behavior; verify route integration tests for opening and returning from each hub.

## 3. Home, challenges, and negotiation flows

- [x] 3.1 Implement the Midnight Home/Discover screen using local fixture, challenge, and open-game data with actionable loading, empty, and status states; verify widget tests for fixture rendering, challenge/open-game navigation, and visible local feedback after an action.
- [x] 3.2 Implement the mocked Challenges list and `/challenges/:challengeId` negotiation detail view with ordered offer revisions, changed terms, and pending-action status; verify widget tests for opening a challenge and rendering its latest offer.
- [x] 3.3 Implement local accept, decline, and counter interactions for negotiation state without backend calls; verify tests that each action updates the mocked state and shows the resulting status/snackbar.
- [x] 3.4 Add local image/icon usage and precaching for Home and challenge surfaces with fallbacks for missing optional imagery; verify an asset/widget test that the screens render without network access or remote image URLs.

## 4. Pitch discovery and smart scheduling

- [x] 4.1 Implement the Pitches destination with local venue cards, date/format/surface/distance filters, native/external source labels, and slot summaries; verify widget tests that each filter changes the displayed local results.
- [x] 4.2 Implement slot selection and local reserve interaction with explicit available, pending, confirmed, external, and sold-out states; verify tests for selecting a slot, reserving a native slot, and avoiding false native confirmation for external venues.
- [x] 4.3 Implement the offline/cached snapshot indicator, last-sync context, retry feedback, empty results, alternative-date, and notify-on-drop states; verify widget tests for each state while retaining usable local content.

## 5. Integration and regression verification

- [x] 5.1 Wire the router-owned authenticated flow into `apps/mobile/lib/main.dart` while preserving onboarding and registration callbacks; verify existing onboarding, match, team, and widget tests pass with the new entry flow.
- [x] 5.2 Add route, shell, safe-area, deep-link, and back-stack coverage for the complete Home → challenge/pitch detail → parent destination flows; verify with the mobile test suite on the supported mobile target.
- [x] 5.3 Run formatting, static analysis, and the complete Flutter test suite; verify `dart format --set-exit-if-changed`, `flutter analyze`, and `flutter test` complete without errors and document any intentionally deferred backend integrations in the mobile implementation notes.
