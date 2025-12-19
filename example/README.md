# nexus_store Examples

This directory contains example applications demonstrating nexus_store usage.

## Examples

### [basic_usage](basic_usage/)

A simple Dart console application demonstrating:
- Store initialization
- CRUD operations (create, read, update, delete)
- Query builder usage
- Reactive streams with watch/watchAll

**Run:**
```bash
cd basic_usage
dart pub get
dart run
```

### [flutter_widgets](flutter_widgets/)

A Flutter application demonstrating:
- NexusStoreProvider for dependency injection
- NexusStoreBuilder for reactive lists
- NexusStoreItemBuilder for single items
- StoreResultBuilder for state handling
- Loading and error states

**Run:**
```bash
cd flutter_widgets
flutter pub get
flutter run
```

## Using with Real Backends

These examples use an in-memory backend for simplicity. To use with real backends:

### PowerSync (Offline-First)

```yaml
dependencies:
  nexus_store_powersync_adapter: ^0.1.0
  powersync: ^1.17.0
```

### Supabase (Online Realtime)

```yaml
dependencies:
  nexus_store_supabase_adapter: ^0.1.0
  supabase: ^2.8.0
```

### Drift (Local SQLite)

```yaml
dependencies:
  nexus_store_drift_adapter: ^0.1.0
  drift: ^2.22.0
```

### CRDT (Conflict-Free)

```yaml
dependencies:
  nexus_store_crdt_adapter: ^0.1.0
  sqlite_crdt: ^3.0.4
```

See each adapter's README for configuration details.
