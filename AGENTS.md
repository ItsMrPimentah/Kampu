# Google Stitch Integration

## Design Project

- Stitch Project ID: 10729709610488881069
- This is the default Stitch design project for this repository.

## Rules

- Use this project ID for all Stitch MCP operations.
- Retrieve existing screens before generating new ones.
- Reuse existing design components and patterns.
- Do not create new Stitch projects unless explicitly requested.
- Do not modify screens in other Stitch projects.

# Flutter implementation

For all work under `apps/mobile`, follow [Flutter implementation guidelines](apps/mobile/FLUTTER_GUIDELINES.md).
Keep app-wide authentication under `lib/app/auth`, feature domain code under `lib/core/<feature>`,
and screen presentation plus its Riverpod notifier controller under `lib/screens/<feature>`.
Use Flutter Hooks for ephemeral widget-local UI state. Do not add feature folders directly under `lib`.
For UI work also consult [DESIGN.md](apps/mobile/DESIGN.md),
[IMPLEMENTATION_NOTES.md](apps/mobile/IMPLEMENTATION_NOTES.md), and the applicable Stitch screen.
The project-level Pitch Pulse tokens and existing Midnight screens have distinct visual sources;
do not silently substitute one for the other. The incremental migration is tracked in
[FLUTTER_REFACTOR_PLAN.md](apps/mobile/FLUTTER_REFACTOR_PLAN.md).

Load the applicable project skill in `.agents/skills/` for tests, code generation, localization,
icon changes, and quality gates. Preserve existing behavior and test each migrated feature.
