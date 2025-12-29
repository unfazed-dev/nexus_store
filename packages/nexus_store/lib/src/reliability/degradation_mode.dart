/// Represents the operational degradation mode of the system.
///
/// Controls what operations are allowed when the system is degraded.
/// Modes are ordered by severity: normal < cacheOnly < readOnly < offline.
///
/// ## Example
///
/// ```dart
/// final mode = store.degradationMode;
/// if (mode.isDegraded) {
///   showBanner('Operating in ${mode.name} mode');
/// }
/// if (!mode.allowsWrites) {
///   disableSaveButton();
/// }
/// ```
enum DegradationMode {
  /// Normal operation mode.
  ///
  /// All operations (reads, writes, backend calls) are allowed.
  normal,

  /// Cache-only mode.
  ///
  /// Reads from cache are allowed, but no backend calls.
  /// Writes are blocked.
  cacheOnly,

  /// Read-only mode.
  ///
  /// Reads (from cache or backend) are allowed.
  /// Writes are blocked.
  readOnly,

  /// Offline mode.
  ///
  /// All operations are blocked.
  offline;

  /// Returns `true` if this is normal mode.
  bool get isNormal => this == normal;

  /// Returns `true` if this is cacheOnly mode.
  bool get isCacheOnly => this == cacheOnly;

  /// Returns `true` if this is readOnly mode.
  bool get isReadOnly => this == readOnly;

  /// Returns `true` if this is offline mode.
  bool get isOffline => this == offline;

  /// Returns `true` if the system is in any degraded mode.
  bool get isDegraded => this != normal;

  /// Returns `true` if read operations are allowed.
  bool get allowsReads => this != offline;

  /// Returns `true` if write operations are allowed.
  bool get allowsWrites => this == normal;

  /// Returns `true` if backend calls are allowed.
  bool get allowsBackendCalls => this == normal || this == readOnly;

  /// Returns `true` if this mode is worse than [other].
  ///
  /// Mode severity order: normal < cacheOnly < readOnly < offline.
  bool isWorseThan(DegradationMode other) => index > other.index;

  /// Returns the worst (most degraded) mode from a list.
  ///
  /// Returns [normal] if the list is empty.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final overall = DegradationMode.worst([
  ///   backendMode,
  ///   cacheMode,
  ///   syncMode,
  /// ]);
  /// ```
  static DegradationMode worst(Iterable<DegradationMode> modes) {
    if (modes.isEmpty) return normal;
    return modes.reduce((a, b) => a.index > b.index ? a : b);
  }
}
