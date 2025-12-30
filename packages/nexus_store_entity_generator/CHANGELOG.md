# Changelog

## 0.1.0

- Initial release
- Code generator for type-safe entity field accessors
- Supports `@NexusEntity` annotation
- Generates:
  - `StringField<T>` for String fields
  - `ComparableField<T, F>` for numeric, DateTime, and Duration fields
  - `ListField<T, E>` for List fields
  - `Field<T, F>` for other field types
- Configurable class name suffix via `fieldsSuffix` parameter
- Ability to skip generation via `generateFields: false`
