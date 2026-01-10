# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-01-11

### Added
- **Batteries-Included Pattern**: Type-safe configuration classes for reduced boilerplate
- `SupabaseColumn` class with factory methods: `text()`, `integer()`, `float8()`, `boolean()`, `timestamptz()`, `uuid()`, `jsonb()`
- `SupabaseTableConfig<T, ID>` class for bundling table configuration
- `SupabaseTableDefinition` class for schema reference
- `SupabaseBackend.withClient()` factory method for streamlined setup
- `SupabaseManager` class for multi-table coordination with shared client
- `SupabaseAuthProvider` abstract class for auth abstraction
- `DefaultSupabaseAuthProvider` implementation with Supabase Auth
- `SupabaseAuthState` enum for auth state tracking
- `SupabaseRLSPolicy` class for type-safe RLS policy definition (`select()`, `insert()`, `update()`, `delete()`)
- `SupabaseRLSRules` class with `toSql()` generation for PostgreSQL policies
- 94 unit tests for new functionality

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_supabase_adapter
- `SupabaseBackend` implementation of `StoreBackend`
- `SupabaseQueryTranslator` for PostgREST query generation
- Real-time subscriptions support
- Field name mapping for snake_case conversion
- Row Level Security (RLS) error handling
- PostgreSQL error code mapping to NexusStore errors
- Online-only backend with automatic sync status
