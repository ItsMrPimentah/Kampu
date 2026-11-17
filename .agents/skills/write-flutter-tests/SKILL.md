---
name: write-flutter-tests
description: Use when creating, changing, or repairing Flutter tests.
---

# Flutter tests

Test observable behavior using flutter_test, mocktail, and standard `expect`; do not use checks.
Keep shared mocks and fakes in `apps/mobile/test/mocks`. Construct subjects with injected
dependencies, using ProviderContainer only for provider wiring or lifecycle. Cover successful and
expected failure paths, dispose resources and isolate state. Check important user-visible labels and
semantics. Run focused tests through `devbox run -q script "..."`, then the project test workflow.
