# Flutter implementation guidelines

These guidelines apply to `apps/mobile`. Existing code is being migrated incrementally; new and
changed code should follow them without breaking existing flows. See the
[refactor plan](FLUTTER_REFACTOR_PLAN.md) for migration order and current gaps.

## Architecture and style

Organize code as `lib/app` (initialization, navigation, theme and localization), `lib/screens`
(presentation), `lib/core` (feature logic and services), and `lib/shared` (feature-independent UI,
logic and services). Dependencies run only `app → screens → core → shared`, including direct
dependencies on any layer to the right. Shared code must not import feature code. Prefer focused,
composed classes and constructor-injected dependencies. Keep builds pure and inexpensive, split
large widgets, and use lazy lists for long collections.

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
