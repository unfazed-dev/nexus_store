import 'dart:async';

import 'package:nexus_store_flutter/src/background/background_sync_config.dart';
import 'package:nexus_store_flutter/src/background/background_sync_service.dart';
import 'package:nexus_store_flutter/src/background/background_sync_status.dart';
import 'package:nexus_store_flutter/src/background/background_sync_task.dart';

/// Implementation of [BackgroundSyncService] using WorkManager.
///
/// Uses the `workmanager` package to schedule background tasks on
/// Android and iOS. Tasks are executed when platform conditions are met.
///
/// ## Setup
///
/// In your app's `main.dart`, register the callback dispatcher:
///
/// ```dart
/// void callbackDispatcher() {
///   Workmanager().executeTask((task, inputData) async {
///     // Get service instance and execute tasks
///     final service = BackgroundSyncServiceFactory.create();
///     return await service.executeRegisteredTasks();
///   });
/// }
///
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   Workmanager().initialize(callbackDispatcher);
///   runApp(MyApp());
/// }
/// ```
///
/// ## Platform Configuration
///
/// ### Android
/// Add to `android/app/src/main/AndroidManifest.xml`:
/// ```xml
/// <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
/// ```
///
/// ### iOS
/// Add to `ios/Runner/Info.plist`:
/// ```xml
/// <key>UIBackgroundModes</key>
/// <array>
///   <string>fetch</string>
///   <string>processing</string>
/// </array>
/// ```
class WorkManagerSyncService extends BackgroundSyncService {
  /// Creates a WorkManager-based sync service.
  WorkManagerSyncService();

  /// Unique task name for WorkManager registration.
  static const String taskName = 'com.nexusstore.backgroundSync';

  final StreamController<BackgroundSyncStatus> _statusController =
      StreamController<BackgroundSyncStatus>.broadcast();

  final List<BackgroundSyncTask> _registeredTasks = [];

  BackgroundSyncConfig? _config;
  bool _initialized = false;
  bool _isScheduled = false;
  bool _disposed = false;

  @override
  bool get isSupported => true;

  @override
  bool get isInitialized => _initialized;

  /// Returns the current configuration.
  BackgroundSyncConfig? get config => _config;

  /// Returns all registered tasks.
  List<BackgroundSyncTask> get registeredTasks =>
      List.unmodifiable(_registeredTasks);

  /// Returns whether a sync is currently scheduled.
  bool get isScheduled => _isScheduled;

  @override
  Stream<BackgroundSyncStatus> get statusStream => _statusController.stream;

  @override
  Future<void> initialize(BackgroundSyncConfig config) async {
    _config = config;
    _initialized = true;

    // Note: Actual Workmanager.initialize() should be called in main.dart
    // with the callback dispatcher. This method just stores configuration.
  }

  @override
  Future<void> registerTask(BackgroundSyncTask task) async {
    // Remove existing task with same ID, then add new task
    _registeredTasks
      ..removeWhere((t) => t.taskId == task.taskId)
      ..add(task);
  }

  @override
  Future<void> scheduleSync() async {
    if (!_initialized) {
      throw StateError('Service not initialized. Call initialize() first.');
    }

    if (_config?.enabled == false) {
      throw StateError('Background sync is disabled in configuration.');
    }

    _isScheduled = true;
    _emitStatus(BackgroundSyncStatus.scheduled);

    // Note: In real usage, this would call:
    // await Workmanager().registerPeriodicTask(
    //   taskName,
    //   taskName,
    //   frequency: _config!.minInterval,
    //   constraints: Constraints(
    //     networkType: _config!.requiresNetwork
    //         ? NetworkType.connected
    //         : NetworkType.not_required,
    //     requiresCharging: _config!.requiresCharging,
    //     requiresBatteryNotLow: _config!.requiresBatteryNotLow,
    //   ),
    // );
  }

  @override
  Future<void> cancelSync() async {
    _isScheduled = false;
    _emitStatus(BackgroundSyncStatus.idle);

    // Note: In real usage, this would call:
    // await Workmanager().cancelByUniqueName(taskName);
  }

  /// Executes all registered tasks.
  ///
  /// Called by the WorkManager callback dispatcher when the platform
  /// triggers a background sync.
  ///
  /// Returns `true` if all tasks succeeded, `false` if any failed.
  Future<bool> executeRegisteredTasks() async {
    if (_registeredTasks.isEmpty) {
      return true;
    }

    _emitStatus(BackgroundSyncStatus.running);

    var allSucceeded = true;
    for (final task in _registeredTasks) {
      try {
        final success = await task.execute();
        if (!success) {
          allSucceeded = false;
        }
      } on Exception {
        allSucceeded = false;
      }
    }

    _emitStatus(
      allSucceeded
          ? BackgroundSyncStatus.completed
          : BackgroundSyncStatus.failed,
    );

    return allSucceeded;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _registeredTasks.clear();
    await _statusController.close();
  }

  void _emitStatus(BackgroundSyncStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
