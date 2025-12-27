/// Background sync functionality for nexus_store.
///
/// Provides platform-specific background sync services using WorkManager
/// on Android and iOS. Falls back to a no-op implementation on unsupported
/// platforms.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:nexus_store_flutter/nexus_store_flutter.dart';
///
/// // Create service using factory
/// final syncService = BackgroundSyncServiceFactory.create();
///
/// if (syncService.isSupported) {
///   // Initialize with configuration
///   await syncService.initialize(BackgroundSyncConfig(
///     minInterval: Duration(minutes: 15),
///     requiresNetwork: true,
///   ));
///
///   // Register sync tasks
///   await syncService.registerTask(mySyncTask);
///
///   // Schedule background sync
///   await syncService.scheduleSync();
///
///   // Listen to status updates
///   syncService.statusStream.listen((status) {
///     print('Sync status: $status');
///   });
/// }
/// ```
library;

export 'background_sync_config.dart';
export 'background_sync_factory.dart';
export 'background_sync_service.dart';
export 'background_sync_status.dart';
export 'background_sync_task.dart';
export 'no_op_sync_service.dart';
export 'priority_sync_queue.dart';
export 'sync_priority.dart';
export 'work_manager_sync_service.dart';
