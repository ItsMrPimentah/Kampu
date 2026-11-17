---
name: run-project-quality-gates
description: Use after Flutter code changes to run the project's required quality gates.
---

# Project quality gates

From the repository root run `devbox run -q format`, `devbox run -q test`, and
`devbox run -q analyze`. Analyze checks formatting as well as Flutter static analysis. Run focused
tests for each changed behavior before the full suite. Inspect formatter and generator changes and
the final diff; report any failure or unavailable gate explicitly.
