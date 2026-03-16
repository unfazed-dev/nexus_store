import 'dart:async';

import 'package:nexus_store/src/policy/refetch_config.dart';

/// Manages automatic background refetching based on [RefetchConfig].
///
/// Supports three refetch triggers:
/// - **Interval**: Periodic timer-based refetching
/// - **Reconnect**: Refetch when connectivity is restored
/// - **Resume**: Refetch when the app returns from background
///
/// ## Example
///
/// ```dart
/// final manager = RefetchManager(
///   config: RefetchConfig(interval: Duration(minutes: 5)),
///   onRefetch: () => store.getAll(policy: FetchPolicy.networkFirst),
/// );
/// manager.start();
/// // ...
/// manager.dispose();
/// ```
class RefetchManager {
  /// Creates a refetch manager.
  RefetchManager({
    required this.config,
    required this.onRefetch,
    this.connectivityStream,
    this.resumeStream,
  });

  /// The refetch configuration.
  final RefetchConfig config;

  /// Callback invoked when a refetch should occur.
  final Future<void> Function() onRefetch;

  /// Stream that emits `true` when connectivity is restored.
  final Stream<bool>? connectivityStream;

  /// Stream that emits when the app resumes from background.
  final Stream<void>? resumeStream;

  Timer? _timer;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<void>? _resumeSubscription;
  bool _disposed = false;

  /// Whether this manager has been disposed.
  bool get isDisposed => _disposed;

  /// Whether the interval timer is active.
  bool get isTimerActive => _timer?.isActive ?? false;

  /// Starts the refetch manager.
  ///
  /// Sets up timers and stream subscriptions based on the configuration.
  /// Does nothing if the config has no enabled triggers.
  void start() {
    if (_disposed || !config.isEnabled) return;

    // Interval-based refetching
    if (config.interval != null) {
      _timer = Timer.periodic(config.interval!, (_) => _doRefetch());
    }

    // Connectivity-based refetching
    if (config.refetchOnReconnect && connectivityStream != null) {
      _connectivitySubscription = connectivityStream!.listen((connected) {
        if (connected && !_disposed) {
          _doRefetch();
        }
      });
    }

    // App resume-based refetching
    if (config.refetchOnResume && resumeStream != null) {
      _resumeSubscription = resumeStream!.listen((_) {
        if (!_disposed) {
          _doRefetch();
        }
      });
    }
  }

  Future<void> _doRefetch() async {
    if (_disposed) return;
    try {
      await onRefetch();
    } catch (_) {
      // Silently ignore refetch errors — they'll be retried
    }
  }

  /// Disposes the refetch manager.
  ///
  /// Cancels all timers and stream subscriptions.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _resumeSubscription?.cancel();
    _resumeSubscription = null;
  }
}
