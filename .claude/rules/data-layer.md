# NexusStore Data Layer Rules

## StoreBackend Interface
- All storage backends implement `StoreBackend` from `nexus_store` core
- Never depend on a concrete backend directly — always program to the interface
- Backend selection is a consumer concern, not a library concern

## CompositeBackend
- Use `CompositeBackend` to compose multiple backends (e.g., local + remote sync)
- Order matters: backends are queried in registration order
- Conflict resolution strategies are configurable per composite

## ReactiveStoreMixin
- Use `ReactiveStoreMixin` for reactive state on store classes
- Exposes streams for entity changes, query results, and sync status
- Consumers subscribe to streams rather than polling

## Query Builder Patterns
- Use the typed query builder API for all data retrieval
- Never construct raw queries against a backend
- Queries are backend-agnostic — the adapter translates to native queries

## EntityDefinition & EntityCodec
- Every entity requires an `EntityDefinition` describing its schema
- `EntityCodec` handles serialization/deserialization per entity
- Register definitions in the store before use
- Codecs must be pure (no side effects, no async)

## Adapter Patterns
- **Drift:** `nexus_store_drift_adapter` — SQLite via Drift ORM
- **PowerSync:** `nexus_store_powersync_adapter` — offline-first sync with PowerSync
- **Supabase:** `nexus_store_supabase_adapter` — direct Supabase client integration
- **Brick:** `nexus_store_brick_adapter` — Brick offline-first framework
- **CRDT:** `nexus_store_crdt_adapter` — conflict-free replicated data types
- Each adapter implements `StoreBackend` and lives in its own package
- Adapter-specific configuration via constructor injection

## Enforcement
- **Invariant:** `.claude/invariants/backend-interface.dart` — detects direct concrete backend usage outside adapter packages
- **AGENTS.md lines:**
  - "DO NOT depend on concrete backend implementations -> use `StoreBackend` interface"
  - "DO NOT construct raw queries against backends -> use the typed query builder API"
  - "DO NOT put side effects in `EntityCodec` implementations -> codecs must be pure"
