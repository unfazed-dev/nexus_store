# Installation Guide

Complete installation patterns for nexus_store packages.

## Git Installation (All 13 Packages)

### Core Package (Required)

```yaml
dependencies:
  nexus_store:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store
```

### Flutter Widgets (For Flutter Apps)

```yaml
dependencies:
  nexus_store_flutter_widgets:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_flutter_widgets
```

### State Management Bindings (Choose One)

```yaml
dependencies:
  # Riverpod binding
  nexus_store_riverpod_binding:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_riverpod_binding

  # Bloc binding
  nexus_store_bloc_binding:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_bloc_binding

  # Signals binding
  nexus_store_signals_binding:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_signals_binding
```

### Storage Adapters (Choose One)

```yaml
dependencies:
  # PowerSync - Offline-first with sync
  nexus_store_powersync_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_powersync_adapter

  # Supabase - Real-time PostgreSQL
  nexus_store_supabase_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_supabase_adapter

  # Drift - Local SQLite
  nexus_store_drift_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_drift_adapter

  # Brick - Offline-first ORM
  nexus_store_brick_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_brick_adapter

  # CRDT - Peer-to-peer sync
  nexus_store_crdt_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_crdt_adapter
```

### Code Generators (Dev Dependencies)

```yaml
dev_dependencies:
  # Lazy field generator
  nexus_store_generator:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_generator

  # Type-safe entity fields
  nexus_store_entity_generator:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_entity_generator

  # Riverpod provider generator
  nexus_store_riverpod_generator:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_riverpod_generator

  build_runner: ^2.4.0
```

## Pub.dev Installation (When Published)

```yaml
dependencies:
  nexus_store: ^0.1.0
  nexus_store_flutter_widgets: ^0.1.0
  nexus_store_powersync_adapter: ^0.1.0
  nexus_store_riverpod_binding: ^0.1.0

dev_dependencies:
  nexus_store_generator: ^0.1.0
  nexus_store_entity_generator: ^0.1.0
  nexus_store_riverpod_generator: ^0.1.0
  build_runner: ^2.4.0
```

## Common Combinations

### Offline-First Flutter App (Recommended)

```yaml
dependencies:
  nexus_store:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store
  nexus_store_flutter_widgets:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_flutter_widgets
  nexus_store_powersync_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_powersync_adapter
  nexus_store_riverpod_binding:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_riverpod_binding

dev_dependencies:
  nexus_store_entity_generator:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_entity_generator
  nexus_store_riverpod_generator:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_riverpod_generator
  build_runner: ^2.4.0
```

### Real-Time Supabase App

```yaml
dependencies:
  nexus_store:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store
  nexus_store_flutter_widgets:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_flutter_widgets
  nexus_store_supabase_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_supabase_adapter
  nexus_store_signals_binding:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_signals_binding
```

### Local-Only with Encryption

```yaml
dependencies:
  nexus_store:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store
  nexus_store_flutter_widgets:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_flutter_widgets
  nexus_store_drift_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_drift_adapter
  flutter_secure_storage: ^9.0.0  # For encryption key storage
```

### Full HIPAA/GDPR Compliance

```yaml
dependencies:
  nexus_store:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store
  nexus_store_flutter_widgets:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_flutter_widgets
  nexus_store_powersync_adapter:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_powersync_adapter
  nexus_store_bloc_binding:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store_bloc_binding
  flutter_secure_storage: ^9.0.0
```

Configuration for compliance:

```dart
final store = NexusStore<Patient, String>(
  backend: PowerSyncBackend(powerSync, 'patients'),
  config: StoreConfig(
    enableAuditLogging: true,  // HIPAA
    enableGdpr: true,          // GDPR
    encryption: EncryptionConfig.sqlCipher(
      keyProvider: () async => await secureStorage.read(key: 'db_key'),
      kdfIterations: 256000,
    ),
  ),
  auditService: AuditService(
    storage: auditStorage,
    actorProvider: () async => currentUser.id,
    hashChainEnabled: true,
  ),
  subjectIdField: 'patientId',
);
```

## Build Runner Configuration

Create or update `build.yaml`:

```yaml
targets:
  $default:
    builders:
      nexus_store_generator:
        enabled: true
      nexus_store_entity_generator:
        enabled: true
      nexus_store_riverpod_generator:
        enabled: true
```

Run generators:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Watch mode for development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Environment Requirements

- Dart SDK: ^3.5.0
- Flutter SDK: >=3.22.0 (for Flutter packages)

## Troubleshooting

### Git Dependency Resolution

If you encounter dependency conflicts:

```yaml
dependency_overrides:
  nexus_store:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store
```

### Version Pinning with Git

Pin to a specific commit:

```yaml
dependencies:
  nexus_store:
    git:
      url: https://github.com/unfazed-dev/nexus_store.git
      path: packages/nexus_store
      ref: v0.1.0  # or commit SHA
```
