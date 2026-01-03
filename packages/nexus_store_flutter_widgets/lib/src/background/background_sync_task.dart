/// Interface for a background sync task.
///
/// Implement this interface to define custom sync logic that can be
/// executed by the [BackgroundSyncService] when the app is backgrounded.
///
/// ## Example
///
/// ```dart
/// class UserSyncTask implements BackgroundSyncTask {
///   final NexusStore<User, String> store;
///
///   UserSyncTask(this.store);
///
///   @override
///   String get taskId => 'com.example.sync.users';
///
///   @override
///   Future<bool> execute() async {
///     try {
///       await store.sync();
///       return true;
///     } catch (e) {
///       return false;
///     }
///   }
/// }
/// ```
///
/// ## Implementation Notes
///
/// - Keep execution time under 30 seconds (iOS limit)
/// - Handle all exceptions internally and return false on failure
/// - The task may be called in a separate isolate on Android
/// - Avoid UI operations - this runs in the background
abstract interface class BackgroundSyncTask {
  /// Unique identifier for this task.
  ///
  /// Should be a reverse domain name style identifier, e.g.,
  /// `com.example.sync.users`. This ID is used to register and
  /// identify the task with the platform.
  String get taskId;

  /// Executes the sync operation.
  ///
  /// Returns `true` if the sync completed successfully, `false` otherwise.
  /// The return value is used by the platform to determine retry behavior:
  /// - `true`: Task completed, no retry needed
  /// - `false`: Task failed, platform may retry based on configuration
  ///
  /// Implementation should:
  /// - Complete within platform time limits (30s iOS, few minutes Android)
  /// - Handle all exceptions internally
  /// - Return false on any failure
  Future<bool> execute();
}
