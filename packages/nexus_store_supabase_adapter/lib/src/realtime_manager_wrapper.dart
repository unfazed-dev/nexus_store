import 'package:nexus_store_supabase_adapter/src/supabase_realtime_manager.dart';

/// An abstraction over [SupabaseRealtimeManager] to enable mocking in tests.
///
/// This wrapper enables testing of error handling paths in watch operations
/// that would otherwise be untestable with the concrete implementation.
///
/// ## Usage
///
/// For production, use [DefaultRealtimeManagerWrapper]:
/// ```dart
/// final manager = SupabaseRealtimeManager<T, ID>(...);
/// final wrapper = DefaultRealtimeManagerWrapper<T, ID>(manager);
/// ```
///
/// For tests, create a mock:
/// ```dart
/// class MockRealtimeManagerWrapper extends Mock
///     implements RealtimeManagerWrapper<T, ID> {}
/// ```
abstract class RealtimeManagerWrapper<T, ID> {
  /// Whether the manager has been initialized.
  bool get isInitialized;

  /// Initializes the realtime manager.
  Future<void> initialize();

  /// Returns a stream for watching a single item by ID.
  ///
  /// [initialValue] can be provided to seed the stream with the current value.
  Stream<T?> watchItem(ID id, {T? initialValue});

  /// Returns a stream for watching all items.
  ///
  /// [initialValue] can be provided to seed the stream with the current list.
  Stream<List<T>> watchAll({List<T>? initialValue});

  /// Manually updates the stream for a single item.
  void notifyItemChanged(T item);

  /// Manually notifies that an item was deleted.
  void notifyItemDeleted(ID id);

  /// Disposes of all resources.
  Future<void> dispose();
}

/// Default implementation that wraps a real [SupabaseRealtimeManager].
class DefaultRealtimeManagerWrapper<T, ID>
    implements RealtimeManagerWrapper<T, ID> {
  /// Creates a wrapper around the given [SupabaseRealtimeManager].
  DefaultRealtimeManagerWrapper(this._manager);

  final SupabaseRealtimeManager<T, ID> _manager;

  @override
  bool get isInitialized => _manager.isInitialized;

  @override
  Future<void> initialize() => _manager.initialize();

  @override
  Stream<T?> watchItem(ID id, {T? initialValue}) =>
      _manager.watchItem(id, initialValue: initialValue);

  @override
  Stream<List<T>> watchAll({List<T>? initialValue}) =>
      _manager.watchAll(initialValue: initialValue);

  @override
  void notifyItemChanged(T item) => _manager.notifyItemChanged(item);

  @override
  void notifyItemDeleted(ID id) => _manager.notifyItemDeleted(id);

  @override
  Future<void> dispose() => _manager.dispose();
}
