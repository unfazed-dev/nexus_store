# TRACKER: Background Sync Service

## Status: ✅ COMPLETE (139 tests)

## Overview

Platform-specific background sync services using WorkManager for both Android and iOS to keep data synchronized when the app is backgrounded.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-032, REQ-033, Task 29
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [x] Create `BackgroundSyncConfig` class
  - [x] `enabled: bool`
  - [x] `minInterval: Duration` - Minimum time between syncs
  - [x] `requiresNetwork: bool` - Only sync with network
  - [x] `requiresCharging: bool` - Only sync while charging
  - [x] `requiresBatteryNotLow: bool`
  - [x] Factory constructors: `disabled()`, `conservative()`, `aggressive()`
  - [x] `copyWith()` method for immutable updates

- [x] Create `SyncPriority` enum
  - [x] `critical` - Sync immediately
  - [x] `high` - Sync soon
  - [x] `normal` - Standard priority
  - [x] `low` - Defer if busy

- [x] Create `BackgroundSyncStatus` enum
  - [x] `idle`, `scheduled`, `running`, `completed`, `failed`
  - [x] Extension: `isActive`, `isTerminal`

### Abstract Interface
- [x] Create `BackgroundSyncService` abstract class
  - [x] `Future<void> initialize(BackgroundSyncConfig config)`
  - [x] `Future<void> scheduleSync()`
  - [x] `Future<void> cancelSync()`
  - [x] `Stream<BackgroundSyncStatus> get statusStream`
  - [x] `bool get isSupported`
  - [x] `bool get isInitialized`
  - [x] `Future<void> registerTask(BackgroundSyncTask task)`
  - [x] `Future<void> dispose()`

- [x] Create `BackgroundSyncTask` interface
  - [x] `Future<bool> execute()` - Called by platform
  - [x] `String get taskId` - Unique identifier

### Platform Implementation (WorkManager - Android + iOS)
- [x] Create `WorkManagerSyncService` class
  - [x] Use `workmanager` package (supports both Android and iOS)
  - [x] Task registration with unique task IDs
  - [x] Status stream with broadcast updates
  - [x] Execute all registered tasks
  - [x] Handle task success/failure reporting

- [x] Create `NoOpSyncService` class
  - [x] Graceful no-op for unsupported platforms (web, desktop)
  - [x] Returns `isSupported = false`
  - [x] All methods complete without error

### Sync Priority Queues (REQ-033)
- [x] Create `PrioritySyncQueue` class
  - [x] `enqueue(T item, SyncPriority priority)`
  - [x] Process items by priority, then FIFO
  - [x] `dequeue()`, `peek()`, `clear()`
  - [x] `isEmpty`, `isNotEmpty`, `length`
  - [x] `toList()` for inspection
  - [x] Generic type support

### Platform Detection
- [x] Create `BackgroundSyncServiceFactory`
  - [x] Detect platform (Android, iOS, other)
  - [x] Return `WorkManagerSyncService` for Android/iOS
  - [x] Return `NoOpSyncService` for unsupported platforms
  - [x] Testable via platform override parameters

### Barrel Export
- [x] Create `background.dart` barrel export
- [x] Update `nexus_store_flutter_widgets.dart` to export background module

### Unit Tests (139 tests)
- [x] `test/src/background/sync_priority_test.dart` (8 tests)
- [x] `test/src/background/background_sync_status_test.dart` (16 tests)
- [x] `test/src/background/background_sync_config_test.dart` (20 tests)
- [x] `test/src/background/background_sync_task_test.dart` (6 tests)
- [x] `test/src/background/background_sync_service_test.dart` (14 tests)
- [x] `test/src/background/priority_sync_queue_test.dart` (26 tests)
- [x] `test/src/background/no_op_sync_service_test.dart` (13 tests)
- [x] `test/src/background/work_manager_sync_service_test.dart` (26 tests)
- [x] `test/src/background/background_sync_factory_test.dart` (10 tests)

## Files

**Source Files:**
```
packages/nexus_store_flutter_widgets/lib/src/background/
├── background.dart                   # Barrel export
├── sync_priority.dart                # SyncPriority enum
├── background_sync_status.dart       # BackgroundSyncStatus enum with extensions
├── background_sync_config.dart       # Immutable configuration class
├── background_sync_task.dart         # BackgroundSyncTask interface
├── background_sync_service.dart      # Abstract service interface
├── priority_sync_queue.dart          # Generic priority queue
├── no_op_sync_service.dart           # No-op implementation
├── work_manager_sync_service.dart    # WorkManager implementation (Android + iOS)
└── background_sync_factory.dart      # Platform factory
```

**Test Files:**
```
packages/nexus_store_flutter_widgets/test/src/background/
├── sync_priority_test.dart
├── background_sync_status_test.dart
├── background_sync_config_test.dart
├── background_sync_task_test.dart
├── background_sync_service_test.dart
├── priority_sync_queue_test.dart
├── no_op_sync_service_test.dart
├── work_manager_sync_service_test.dart
└── background_sync_factory_test.dart
```

## Dependencies

- Flutter extension (Task 14, complete)
- Core package sync (Task 1, complete)
- `workmanager: ^0.5.2` - Android + iOS background execution

## API Preview

```dart
// Configure background sync (in Flutter app)
final store = NexusStore<User, String>(
  backend: backend,
  config: StoreConfig(...),
);

// Initialize background sync
await BackgroundSyncService.initialize(
  store: store,
  config: BackgroundSyncConfig(
    enabled: true,
    minInterval: Duration(minutes: 15),
    requiresNetwork: true,
    requiresCharging: false,
    requiresBatteryNotLow: true,
  ),
);

// Schedule sync (done automatically, but can be manual)
await BackgroundSyncService.instance.scheduleSync();

// Monitor status
BackgroundSyncService.instance.statusStream.listen((status) {
  print('Background sync: $status');
});

// Save with priority
await store.save(
  criticalUpdate,
  priority: SyncPriority.critical, // Syncs first
);

await store.save(
  regularUpdate,
  priority: SyncPriority.normal, // Syncs after critical
);

// In main.dart - register callback
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Re-initialize store in background isolate
    final store = await initializeStore();
    await store.sync();
    return true;
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher);
  runApp(MyApp());
}

// iOS - configure in Info.plist
// <key>UIBackgroundModes</key>
// <array>
//   <string>fetch</string>
//   <string>processing</string>
// </array>
// <key>BGTaskSchedulerPermittedIdentifiers</key>
// <array>
//   <string>com.example.nexusstore.sync</string>
// </array>
```

## Notes

- Background execution time is limited (30 seconds iOS, few minutes Android)
- System may delay or skip background tasks based on battery/usage
- Critical priority should be used sparingly to avoid throttling
- Users can disable background refresh in settings
- Consider adding badge/notification for pending sync count
- Test thoroughly on real devices (emulators have different behavior)
- Document that background sync is best-effort, not guaranteed
- Android 12+ has stricter background execution limits
