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
- Authentication HTTP/secure storage are separated into `app/auth/auth_repository.dart`, with
  explicit Result handling and focused restoration, login, and failure tests. The client is owned by
  a Riverpod provider. Shared visual tokens/components and Result are in `lib/shared`; the app theme
  is configured in `lib/app/theme.dart`.
- Community HTTP calls now use an injected repository with explicit failures and a session token
  supplied at request time. Community screens live in `screens/community`, use GoRouter for page
  navigation, and have success, failure, retry and deep-link tests. List rendering is lazy.
- The analyze workflow checks import direction for migrated `screens`, `core`, and `shared` code.
- Login, phone verification, onboarding, local discovery, pitches, challenges, squad, teams,
  matches, venues, payments, and safety have screen-scoped Riverpod controllers in `screens/`.
  Their widget-local text and visibility state uses Flutter Hooks. Shared preview data is in
  `core/discovery`, and app-wide authentication and routing are in `app/`.
- Legacy top-level feature re-exports have been removed, and the analyzer workflow rejects Dart
  source directories outside `app`, `screens`, `core`, and `shared`.
- Registration and the four authenticated community screens now have screen-scoped Riverpod
  controllers and use Hooks for local form controls. The app session is exposed through a Riverpod
  notifier, which drives the production router and session actions.
- Remaining: the session notifier adapts a legacy ChangeNotifier client; replace that client with
  notifier-owned session state. The community presentation still combines multiple features and
  dynamic response maps in one file. Split feature widgets and adopt typed models.
- Drift is not currently needed by an existing local relational-data use case. Existing visual
  authority is described in DESIGN.md.
