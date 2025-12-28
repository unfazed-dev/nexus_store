import 'dart:async';

import 'package:nexus_store/src/lazy/lazy_field_state.dart';

/// A wrapper for lazily-loaded field values.
///
/// Provides on-demand loading for heavy fields (blobs, large text) to improve
/// initial load performance and reduce memory usage.
///
/// ## Example
///
/// ```dart
/// final thumbnailField = LazyField<Uint8List>(
///   placeholder: null,
///   loader: () => backend.getField(entityId, 'thumbnail'),
/// );
///
/// // Before loading
/// print(thumbnailField.value); // null (placeholder)
/// print(thumbnailField.isLoaded); // false
///
/// // Load the field
/// final thumbnail = await thumbnailField.load();
///
/// // After loading
/// print(thumbnailField.value); // Uint8List(...)
/// print(thumbnailField.isLoaded); // true
/// ```
class LazyField<T> {
  /// Creates a lazy field with a loader function.
  ///
  /// The [loader] function is called when [load] is invoked.
  /// The optional [placeholder] value is returned by [value] when the
  /// field is not loaded.
  LazyField({
    this.placeholder,
    required Future<T> Function() loader,
  })  : _loader = loader,
        _state = LazyFieldState.notLoaded,
        _value = null,
        _errorMessage = null;

  /// Creates a lazy field that is already loaded with a value.
  ///
  /// Use this for fields that were eagerly loaded or for testing.
  LazyField.loaded(T value)
      : placeholder = null,
        _loader = (() async => value),
        _state = LazyFieldState.loaded,
        _value = value,
        _errorMessage = null;

  /// The placeholder value returned when the field is not loaded.
  final T? placeholder;

  final Future<T> Function() _loader;

  LazyFieldState _state;
  T? _value;
  String? _errorMessage;
  Future<T>? _loadFuture;

  /// The current loading state of this field.
  LazyFieldState get state => _state;

  /// Whether the field has been successfully loaded.
  bool get isLoaded => _state == LazyFieldState.loaded;

  /// Whether the field is currently being loaded.
  bool get isLoading => _state == LazyFieldState.loading;

  /// Whether the field is in an error state.
  bool get hasError => _state == LazyFieldState.error;

  /// The loaded value, or [placeholder] if not loaded.
  ///
  /// Returns `null` if no placeholder is set and field is not loaded.
  T? get value => isLoaded ? _value : placeholder;

  /// The loaded value, throwing [StateError] if not loaded.
  ///
  /// Use [isLoaded] to check before calling, or use [value] for a
  /// nullable result with placeholder fallback.
  T get requireValue {
    if (!isLoaded) {
      throw StateError(
        'LazyField value is not loaded. Call load() first or use value getter.',
      );
    }
    return _value as T;
  }

  /// Error message if loading failed, or `null` if no error.
  String? get errorMessage => _errorMessage;

  /// Loads the field value.
  ///
  /// If the field is already loaded, returns the cached value.
  /// If a load is in progress, returns the existing future.
  ///
  /// Throws any exception from the loader function.
  Future<T> load() {
    // Return cached value if already loaded
    if (isLoaded) {
      return Future.value(_value);
    }

    // Return existing load future if loading
    if (_loadFuture != null) {
      return _loadFuture!;
    }

    // Start new load
    _state = LazyFieldState.loading;
    _loadFuture = _doLoad();
    return _loadFuture!;
  }

  Future<T> _doLoad() async {
    try {
      final result = await _loader();
      _value = result;
      _state = LazyFieldState.loaded;
      _errorMessage = null;
      _loadFuture = null;
      return result;
    } catch (e) {
      _state = LazyFieldState.error;
      _errorMessage = e.toString();
      _loadFuture = null;
      rethrow;
    }
  }

  /// Resets the field to its initial unloaded state.
  ///
  /// Clears any loaded value, error message, and resets state to [notLoaded].
  /// After reset, [load] can be called again to reload the field.
  void reset() {
    _state = LazyFieldState.notLoaded;
    _value = null;
    _errorMessage = null;
    _loadFuture = null;
  }
}
