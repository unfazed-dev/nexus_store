import 'package:flutter/widgets.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:rxdart/rxdart.dart';

/// A [MemoryPressureHandler] that responds to system memory pressure events.
///
/// Uses [WidgetsBindingObserver] to detect when the platform reports memory
/// pressure, mapping system events to [MemoryPressureLevel] values.
///
/// ## Example
///
/// ```dart
/// final handler = FlutterMemoryPressureHandler();
///
/// // Listen for pressure changes
/// handler.pressureStream.listen((level) {
///   if (level.shouldEvict) {
///     cache.evict();
///   }
/// });
///
/// // Clean up when done
/// handler.dispose();
/// ```
class FlutterMemoryPressureHandler
    with WidgetsBindingObserver
    implements MemoryPressureHandler {
  /// Creates a Flutter memory pressure handler.
  ///
  /// The handler automatically registers itself with [WidgetsBinding]
  /// to receive memory pressure notifications.
  FlutterMemoryPressureHandler() {
    _binding = WidgetsBinding.instance;
    _binding.addObserver(this);
  }

  late final WidgetsBinding _binding;
  final BehaviorSubject<MemoryPressureLevel> _levelSubject =
      BehaviorSubject.seeded(MemoryPressureLevel.none);

  @override
  MemoryPressureLevel get currentLevel => _levelSubject.value;

  @override
  Stream<MemoryPressureLevel> get pressureStream =>
      _levelSubject.stream.distinct();

  /// Called when the system notifies the app of a memory pressure event.
  ///
  /// Maps to [MemoryPressureLevel.critical] since Flutter doesn't provide
  /// granular pressure levels.
  @override
  void didHaveMemoryPressure() {
    _levelSubject.add(MemoryPressureLevel.critical);
  }

  /// Manually sets the pressure level.
  ///
  /// Useful for testing or custom pressure detection.
  void setLevel(MemoryPressureLevel level) {
    _levelSubject.add(level);
  }

  /// Resets the pressure level to [MemoryPressureLevel.none].
  ///
  /// Call this after handling a memory pressure event.
  void reset() {
    _levelSubject.add(MemoryPressureLevel.none);
  }

  /// Triggers an emergency pressure level.
  ///
  /// Use this for critical memory situations that require immediate action.
  void triggerEmergency() {
    _levelSubject.add(MemoryPressureLevel.emergency);
  }

  @override
  void dispose() {
    _binding.removeObserver(this);
    _levelSubject.close();
  }
}
