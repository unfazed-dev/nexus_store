# Troubleshooting Guide

Common issues and solutions when using nexus_store.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Encryption Issues](#encryption-issues)
- [Sync Issues](#sync-issues)
- [Backend Adapter Issues](#backend-adapter-issues)
- [Performance Issues](#performance-issues)
- [Code Generation Issues](#code-generation-issues)

---

## Installation Issues

### Dependency conflicts with rxdart

**Symptom**: Version solving failed for rxdart

**Solution**: Ensure you're using compatible versions:
```yaml
dependencies:
  nexus_store: ^0.1.0
  rxdart: ^0.28.0  # Use same major version
```

### Flutter version mismatch

**Symptom**: `The current Flutter SDK version is X.X.X`

**Solution**: nexus_store requires Flutter 3.22.0+:
```bash
flutter upgrade
flutter --version  # Verify 3.22.0+
```

### Melos bootstrap fails

**Symptom**: `melos bootstrap` fails with dependency errors

**Solution**:
```bash
# Clean and retry
melos clean
rm -rf ~/.pub-cache
melos bootstrap
```

---

## Encryption Issues

### "Encryption key not found" error

**Symptom**: `Exception: Encryption key not found`

**Cause**: Key provider returned null or key wasn't initialized

**Solution**:
```dart
// Ensure key exists before creating store
Future<void> initializeEncryption() async {
  final storage = FlutterSecureStorage();
  final keyExists = await storage.containsKey(key: 'encryption_key');

  if (!keyExists) {
    // Generate and store a new key
    final key = List.generate(32, (_) => Random.secure().nextInt(256));
    await storage.write(
      key: 'encryption_key',
      value: base64Encode(Uint8List.fromList(key)),
    );
  }
}
```

### "Version mismatch" decryption error

**Symptom**: `EncryptionException: Version mismatch`

**Cause**: Data encrypted with different key version

**Solution**:
1. Check your encryption config version matches stored data
2. If rotating keys, re-encrypt all data with the new version
3. Keep old key available during migration period

```dart
// During key rotation, handle both versions
try {
  return await decryptWithV2(data);
} on EncryptionException catch (e) {
  if (e.message.contains('Version mismatch')) {
    // Fall back to old key
    return await decryptWithV1(data);
  }
  rethrow;
}
```

### Salt storage errors

**Symptom**: `SecureSaltStorage: Error reading salt`

**Cause**: Platform secure storage unavailable or corrupted

**Solution**:
```dart
// On Android, ensure proper configuration
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,  // Reset on corruption
  ),
);
```

For Android, also ensure `minSdkVersion` is 23+ in `android/app/build.gradle`.

---

## Sync Issues

### Sync stuck in pending state

**Symptom**: `syncStatus` shows pending but never completes

**Cause**: Network issues or backend unavailable

**Solution**:
```dart
// Check pending changes
final count = await store.pendingChangesCount.first;
print('Pending changes: $count');

// Force retry
await store.sync();

// Or clear pending (use with caution)
await store.clearPendingChanges();
```

### Conflict resolution not working

**Symptom**: Data overwrites instead of merging

**Cause**: Default conflict strategy may not suit your use case

**Solution**:
```dart
// Configure conflict resolution
final config = StoreConfig(
  conflictResolution: ConflictResolution.serverWins,
  // Or use custom resolver:
  // conflictResolver: (local, remote) => mergeEntities(local, remote),
);
```

### Delta sync missing changes

**Symptom**: Some changes not syncing

**Cause**: Timestamp drift or incorrect delta tracking

**Solution**:
```dart
// Force full sync
await store.fullSync();

// Check last sync timestamp
final lastSync = await store.lastSyncTimestamp;
print('Last sync: $lastSync');
```

---

## Backend Adapter Issues

### PowerSync: "sqlite3 library not found"

**Symptom**: `DynamicLibrary.open failed`

**Cause**: SQLite3 native library not included

**Solution** (macOS):
```bash
# The library should be bundled automatically
# If not, check your Podfile includes:
pod 'sqlite3'
```

**Solution** (iOS):
Add to `ios/Podfile`:
```ruby
pod 'sqlite3', '~> 3.45.0'
```

### PowerSync: "OFFSET without LIMIT" error

**Symptom**: SQL syntax error with offset queries

**Cause**: SQLite requires LIMIT when using OFFSET

**Solution**: This is fixed in nexus_store 0.1.0+. Update your package:
```yaml
dependencies:
  nexus_store_powersync_adapter: ^0.1.0
```

### Supabase: "JWT expired" error

**Symptom**: Authentication errors after app backgrounded

**Solution**:
```dart
// Enable auto-refresh
final client = SupabaseClient(
  url,
  anonKey,
  authOptions: AuthClientOptions(
    autoRefreshToken: true,
  ),
);
```

### Drift: Generated code out of sync

**Symptom**: Type errors in generated `.g.dart` files

**Solution**:
```bash
# Regenerate code
dart run build_runner build --delete-conflicting-outputs

# Or watch mode during development
dart run build_runner watch
```

---

## Performance Issues

### Slow queries on large datasets

**Symptom**: `getAll()` takes seconds

**Solution**: Use pagination and queries:
```dart
// Bad - loads everything
final all = await store.getAll();

// Good - paginated
final page = await store.getAll(
  query: store.createQuery()
    .orderBy('createdAt', descending: true)
    .limit(50),
);

// Good - cursor pagination
final result = await store.getPage(
  query: query,
  cursor: lastCursor,
  pageSize: 20,
);
```

### Memory pressure warnings

**Symptom**: App receiving memory warnings, cache evictions

**Solution**:
```dart
// Configure cache limits
final config = StoreConfig(
  cacheConfig: CacheConfig(
    maxEntries: 1000,  // Reduce if needed
    maxMemoryMB: 50,
    evictionStrategy: EvictionStrategy.lru,
  ),
);

// Or use lazy loading for large entities
final user = await store.get(
  id,
  lazyFields: {'profileImage', 'attachments'},
);
```

### Circuit breaker tripping frequently

**Symptom**: Operations failing with circuit breaker open

**Solution**:
```dart
// Adjust thresholds
final config = StoreConfig(
  circuitBreakerConfig: CircuitBreakerConfig(
    failureThreshold: 10,     // More failures before tripping
    resetTimeout: Duration(seconds: 30),
    halfOpenMaxCalls: 3,
  ),
);

// Monitor state
store.circuitBreakerState.listen((state) {
  if (state == CircuitState.open) {
    showOfflineIndicator();
  }
});
```

---

## Code Generation Issues

### "Could not find asset" during build

**Symptom**: build_runner can't find source files

**Solution**:
```bash
# Clean build cache
dart run build_runner clean

# Ensure pubspec.yaml has build_runner in dev_dependencies
flutter pub get
dart run build_runner build
```

### Generated providers not found

**Symptom**: `NexusStoreProviders` class not generated

**Cause**: Missing annotation or incorrect import

**Solution**:
```dart
// Ensure entity is annotated
@NexusEntity()
class User {
  final String id;
  final String name;
  // ...
}

// Run generator
dart run build_runner build
```

### Type mismatch in generated code

**Symptom**: `The argument type 'X' can't be assigned to 'Y'`

**Cause**: Generator output doesn't match expected types

**Solution**:
1. Delete generated files: `rm **/*.g.dart`
2. Regenerate: `dart run build_runner build --delete-conflicting-outputs`
3. If persists, check your entity class matches expected format

---

## Getting More Help

### Enable Debug Logging

```dart
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });

  runApp(MyApp());
}
```

### Check Package Versions

```bash
flutter pub deps | grep nexus_store
```

### Report Issues

If you can't resolve your issue:

1. Search [existing issues](https://github.com/unfazed-dev/nexus_store/issues)
2. Create a new issue with:
   - Package versions (`flutter pub deps`)
   - Minimal reproduction code
   - Error messages and stack traces
   - Platform (iOS/Android/Web/Desktop)

### Community Support

- GitHub Discussions: [nexus_store discussions](https://github.com/unfazed-dev/nexus_store/discussions)
- Stack Overflow: Tag with `nexus-store` and `flutter`
