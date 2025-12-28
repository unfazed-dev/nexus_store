import 'package:nexus_store_flutter/src/background/background_sync_config.dart';
import 'package:nexus_store_flutter/src/background/background_sync_status.dart';
import 'package:nexus_store_flutter/src/background/background_sync_task.dart';

/// Abstract service for managing background sync operations.
///
/// Platform-specific implementations handle the actual scheduling
/// using WorkManager (Android/iOS) or equivalent platform APIs.
///
/// ## Usage
///
/// ```dart
/// // Get the service instance from factory
/// final service = BackgroundSyncServiceFactory.create();
///
/// // Check if platform supports background sync
/// if (service.isSupported) {
///   // Initialize with configuration
///   await service.initialize(BackgroundSyncConfig(
///     minInterval: Duration(minutes: 15),
///     requiresNetwork: true,
///   ));
///
///   // Register sync task
///   await service.registerTask(mySyncTask);
///
///   // Schedule sync
///   await service.scheduleSync();
///
///   // Listen to status updates
///   service.statusStream.listen((status) {
///     print('Sync status: $status');
///   });
/// }
///
/// // Cleanup when done
/// await service.dispose();
/// ```
abstract class BackgroundSyncService {
  /// Whether background sync is supported on this platform.
  ///
  /// Returns `true` for Android and iOS, `false` for other platforms.
  bool get isSupported;

  /// Whether the service has been initialized.
  ///
  /// Must call [initialize] before scheduling syncs.
  bool get isInitialized;

  /// Stream of sync status updates.
  ///
  /// Emits status changes as the sync progresses through its lifecycle.
  /// This is a broadcast stream and supports multiple listeners.
  Stream<BackgroundSyncStatus> get statusStream;

  /// Initializes the service with the given configuration.
  ///
  /// Must be called before [scheduleSync] or [registerTask].
  /// Can be called multiple times to update configuration.
  ///
  /// Throws [StateError] if initialization fails.
  Future<void> initialize(BackgroundSyncConfig config);

  /// Registers a sync task to be executed in the background.
  ///
  /// The task's [BackgroundSyncTask.execute] method will be called
  /// when the platform triggers a background sync.
  ///
  /// Multiple tasks can be registered; they will be executed in order.
  Future<void> registerTask(BackgroundSyncTask task);

  /// Schedules a background sync.
  ///
  /// The sync will be executed when platform conditions are met
  /// (network, battery, etc. based on [BackgroundSyncConfig]).
  ///
  /// Throws [StateError] if service is not initialized.
  Future<void> scheduleSync();

  /// Cancels any scheduled sync.
  ///
  /// Does nothing if no sync is scheduled.
  Future<void> cancelSync();

  /// Releases resources used by the service.
  ///
  /// Call this when the service is no longer needed.
  /// After disposal, the service cannot be used again.
  Future<void> dispose();
}
