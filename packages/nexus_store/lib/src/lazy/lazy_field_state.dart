/// Loading state of a lazy field.
///
/// Represents the current state of a lazily-loaded field value.
enum LazyFieldState {
  /// Field has not been loaded yet.
  ///
  /// The field contains a placeholder value or null.
  notLoaded,

  /// Field is currently being loaded.
  ///
  /// A load operation is in progress.
  loading,

  /// Field has been successfully loaded.
  ///
  /// The field contains the actual value from the backend.
  loaded,

  /// Field loading failed.
  ///
  /// Check [LazyField.errorMessage] for details about the failure.
  error,
}
