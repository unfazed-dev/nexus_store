import '../core/nexus_store.dart';

/// A key for storing stores in the registry.
class _RegistryKey {
  const _RegistryKey(this.type, this.scope);

  final Type type;
  final String? scope;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RegistryKey && type == other.type && scope == other.scope;

  @override
  int get hashCode => Object.hash(type, scope);

  // coverage:ignore-start
  // toString() is for debugging; private class not exposed externally
  @override
  String toString() => '_RegistryKey($type, scope: $scope)';
  // coverage:ignore-end
}

/// A singleton registry for [NexusStore] instances.
///
/// Provides a lightweight dependency injection mechanism for stores,
/// supporting both global and scoped registration for multi-tenant scenarios.
///
/// ## Example
///
/// ```dart
/// void main() {
///   // Register stores at app startup
///   NexusRegistry.register<User>(
///     NexusStore<User, String>(backend: userBackend),
///   );
///   NexusRegistry.register<Order>(
///     NexusStore<Order, String>(backend: orderBackend),
///   );
///
///   runApp(MyApp());
/// }
///
/// // Access anywhere
/// class UserService {
///   final userStore = NexusRegistry.get<User, String>();
///
///   Future<void> updateUser(User user) => userStore.save(user);
/// }
/// ```
///
/// ## Scoped Registration (Multi-Tenant)
///
/// ```dart
/// // Register per tenant
/// NexusRegistry.register<User>(tenantAStore, scope: 'tenant-a');
/// NexusRegistry.register<User>(tenantBStore, scope: 'tenant-b');
///
/// // Access by scope
/// final storeA = NexusRegistry.get<User, String>(scope: 'tenant-a');
/// final storeB = NexusRegistry.get<User, String>(scope: 'tenant-b');
/// ```
class NexusRegistry {
  NexusRegistry._(); // coverage:ignore-line

  static final Map<_RegistryKey, NexusStore<dynamic, dynamic>> _stores = {};

  /// Registers a [NexusStore] in the registry.
  ///
  /// - [store]: The store instance to register.
  /// - [scope]: Optional scope for multi-tenant scenarios.
  /// - [replace]: If true, replaces any existing registration for the same type/scope.
  ///
  /// Throws [StateError] if a store of the same type is already registered
  /// in the same scope and [replace] is false.
  static void register<T>(
    NexusStore<T, dynamic> store, {
    String? scope,
    bool replace = false,
  }) {
    final key = _RegistryKey(T, scope);
    if (_stores.containsKey(key) && !replace) {
      final scopeInfo = scope != null ? " in scope '$scope'" : '';
      throw StateError(
        'A store for type $T is already registered$scopeInfo. '
        'Use replace: true to override.',
      );
    }
    _stores[key] = store;
  }

  /// Gets a registered [NexusStore] from the registry.
  ///
  /// - [scope]: Optional scope to look up scoped registration.
  ///
  /// Throws [StateError] if no store of the requested type is registered
  /// in the specified scope.
  static NexusStore<T, ID> get<T, ID>({String? scope}) {
    final key = _RegistryKey(T, scope);
    final store = _stores[key];
    if (store == null) {
      final scopeInfo = scope != null ? " in scope '$scope'" : '';
      throw StateError('No store registered for type $T$scopeInfo.');
    }
    return store as NexusStore<T, ID>;
  }

  /// Tries to get a registered [NexusStore] from the registry.
  ///
  /// Returns `null` if no store of the requested type is registered
  /// in the specified scope.
  static NexusStore<T, ID>? tryGet<T, ID>({String? scope}) {
    final key = _RegistryKey(T, scope);
    final store = _stores[key];
    return store as NexusStore<T, ID>?;
  }

  /// Checks if a store of type [T] is registered.
  ///
  /// - [scope]: Optional scope to check scoped registration.
  static bool isRegistered<T>({String? scope}) {
    final key = _RegistryKey(T, scope);
    return _stores.containsKey(key);
  }

  /// Unregisters a store of type [T] from the registry.
  ///
  /// - [scope]: Optional scope to unregister scoped store.
  ///
  /// Does nothing if no store is registered for the type/scope.
  static void unregister<T>({String? scope}) {
    final key = _RegistryKey(T, scope);
    _stores.remove(key);
  }

  /// Clears all registered stores from the registry.
  ///
  /// Useful for testing to reset state between tests.
  static void reset() {
    _stores.clear();
  }

  /// Gets a list of all registered entity types.
  ///
  /// Includes types from all scopes.
  static List<Type> get registeredTypes {
    return _stores.keys.map((key) => key.type).toSet().toList();
  }

  /// Gets a list of all used scopes.
  ///
  /// Does not include `null` (default scope).
  static List<String> get scopes {
    return _stores.keys
        .map((key) => key.scope)
        .whereType<String>()
        .toSet()
        .toList();
  }

  /// Disposes all stores registered in a specific scope.
  ///
  /// Does nothing if the scope doesn't exist.
  static void disposeScope(String scope) {
    final keysToRemove =
        _stores.keys.where((key) => key.scope == scope).toList();
    for (final key in keysToRemove) {
      _stores.remove(key);
    }
  }
}
