---
name: regenerate-dart-sources
description: Use after changing Freezed, json_serializable, Drift, or other generated Dart declarations.
---

# Regenerate Dart sources

From the repository root run `devbox run -q script "cd apps/mobile; ^fvm dart run build_runner build --delete-conflicting-outputs"`.
Never edit generated files by hand. Inspect all generated changes and run relevant tests and quality
gates. Localization generation has a separate workflow.
