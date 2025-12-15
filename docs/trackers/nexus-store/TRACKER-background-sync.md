# TRACKER: Background Sync Service

## Status: PENDING

## Overview

Implement platform-specific background sync services using WorkManager (Android) and BGTaskScheduler (iOS) to keep data synchronized when the app is backgrounded.

**Spec Reference**: [SPEC-nexus-store.md](../../specs/SPEC-nexus-store.md) - REQ-032, REQ-033, Task 29
**Parent Tracker**: [TRACKER-nexus-store-main.md](./TRACKER-nexus-store-main.md)

## Tasks

### Data Models
- [ ] Create `BackgroundSyncConfig` class
  - [ ] `enabled: bool`
  - [ ] `minInterval: Duration` - Minimum time between syncs
  - [ ] `requiresNetwork: bool` - Only sync with network
  - [ ] `requiresCharging: bool` - Only sync while charging
  - [ ] `requiresBatteryNotLow: bool`

- [ ] Create `SyncPriority` enum
  - [ ] `critical` - Sync immediately
  - [ ] `high` - Sync soon
  - [ ] `normal` - Standard priority
  - [ ] `low` - Defer if busy

- [ ] Create `BackgroundSyncStatus` enum
  - [ ] `idle`, `scheduled`, `running`, `completed`, `failed`

### Abstract Interface
- [ ] Create `BackgroundSyncService` abstract class
  - [ ] `Future<void> initialize(BackgroundSyncConfig config)`
  - [ ] `Future<void> scheduleSync()`
  - [ ] `Future<void> cancelSync()`
  - [ ] `Stream<BackgroundSyncStatus> get statusStream`
  - [ ] `bool get isSupported`

- [ ] Create `BackgroundSyncTask` interface
  - [ ] `Future<bool> execute()` - Called by platform
  - [ ] `String get taskId` - Unique identifier

### Android Implementation (WorkManager)
- [ ] Create `WorkManagerSyncService` class
  - [ ] Use `workmanager` package
  - [ ] Configure periodic work requests
  - [ ] Handle constraints (network, battery, charging)

- [ ] Implement WorkManager callback
  - [ ] Register callback dispatcher
  - [ ] Execute sync in isolate
  - [ ] Report success/failure

- [ ] Configure retry policy
  - [ ] Exponential backoff on failure
  - [ ] Maximum retry attempts

### iOS Implementation (BGTaskScheduler)
- [ ] Create `BGTaskSchedulerService` class
  - [ ] Use `background_fetch` or native method channel
  - [ ] Register BGAppRefreshTask
  - [ ] Handle completion handler

- [ ] Configure background modes
  - [ ] Document Info.plist requirements
  - [ ] Handle execution time limits

### Sync Priority Queues (REQ-033)
- [ ] Create `PrioritySyncQueue` class
  - [ ] `enqueue(T item, SyncPriority priority)`
  - [ ] Process items by priority, then FIFO
  - [ ] Persist queue for background resume

- [ ] Integrate with save operations
  - [ ] `store.save(item, priority: SyncPriority.critical)`
  - [ ] Critical items sync before normal

### Platform Detection
- [ ] Create `BackgroundSyncServiceFactory`
  - [ ] Detect platform
  - [ ] Return appropriate implementation
  - [ ] Provide no-op for unsupported platforms

### NexusStore Integration
- [ ] Add `backgroundSync` to Flutter extension
  - [ ] Auto-register sync tasks
  - [ ] Connect to store sync mechanism

### Unit Tests
- [ ] `test/src/background/background_sync_service_test.dart`
  - [ ] Scheduling works correctly
  - [ ] Cancellation works
  - [ ] Status updates properly

- [ ] `test/src/background/priority_queue_test.dart`
  - [ ] Priority ordering correct
  - [ ] FIFO within same priority

## Files

**Source Files:**
```
packages/nexus_store_flutter/lib/src/background/
├── background_sync_service.dart      # Abstract interface
├── background_sync_config.dart       # Configuration
├── sync_priority.dart                # SyncPriority enum
├── work_manager_sync_service.dart    # Android implementation
├── bg_task_scheduler_service.dart    # iOS implementation
├── priority_sync_queue.dart          # Priority queue
└── background_sync_factory.dart      # Platform factory
```

**Test Files:**
```
packages/nexus_store_flutter/test/src/background/
├── background_sync_service_test.dart
├── priority_queue_test.dart
└── work_manager_sync_service_test.dart
```

## Dependencies

- Flutter extension (Task 14)
- Core package sync (Task 1, complete)
- `workmanager: ^0.5.0` - Android WorkManager
- `background_fetch: ^1.0.0` - iOS background fetch

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
