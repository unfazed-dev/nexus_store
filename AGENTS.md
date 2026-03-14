# AGENTS.md - NexusStore

## DO NOT Lines

- DO NOT import from `package:xxx/src/` across packages -> use barrel exports
- DO NOT create circular dependencies between packages
- DO NOT use `static const` with obfuscated envied fields -> use `static final`
- DO NOT commit `.g.dart` files -> they are generated
- DO NOT modify generated files directly -> modify source and regenerate
- DO NOT skip `melos bootstrap` after pubspec changes
- DO NOT use `IXxxRepository` naming -> use `InterfaceXxxRepository`
