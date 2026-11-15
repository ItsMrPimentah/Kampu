# Flutter implementation guidelines

These guidelines apply to `apps/mobile`. Existing code is being migrated incrementally; new and
changed code should follow them without breaking existing flows. See the
[refactor plan](FLUTTER_REFACTOR_PLAN.md) for migration order and current gaps.

## Architecture and style

Organize code as `lib/app` (initialization, app-wide authentication/session, navigation, theme and
localization), `lib/screens` (screen composition, screen controllers and presentation state),
`lib/core/<feature>` (feature-specific domain logic, use cases, models and repositories), and
`lib/shared` (feature-independent UI, logic and services). Do not create isolated feature folders
directly under `lib`. Authentication is app-wide: keep its session and data access under
`lib/app/auth`; its screens and screen controllers belong under `lib/screens/auth`.
Dependencies run only `app → screens → core → shared`, including direct
dependencies on any layer to the right. Shared code must not import feature code. Prefer focused,
composed classes and constructor-injected dependencies. Keep builds pure and inexpensive, split
large widgets, and use lazy lists for long collections.

Each screen owns a dedicated Riverpod notifier controller and an explicit screen state. Controllers
coordinate validation, loading, errors, feature actions and business decisions through injected
repositories or use cases; do not put those responsibilities in widgets. Providers compose and
inject dependencies; controllers and repositories do not read global providers themselves. Use
autoDispose for screen-scoped controllers and prevent async completion from updating disposed state.
Screen controllers reside next to their screen; reusable feature business rules remain in `core`.

Use Effective Dart, snake_case files, PascalCase types, camelCase members, private names beginning
with `_`, and lines no longer than 100 characters. Keep functions focused, document public APIs,
prefer const constructors and sound null safety, and avoid null assertions. Pin newly added or
updated dependencies to exact versions. Never manually edit generated Dart files.

## State, navigation and errors

Use Riverpod providers according to ownership: `Provider` for immutable services; Notifier,
AsyncNotifier or StateNotifier providers for controlled state; FutureProvider or StreamProvider for
simple async values; autoDispose for transient state. Use watch for rebuilds, read for callbacks,
listen for reactions, and refresh for refreshes. Inject non-widget dependencies instead of reading
global providers inside repositories and controllers.

### Screen and controller state

Define every screen/controller state object with `@freezed` as an immutable state type, alongside
its screen and controller. For a simple state with one shape, use a single const factory constructor
with the necessary fields:

```dart
@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    required String firstName,
    required String lastName,
    required String email,
  }) = _ProfileState;
}
```

For more complex state with mutually exclusive variants, use a sealed Freezed union with named const
factory constructors. Give each variant all parameters required for that state and handle variants
exhaustively. For example:

```dart
@freezed
sealed class ProfileState with _$ProfileState {
  const factory ProfileState.loading() = ProfileLoading;

  const factory ProfileState.loaded({
    required String firstName,
    required String lastName,
    required String email,
  }) = ProfileLoaded;

  const factory ProfileState.error({required String message}) = ProfileError;
}
```

Import `freezed_annotation` and declare the generated `.freezed.dart` part in the state source file.
Only add `fromJson`, a `.g.dart` part, and JSON generation when the state actually needs
serialization. After changing Freezed declarations, load `regenerate-dart-sources` and generate the
outputs rather than editing them manually. Apply this requirement to new and changed screen state
as the existing code is migrated.

Use `flutter_hooks` for ephemeral widget-only state and lifecycle, such as text controllers, focus,
password visibility and animation. Use `HookConsumerWidget` when a screen also watches a controller.
Do not duplicate controller-owned loading, validation, errors or business state in hooks. Dispose
hook-owned resources automatically, and keep navigation, dialogs and other presentation effects in
the UI. Every screen must have a controller even when it currently has little behavior; a shared
controller is appropriate only for deliberately shared state in addition to screen controllers.

Use GoRouter for page navigation and handle missing path parameters safely. Dialog and sheet routes
can use Flutter's Navigator. Return `Result<Val, Err>` for expected API, database and other failable
operations, using `Result.val`, `Result.err`, and `Ok` for successful void operations. Handle both
branches, preferably with `when`; avoid assertions on nullable values. Catch specific expected
exceptions at external boundaries and preserve unexpected errors with stack traces. Inject logging
into non-widget objects; avoid logging secrets or personal data.

Use Freezed and json_serializable for appropriate immutable serializable models. Use Hive CE for
key-value persistence and Drift with type converters for relational data when needed. Keep session
tokens in platform secure storage. Generate code using the applicable project skill.

## UI and accessibility

Follow [DESIGN.md](DESIGN.md), [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md), and the
applicable Stitch screen; reuse existing tokens and components. Configure the app theme in
`lib/app/theme.dart` and access extensions through `Theme.of(context)`. Import shared UI through
`package:showtime_mobile/shared/ui/ui.dart` once migrated, and use `AppIcons` for app icon resources.
Do not introduce runtime-hosted visual assets. Support safe areas, text scaling, and 360–430dp
layouts. Provide accessible labels for interactive icons, test important semantics, and maintain
contrast of at least 4.5:1 for normal text and 3:1 for large text. Communicate status in text as well
as color.

## Tests and verification

All behavior changes require focused tests. Load `write-flutter-tests`; use flutter_test, mocktail,
standard `expect`, shared mocks/fakes in `test/mocks`, and test both success and failure for failable
operations. Construct objects directly unless testing provider wiring or lifecycle; clean up state.
Patrol is available for suitable integration tests. After code changes load
`run-project-quality-gates`; run formatting, tests, and the project's broader analyze workflow through
Devbox. Review generator/formatter output and the final diff for unrelated files and secrets.
