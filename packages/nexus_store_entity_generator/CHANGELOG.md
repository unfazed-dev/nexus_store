# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2024-12-31

### Added
- Initial release of nexus_store_entity_generator
- Code generator for type-safe entity field accessors
- Supports `@NexusEntity` annotation
- Generates field accessor classes:
  - `StringField<T>` for String fields
  - `ComparableField<T, F>` for numeric, DateTime, and Duration fields
  - `ListField<T, E>` for List fields
  - `Field<T, F>` for other field types
- Configurable class name suffix via `fieldsSuffix` parameter
- Ability to skip generation via `generateFields: false`
