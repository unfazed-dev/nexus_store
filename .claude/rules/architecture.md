# Package Architecture Rules

## Public API
- Every package exposes its public API via a barrel file: `lib/xxx.dart`
- All implementation details live in `lib/src/`
- Barrel files re-export only from `lib/src/`
- Never import from another package's `lib/src/` directory

## Dependency Direction (STRICT)
- `nexus_store` (core) — no dependencies on other nexus packages
- Adapters (`drift_adapter`, `powersync_adapter`, `supabase_adapter`, `brick_adapter`, `crdt_adapter`) — depend on core only
- Bindings (`bloc_binding`, `riverpod_binding`, `riverpod_generator`, `signals_binding`) — depend on core only
- Generators (`nexus_store_generator`, `nexus_store_entity_generator`) — depend on core only
- `nexus_store_flutter_widgets` — depends on core only
- NO reverse dependencies (adapters must not depend on bindings, core must not depend on adapters)
- NO circular dependencies between any packages

## Interface Naming
- Use `InterfaceXxxRepository` (NOT `IXxxRepository`)
- Co-locate interface with implementation in the same directory

## Import Rules
- Cross-package imports use the barrel file: `package:nexus_store/nexus_store.dart`
- Never use relative imports across package boundaries
- Within a package, prefer relative imports for `lib/src/` internals

## Enforcement
- **Invariant:** `.claude/invariants/cross-package-src-import.dart` — detects imports of another package's `lib/src/`
- **Invariant:** `.claude/invariants/dependency-direction.dart` — detects reverse or circular dependencies
- **AGENTS.md lines:**
  - "DO NOT import from another package's `lib/src/` -> use the barrel file"
  - "DO NOT create reverse dependencies (adapter depending on binding, core depending on adapter)"
  - "DO NOT use `IXxxRepository` naming -> use `InterfaceXxxRepository`"
