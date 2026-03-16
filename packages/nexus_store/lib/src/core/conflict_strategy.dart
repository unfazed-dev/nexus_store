/// Strategy for handling conflicts when upserting entities.
///
/// Determines what happens when an entity with the same ID already exists
/// during an [upsert] operation.
///
/// ## Example
///
/// ```dart
/// // Default: update existing entity
/// await store.upsert(user, onConflict: ConflictStrategy.update);
///
/// // Skip if entity already exists
/// await store.upsert(user, onConflict: ConflictStrategy.ignore);
///
/// // Replace entire entity
/// await store.upsert(user, onConflict: ConflictStrategy.replace);
/// ```
enum ConflictStrategy {
  /// Updates the existing entity with the new values.
  ///
  /// This is the default strategy. If an entity with the same ID exists,
  /// it will be updated (equivalent to `save()`).
  update,

  /// Ignores the upsert if an entity with the same ID already exists.
  ///
  /// The existing entity is returned unchanged.
  ignore,

  /// Replaces the existing entity entirely with the new one.
  ///
  /// Unlike [update], this does not merge fields — the old entity is
  /// completely replaced.
  replace,

  /// Throws an error if an entity with the same ID already exists.
  ///
  /// Use this when you expect the entity to be new and want to catch
  /// accidental overwrites.
  error,
}
