# Flutter refactor plan

Migrate incrementally, preserving the existing authenticated flows, legacy previews, and Stitch
screen-specific styling. Each slice must include focused tests and pass the project quality gates.

1. Establish documented instructions, skills, a consistent Flutter SDK and Devbox/CI workflows.
2. Introduce the `app → screens → core → shared` structure, a shared Result and logging boundary,
   Riverpod, reusable UI exports and icon conventions. Enforce import direction for migrated code.
3. Separate authentication, session storage and community transport from state; use injected
   repositories and explicit failures. Migrate routing and preserve restoration, verification,
   retry and sign-out behavior.
4. Split community screens by feature; migrate discovery, challenges, games, teams and notifications
   to typed models, controllers and GoRouter pages with success and failure coverage.
5. Migrate registration, pitches, matches, payments, venues and safety; retain legacy previews until
   their replacement is verified. Adopt Freezed/JSON generation and persistence where appropriate.
6. Consolidate theme configuration and shared UI, validate accessibility and visual baselines, and
   run complete formatting, analysis and test gates. Review generated files and final changes.

## Migration status

- Devbox workflows, pinned Flutter 3.47.9, CI, guidelines, and project skill instructions are in place.
- Authentication HTTP/secure storage are separated into `core/auth/auth_repository.dart`, with
  explicit Result handling and focused restoration, login, and failure tests. The client is owned by
  a Riverpod provider. Shared visual tokens/components and Result are in `lib/shared`, with legacy
  exports for existing imports; the app theme is configured in `lib/app/theme.dart`.
- The analyze workflow checks import direction for migrated `core` and `shared` code.
- Remaining: `AuthClient` still provides community HTTP calls, authentication state remains a
  ChangeNotifier rather than a Riverpod notifier, and the router and screens still use legacy paths.
  `community_screen.dart` still combines multiple features, direct page navigation, and broad catches.
  Migrate these in independently tested slices before enforcing import direction across all code.
- Drift is not currently needed by an existing local relational-data use case. Existing visual
  authority is described in DESIGN.md.
