# Code Generation Rules

## Build Runner
- Run: `dart run build_runner build --delete-conflicting-outputs`
- Melos: `melos run build:runner` to run build_runner across all packages
- Always run after model or annotation changes

## Generated Files
- `.g.dart` files are generated — NEVER edit manually
- `.g.dart` files are gitignored — do not commit them
- Use `part` directives to include generated files: `part 'my_model.g.dart';`

## Regeneration Triggers
- Model class changes (fields, constructors)
- Annotation changes (`@JsonSerializable`, `@DriftTable`, custom annotations)
- Entity definition changes
- Generator template changes (in `nexus_store_generator` / `nexus_store_entity_generator`)

## Generator Packages
- `nexus_store_generator` — core code generation for NexusStore
- `nexus_store_entity_generator` — entity-specific code generation
- Both use `build_runner` and `source_gen`

## Enforcement
- **Manual only:** Never editing `.g.dart` files is enforced by code review
- **AGENTS.md lines:**
  - "DO NOT edit `.g.dart` files manually -> run `dart run build_runner build --delete-conflicting-outputs`"
  - "DO NOT commit `.g.dart` files -> they are gitignored"
