import 'package:freezed_annotation/freezed_annotation.dart';

part 'lazy_load_config.freezed.dart';

/// Configuration for lazy field loading.
///
/// Specifies which fields should be loaded on-demand rather than eagerly,
/// along with batching and preloading behavior.
///
/// ## Example
///
/// ```dart
/// final config = LazyLoadConfig(
///   lazyFields: {'thumbnail', 'fullImage', 'video'},
///   batchSize: 10,
///   placeholders: {
///     'thumbnail': null,
///     'fullImage': null,
///     'video': null,
///   },
/// );
///
/// // Check if a field is lazy
/// print(config.isLazyField('thumbnail')); // true
/// print(config.isLazyField('name')); // false
/// ```
@freezed
abstract class LazyLoadConfig with _$LazyLoadConfig {
  /// Creates a lazy load configuration.
  const factory LazyLoadConfig({
    /// Fields to load lazily.
    ///
    /// These fields will not be loaded with the entity by default and must
    /// be explicitly loaded via [NexusStore.loadField] or similar methods.
    @Default({}) Set<String> lazyFields,

    /// Maximum number of field load requests to batch together.
    ///
    /// When multiple field load requests are made within [batchDelay],
    /// they are combined into a single backend call up to this limit.
    @Default(10) int batchSize,

    /// Duration to wait before executing a batch of field loads.
    ///
    /// Requests made within this window are batched together.
    @Default(Duration(milliseconds: 50)) Duration batchDelay,

    /// Whether to preload lazy fields when watching an entity.
    ///
    /// When true, lazy fields are automatically loaded when an entity
    /// is watched via [NexusStore.watch] or [NexusStore.watchAll].
    @Default(false) bool preloadOnWatch,

    /// Default placeholder values per field.
    ///
    /// When a lazy field is not loaded, [getPlaceholder] returns the
    /// value configured here, or null if not specified.
    @Default({}) Map<String, dynamic> placeholders,
  }) = _LazyLoadConfig;

  const LazyLoadConfig._();

  /// Configuration with lazy loading disabled.
  ///
  /// Use this as a default when lazy loading is not needed.
  static const LazyLoadConfig off = LazyLoadConfig();

  /// Configuration preset for media-heavy entities.
  ///
  /// Pre-configured for common media fields like thumbnails and images.
  static const LazyLoadConfig media = LazyLoadConfig(
    lazyFields: {'thumbnail', 'fullImage', 'video'},
    batchSize: 5,
  );

  /// Returns `true` if [fieldName] should be loaded lazily.
  bool isLazyField(String fieldName) => lazyFields.contains(fieldName);

  /// Returns the placeholder value for [fieldName], or `null` if not configured.
  dynamic getPlaceholder(String fieldName) => placeholders[fieldName];

  /// Returns `true` if any lazy fields are configured.
  bool get hasLazyFields => lazyFields.isNotEmpty;
}
