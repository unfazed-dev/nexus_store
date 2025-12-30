/// Built-in state management layer for nexus_store.
///
/// Provides lightweight state management primitives that make nexus_store
/// self-sufficient for most applications without requiring external state
/// management packages.
///
/// ## Components
///
/// - [NexusRegistry]: Singleton store registry for dependency injection
/// - [NexusState]: UI state container with BehaviorSubject backing
/// - [ComputedStore]: Derived state from multiple source stores
/// - [Selector]: Stream transformation with memoization
///
/// ## Example
///
/// ```dart
/// // Register stores at app startup
/// NexusRegistry.register<User>(userStore);
/// NexusRegistry.register<Order>(orderStore);
///
/// // Create computed state
/// final dashboardStore = ComputedStore.from2(
///   NexusRegistry.get<User, String>(),
///   NexusRegistry.get<Order, String>(),
///   (users, orders) => DashboardState(
///     userCount: users.length,
///     orderCount: orders.length,
///   ),
/// );
///
/// // Create UI state
/// final uiState = NexusState<AppUIState>(
///   AppUIState(selectedTab: 0, isDarkMode: false),
/// );
///
/// // Use selectors for efficient updates
/// userStore.select((users) => users.length).listen((count) {
///   print('User count: $count');
/// });
/// ```
library;

export 'computed_store.dart';
export 'nexus_registry.dart';
export 'nexus_state.dart';
export 'persisted_state.dart';
export 'selector.dart';
export 'state_storage.dart';
