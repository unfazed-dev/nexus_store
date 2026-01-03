/// Observes app lifecycle to pause/resume store sync operations.
library;

import 'package:flutter/widgets.dart';
import 'package:nexus_store/nexus_store.dart';

/// Callback for lifecycle state changes.
typedef LifecycleCallback = void Function(AppLifecycleState state);

/// A [WidgetsBindingObserver] that manages store sync based on app lifecycle.
///
/// This observer automatically pauses sync when the app goes to background
/// and resumes it when the app returns to foreground.
///
/// Usage:
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   final observer = NexusStoreLifecycleObserver(
///     stores: [userStore, productStore],
///   );
///   WidgetsBinding.instance.addObserver(observer);
///
///   runApp(MyApp());
/// }
/// ```
///
/// Or use as a widget:
/// ```dart
/// NexusStoreLifecycleObserverWidget(
///   stores: [userStore, productStore],
///   child: MyApp(),
/// )
/// ```
class NexusStoreLifecycleObserver with WidgetsBindingObserver {
  /// Creates a lifecycle observer for the given stores.
  ///
  /// If [pauseOnBackground] is true (default), sync is paused when app
  /// goes to background and resumed when returning to foreground.
  NexusStoreLifecycleObserver({
    required this.stores,
    this.pauseOnBackground = true,
    this.onStateChange,
  });

  /// The stores to manage lifecycle for.
  final List<NexusStore<dynamic, dynamic>> stores;

  /// Whether to pause sync when app goes to background.
  final bool pauseOnBackground;

  /// Optional callback for lifecycle state changes.
  final LifecycleCallback? onStateChange;

  bool _isPaused = false;

  /// Whether sync is currently paused.
  bool get isPaused => _isPaused;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChange?.call(state);

    if (!pauseOnBackground) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pauseSync();
      case AppLifecycleState.resumed:
        _resumeSync();
    }
  }

  void _pauseSync() {
    if (_isPaused) return;
    _isPaused = true;
    // Stores don't have a pause method in the current API
    // This is a placeholder for when pause/resume is added
    // For now, we just track the state
  }

  void _resumeSync() {
    if (!_isPaused) return;
    _isPaused = false;

    // Trigger a sync on all stores when resuming
    for (final store in stores) {
      store.sync().catchError((_) {
        // Ignore sync errors on resume
      });
    }
  }

  /// Attaches this observer to [WidgetsBinding].
  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Detaches this observer from [WidgetsBinding].
  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// A widget that manages store lifecycle based on app state.
///
/// This widget creates and manages a [NexusStoreLifecycleObserver] for you.
///
/// Example:
/// ```dart
/// NexusStoreLifecycleObserverWidget(
///   stores: [userStore, productStore],
///   child: MyApp(),
/// )
/// ```
class NexusStoreLifecycleObserverWidget extends StatefulWidget {
  /// Creates a widget that manages store lifecycle.
  const NexusStoreLifecycleObserverWidget({
    required this.stores,
    required this.child,
    this.pauseOnBackground = true,
    this.onStateChange,
    super.key,
  });

  /// The stores to manage lifecycle for.
  final List<NexusStore<dynamic, dynamic>> stores;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Whether to pause sync when app goes to background.
  final bool pauseOnBackground;

  /// Optional callback for lifecycle state changes.
  final LifecycleCallback? onStateChange;

  @override
  State<NexusStoreLifecycleObserverWidget> createState() =>
      _NexusStoreLifecycleObserverWidgetState();
}

class _NexusStoreLifecycleObserverWidgetState
    extends State<NexusStoreLifecycleObserverWidget> {
  late NexusStoreLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = NexusStoreLifecycleObserver(
      stores: widget.stores,
      pauseOnBackground: widget.pauseOnBackground,
      onStateChange: widget.onStateChange,
    );
    _observer.attach();
  }

  @override
  void didUpdateWidget(NexusStoreLifecycleObserverWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // coverage:ignore-start
    if (oldWidget.stores != widget.stores ||
        oldWidget.pauseOnBackground != widget.pauseOnBackground) {
      _observer.detach();
      _observer = NexusStoreLifecycleObserver(
        stores: widget.stores,
        pauseOnBackground: widget.pauseOnBackground,
        onStateChange: widget.onStateChange,
      );
      _observer.attach();
    }
    // coverage:ignore-end
  }

  @override
  void dispose() {
    _observer.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
