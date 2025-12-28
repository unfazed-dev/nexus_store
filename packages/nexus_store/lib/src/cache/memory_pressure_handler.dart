import 'package:rxdart/rxdart.dart';

import 'memory_pressure_level.dart';

/// Interface for detecting and reporting memory pressure levels.
///
/// Implementations can use various strategies to detect memory pressure:
/// - Threshold-based (pure Dart): Compare cache size to configured limits
/// - Platform-based (Flutter): Use system memory pressure callbacks
///
/// ## Example
///
/// ```dart
/// final handler = ThresholdMemoryPressureHandler(
///   maxBytes: 50 * 1024 * 1024, // 50MB
///   moderateThreshold: 0.7,
///   criticalThreshold: 0.9,
/// );
///
/// handler.pressureStream.listen((level) {
///   if (level.shouldEvict) {
///     evictCache();
///   }
/// });
///
/// // Update as cache usage changes
/// handler.updateUsage(currentCacheSize);
/// ```
abstract interface class MemoryPressureHandler {
  /// Stream of memory pressure level changes.
  ///
  /// Emits when the pressure level changes, not on every update.
  Stream<MemoryPressureLevel> get pressureStream;

  /// Current memory pressure level.
  MemoryPressureLevel get currentLevel;

  /// Releases resources used by this handler.
  void dispose();
}

/// Memory pressure handler based on usage thresholds.
///
/// Calculates pressure level by comparing current usage against configured
/// thresholds of the maximum cache size.
///
/// ## Example
///
/// ```dart
/// final handler = ThresholdMemoryPressureHandler(
///   maxBytes: 100 * 1024 * 1024, // 100MB limit
///   moderateThreshold: 0.7, // Start evicting at 70%
///   criticalThreshold: 0.9, // Aggressive at 90%
/// );
///
/// // Update with current cache size
/// handler.updateUsage(75 * 1024 * 1024); // 75MB = moderate
/// ```
class ThresholdMemoryPressureHandler implements MemoryPressureHandler {
  /// Creates a threshold-based pressure handler.
  ///
  /// If [maxBytes] is null, the handler always returns [MemoryPressureLevel.none].
  ThresholdMemoryPressureHandler({
    this.maxBytes,
    this.moderateThreshold = 0.7,
    this.criticalThreshold = 0.9,
  }) : _pressureSubject = BehaviorSubject.seeded(MemoryPressureLevel.none);

  /// Maximum cache size in bytes, or null for unlimited.
  final int? maxBytes;

  /// Threshold (0.0-1.0) for moderate pressure.
  final double moderateThreshold;

  /// Threshold (0.0-1.0) for critical pressure.
  final double criticalThreshold;

  final BehaviorSubject<MemoryPressureLevel> _pressureSubject;
  MemoryPressureLevel _currentLevel = MemoryPressureLevel.none;

  @override
  Stream<MemoryPressureLevel> get pressureStream =>
      _pressureSubject.stream.distinct();

  @override
  MemoryPressureLevel get currentLevel => _currentLevel;

  /// Updates the current usage and recalculates pressure level.
  ///
  /// [currentBytes] is the current cache size in bytes.
  void updateUsage(int currentBytes) {
    final max = maxBytes;
    if (max == null || max <= 0) {
      _setLevel(MemoryPressureLevel.none);
      return;
    }

    final ratio = currentBytes / max;

    if (ratio > 1.0) {
      _setLevel(MemoryPressureLevel.emergency);
    } else if (ratio >= criticalThreshold) {
      _setLevel(MemoryPressureLevel.critical);
    } else if (ratio >= moderateThreshold) {
      _setLevel(MemoryPressureLevel.moderate);
    } else {
      _setLevel(MemoryPressureLevel.none);
    }
  }

  /// Triggers emergency level immediately.
  ///
  /// Use this when receiving external memory pressure signals.
  void triggerEmergency() {
    _setLevel(MemoryPressureLevel.emergency);
  }

  /// Resets pressure level to none.
  void reset() {
    _setLevel(MemoryPressureLevel.none);
  }

  void _setLevel(MemoryPressureLevel level) {
    if (_currentLevel != level) {
      _currentLevel = level;
      _pressureSubject.add(level);
    }
  }

  @override
  void dispose() {
    _pressureSubject.close();
  }
}

/// Memory pressure handler for manual control.
///
/// Allows external code to set the pressure level directly,
/// useful for testing or when integrating with platform-specific APIs.
///
/// ## Example
///
/// ```dart
/// final handler = ManualMemoryPressureHandler();
///
/// // Set from platform callback
/// void onSystemMemoryWarning() {
///   handler.setLevel(MemoryPressureLevel.critical);
/// }
/// ```
class ManualMemoryPressureHandler implements MemoryPressureHandler {
  /// Creates a manual pressure handler.
  ManualMemoryPressureHandler()
      : _pressureSubject = BehaviorSubject.seeded(MemoryPressureLevel.none);

  final BehaviorSubject<MemoryPressureLevel> _pressureSubject;
  MemoryPressureLevel _currentLevel = MemoryPressureLevel.none;

  @override
  Stream<MemoryPressureLevel> get pressureStream =>
      _pressureSubject.stream.distinct();

  @override
  MemoryPressureLevel get currentLevel => _currentLevel;

  /// Sets the pressure level.
  void setLevel(MemoryPressureLevel level) {
    if (_currentLevel != level) {
      _currentLevel = level;
      _pressureSubject.add(level);
    }
  }

  @override
  void dispose() {
    _pressureSubject.close();
  }
}
