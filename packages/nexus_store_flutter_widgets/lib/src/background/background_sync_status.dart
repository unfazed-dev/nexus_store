/// Status of a background sync operation.
///
/// Represents the lifecycle of a sync task from scheduling through completion
/// or failure. Use [isActive] to check if sync is in progress, and
/// [isTerminal] to check if the sync has finished.
///
/// ## State Machine
///
/// ```
/// idle -> scheduled -> running -> completed
///                         |
///                         v
///                      failed
/// ```
enum BackgroundSyncStatus {
  /// No sync is scheduled or running. Initial state.
  idle,

  /// Sync has been scheduled but not yet started.
  ///
  /// The system will start the sync when conditions are met
  /// (network, battery, etc.).
  scheduled,

  /// Sync is currently executing.
  running,

  /// Sync completed successfully.
  completed,

  /// Sync failed. Check logs for error details.
  failed,
}

/// Extension methods for [BackgroundSyncStatus].
extension BackgroundSyncStatusExtension on BackgroundSyncStatus {
  /// Returns true if sync is currently active (scheduled or running).
  ///
  /// Use this to show sync indicators in the UI.
  bool get isActive =>
      this == BackgroundSyncStatus.scheduled ||
      this == BackgroundSyncStatus.running;

  /// Returns true if sync has reached a terminal state (completed or failed).
  ///
  /// Terminal states indicate the sync cycle has finished and a new sync
  /// can be scheduled.
  bool get isTerminal =>
      this == BackgroundSyncStatus.completed ||
      this == BackgroundSyncStatus.failed;
}
