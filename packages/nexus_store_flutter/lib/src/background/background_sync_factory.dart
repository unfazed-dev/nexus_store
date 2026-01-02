import 'dart:io' show Platform;

import 'package:nexus_store_flutter/src/background/background_sync_service.dart';
import 'package:nexus_store_flutter/src/background/no_op_sync_service.dart';
import 'package:nexus_store_flutter/src/background/work_manager_sync_service.dart';

/// Factory for creating platform-appropriate [BackgroundSyncService].
///
/// Automatically detects the platform and returns the appropriate
/// implementation:
/// - Android/iOS: [WorkManagerSyncService] using the workmanager plugin
/// - Other platforms: [NoOpSyncService] that does nothing
///
/// ## Example
///
/// ```dart
/// // Get the appropriate service for the current platform
/// final service = BackgroundSyncServiceFactory.create();
///
/// if (service.isSupported) {
///   await service.initialize(config);
///   await service.scheduleSync();
/// } else {
///   print('Background sync not supported on this platform');
/// }
/// ```
class BackgroundSyncServiceFactory {
  // coverage:ignore-start
  // Private constructor to prevent instantiation
  BackgroundSyncServiceFactory._();
  // coverage:ignore-end

  /// Creates a [BackgroundSyncService] appropriate for the current platform.
  ///
  /// On Android and iOS, returns a [WorkManagerSyncService].
  /// On other platforms (web, desktop), returns a [NoOpSyncService].
  ///
  /// Optional [isAndroid] and [isIOS] parameters are provided for testing.
  /// In production, platform detection is automatic.
  static BackgroundSyncService create({
    bool? isAndroid,
    bool? isIOS,
  }) {
    final android = isAndroid ?? _isAndroid;
    final ios = isIOS ?? _isIOS;

    if (android || ios) {
      return WorkManagerSyncService();
    }

    return NoOpSyncService();
  }

  /// Returns true if running on Android.
  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
      // coverage:ignore-start
      // ignore: avoid_catching_errors
    } on UnsupportedError catch (_) {
      // Platform throws UnsupportedError on web
      return false;
    }
    // coverage:ignore-end
  }

  /// Returns true if running on iOS.
  static bool get _isIOS {
    try {
      return Platform.isIOS;
      // coverage:ignore-start
      // ignore: avoid_catching_errors
    } on UnsupportedError catch (_) {
      // Platform throws UnsupportedError on web
      return false;
    }
    // coverage:ignore-end
  }
}
