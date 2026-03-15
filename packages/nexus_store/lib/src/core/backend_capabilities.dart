/// Bundles backend capability flags into a single queryable object.
///
/// Use [NexusStore.capabilities] to check what the underlying backend supports
/// at runtime, enabling graceful feature detection and fallback behavior.
///
/// ```dart
/// if (store.capabilities.supportsOffline) {
///   // Enable offline-first UX
/// }
/// ```
class BackendCapabilities {
  /// Creates a [BackendCapabilities] with the given flags.
  ///
  /// All flags default to `false`.
  const BackendCapabilities({
    this.supportsOffline = false,
    this.supportsRealtime = false,
    this.supportsTransactions = false,
    this.supportsPagination = false,
    this.supportsFieldOperations = false,
  });

  /// Whether the backend supports offline operations.
  final bool supportsOffline;

  /// Whether the backend supports real-time subscriptions.
  final bool supportsRealtime;

  /// Whether the backend supports transactions.
  final bool supportsTransactions;

  /// Whether the backend supports cursor-based pagination.
  final bool supportsPagination;

  /// Whether the backend supports field-level operations (lazy loading).
  final bool supportsFieldOperations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackendCapabilities &&
          supportsOffline == other.supportsOffline &&
          supportsRealtime == other.supportsRealtime &&
          supportsTransactions == other.supportsTransactions &&
          supportsPagination == other.supportsPagination &&
          supportsFieldOperations == other.supportsFieldOperations;

  @override
  int get hashCode => Object.hash(
        supportsOffline,
        supportsRealtime,
        supportsTransactions,
        supportsPagination,
        supportsFieldOperations,
      );

  @override
  String toString() => 'BackendCapabilities('
      'supportsOffline: $supportsOffline, '
      'supportsRealtime: $supportsRealtime, '
      'supportsTransactions: $supportsTransactions, '
      'supportsPagination: $supportsPagination, '
      'supportsFieldOperations: $supportsFieldOperations)';
}
