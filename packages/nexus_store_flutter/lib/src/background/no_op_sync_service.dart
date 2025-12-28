import 'dart:async';

import 'package:nexus_store_flutter/src/background/background_sync_config.dart';
import 'package:nexus_store_flutter/src/background/background_sync_service.dart';
import 'package:nexus_store_flutter/src/background/background_sync_status.dart';
import 'package:nexus_store_flutter/src/background/background_sync_task.dart';

/// A no-operation implementation of [BackgroundSyncService].
///
/// Used for platforms that don't support background sync (web, desktop).
/// All methods complete successfully but perform no actual operations.
///
/// ## Example
///
/// ```dart
/// final service = NoOpSyncService();
///
/// // Check if supported (always false)
/// if (!service.isSupported) {
///   print('Background sync not supported on this platform');
/// }
///
/// // Methods complete but do nothing
/// await service.initialize(config);
/// await service.scheduleSync(); // No-op
/// ```
class NoOpSyncService extends BackgroundSyncService {
  /// Creates a no-operation sync service.
  NoOpSyncService();

  final StreamController<BackgroundSyncStatus> _statusController =
      StreamController<BackgroundSyncStatus>.broadcast();

  bool _initialized = false;
  bool _disposed = false;

  @override
  bool get isSupported => false;

  @override
  bool get isInitialized => _initialized;

  @override
  Stream<BackgroundSyncStatus> get statusStream => _statusController.stream;

  @override
  Future<void> initialize(BackgroundSyncConfig config) async {
    _initialized = true;
    // No-op: configuration is ignored on unsupported platforms
  }

  @override
  Future<void> registerTask(BackgroundSyncTask task) async {
    // No-op: tasks are not executed on unsupported platforms
  }

  @override
  Future<void> scheduleSync() async {
    // No-op: sync is not scheduled on unsupported platforms
  }

  @override
  Future<void> cancelSync() async {
    // No-op: nothing to cancel on unsupported platforms
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _statusController.close();
  }
}
