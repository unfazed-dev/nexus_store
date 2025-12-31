# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
