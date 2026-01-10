/// Signals integration for NexusStore.
///
/// This library provides fine-grained reactive signals that integrate
/// with NexusStore for efficient, reactive data management.
///
/// ## Features
///
/// - **Store to Signal Adapters**: Convert NexusStore streams to signals
/// - **State Management**: Sealed state classes with pattern matching
/// - **Computed Signals**: Filter, sort, count, and transform helpers
/// - **Lifecycle Management**: SignalScope and disposal utilities
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:nexus_store_signals_binding/nexus_store_signals_binding.dart';
///
/// // Convert store to signal
/// final usersSignal = userStore.toSignal();
///
/// // Use in a widget
/// Watch((context) {
///   return ListView(
///     children: usersSignal.value.map((u) => UserTile(u)).toList(),
///   );
/// });
/// ```
///
/// ## State Signals
///
/// ```dart
/// // Get loading/error states
/// final usersState = userStore.toStateSignal();
///
/// Watch((context) {
///   return usersState.value.when(
///     initial: () => Text('Ready'),
///     loading: (prev) => CircularProgressIndicator(),
///     data: (users) => UserList(users: users),
///     error: (e, st, prev) => Text('Error: $e'),
///   );
/// });
/// ```
library;

// State classes
export 'src/state/nexus_signal_state.dart';
export 'src/state/nexus_item_signal_state.dart';

// Extensions
export 'src/extensions/store_signal_extension.dart';

// Signal wrappers
export 'src/signals/nexus_signal.dart';
export 'src/signals/nexus_list_signal.dart';

// Computed utilities
export 'src/computed/computed_utils.dart';

// Lifecycle management
export 'src/lifecycle/signal_scope.dart';

// Bundle (batteries-included)
export 'src/bundle/signals_store_bundle.dart';

// Manager (batteries-included)
export 'src/manager/signals_manager.dart';
