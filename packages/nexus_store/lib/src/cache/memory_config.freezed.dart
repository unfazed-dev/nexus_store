// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memory_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemoryConfig {
  /// Maximum cache size in bytes.
  ///
  /// When null, the cache is unlimited (no automatic eviction based on size).
  /// When set, cache eviction is triggered when usage exceeds thresholds.
  int? get maxCacheBytes;

  /// Threshold (0.0-1.0) for moderate memory pressure.
  ///
  /// When cache usage exceeds this percentage of [maxCacheBytes],
  /// the system starts evicting items in batches using the configured
  /// [strategy]. Defaults to 0.7 (70%).
  double get moderateThreshold;

  /// Threshold (0.0-1.0) for critical memory pressure.
  ///
  /// When cache usage exceeds this percentage of [maxCacheBytes],
  /// the system performs aggressive eviction. Defaults to 0.9 (90%).
  double get criticalThreshold;

  /// Number of items to evict per batch.
  ///
  /// When eviction is triggered, this many items are removed at once.
  /// Larger batches are more efficient but may cause UI jank.
  /// Defaults to 10.
  int get evictionBatchSize;

  /// Strategy for selecting which items to evict.
  ///
  /// Defaults to [EvictionStrategy.lru] (least recently used).
  EvictionStrategy get strategy;

  /// Create a copy of MemoryConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MemoryConfigCopyWith<MemoryConfig> get copyWith =>
      _$MemoryConfigCopyWithImpl<MemoryConfig>(
          this as MemoryConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MemoryConfig &&
            (identical(other.maxCacheBytes, maxCacheBytes) ||
                other.maxCacheBytes == maxCacheBytes) &&
            (identical(other.moderateThreshold, moderateThreshold) ||
                other.moderateThreshold == moderateThreshold) &&
            (identical(other.criticalThreshold, criticalThreshold) ||
                other.criticalThreshold == criticalThreshold) &&
            (identical(other.evictionBatchSize, evictionBatchSize) ||
                other.evictionBatchSize == evictionBatchSize) &&
            (identical(other.strategy, strategy) ||
                other.strategy == strategy));
  }

  @override
  int get hashCode => Object.hash(runtimeType, maxCacheBytes, moderateThreshold,
      criticalThreshold, evictionBatchSize, strategy);

  @override
  String toString() {
    return 'MemoryConfig(maxCacheBytes: $maxCacheBytes, moderateThreshold: $moderateThreshold, criticalThreshold: $criticalThreshold, evictionBatchSize: $evictionBatchSize, strategy: $strategy)';
  }
}

/// @nodoc
abstract mixin class $MemoryConfigCopyWith<$Res> {
  factory $MemoryConfigCopyWith(
          MemoryConfig value, $Res Function(MemoryConfig) _then) =
      _$MemoryConfigCopyWithImpl;
  @useResult
  $Res call(
      {int? maxCacheBytes,
      double moderateThreshold,
      double criticalThreshold,
      int evictionBatchSize,
      EvictionStrategy strategy});
}

/// @nodoc
class _$MemoryConfigCopyWithImpl<$Res> implements $MemoryConfigCopyWith<$Res> {
  _$MemoryConfigCopyWithImpl(this._self, this._then);

  final MemoryConfig _self;
  final $Res Function(MemoryConfig) _then;

  /// Create a copy of MemoryConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxCacheBytes = freezed,
    Object? moderateThreshold = null,
    Object? criticalThreshold = null,
    Object? evictionBatchSize = null,
    Object? strategy = null,
  }) {
    return _then(_self.copyWith(
      maxCacheBytes: freezed == maxCacheBytes
          ? _self.maxCacheBytes
          : maxCacheBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      moderateThreshold: null == moderateThreshold
          ? _self.moderateThreshold
          : moderateThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      criticalThreshold: null == criticalThreshold
          ? _self.criticalThreshold
          : criticalThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      evictionBatchSize: null == evictionBatchSize
          ? _self.evictionBatchSize
          : evictionBatchSize // ignore: cast_nullable_to_non_nullable
              as int,
      strategy: null == strategy
          ? _self.strategy
          : strategy // ignore: cast_nullable_to_non_nullable
              as EvictionStrategy,
    ));
  }
}

/// Adds pattern-matching-related methods to [MemoryConfig].
extension MemoryConfigPatterns on MemoryConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_MemoryConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MemoryConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_MemoryConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemoryConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_MemoryConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemoryConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            int? maxCacheBytes,
            double moderateThreshold,
            double criticalThreshold,
            int evictionBatchSize,
            EvictionStrategy strategy)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MemoryConfig() when $default != null:
        return $default(_that.maxCacheBytes, _that.moderateThreshold,
            _that.criticalThreshold, _that.evictionBatchSize, _that.strategy);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            int? maxCacheBytes,
            double moderateThreshold,
            double criticalThreshold,
            int evictionBatchSize,
            EvictionStrategy strategy)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemoryConfig():
        return $default(_that.maxCacheBytes, _that.moderateThreshold,
            _that.criticalThreshold, _that.evictionBatchSize, _that.strategy);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            int? maxCacheBytes,
            double moderateThreshold,
            double criticalThreshold,
            int evictionBatchSize,
            EvictionStrategy strategy)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemoryConfig() when $default != null:
        return $default(_that.maxCacheBytes, _that.moderateThreshold,
            _that.criticalThreshold, _that.evictionBatchSize, _that.strategy);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MemoryConfig extends MemoryConfig {
  const _MemoryConfig(
      {this.maxCacheBytes,
      this.moderateThreshold = 0.7,
      this.criticalThreshold = 0.9,
      this.evictionBatchSize = 10,
      this.strategy = EvictionStrategy.lru})
      : super._();

  /// Maximum cache size in bytes.
  ///
  /// When null, the cache is unlimited (no automatic eviction based on size).
  /// When set, cache eviction is triggered when usage exceeds thresholds.
  @override
  final int? maxCacheBytes;

  /// Threshold (0.0-1.0) for moderate memory pressure.
  ///
  /// When cache usage exceeds this percentage of [maxCacheBytes],
  /// the system starts evicting items in batches using the configured
  /// [strategy]. Defaults to 0.7 (70%).
  @override
  @JsonKey()
  final double moderateThreshold;

  /// Threshold (0.0-1.0) for critical memory pressure.
  ///
  /// When cache usage exceeds this percentage of [maxCacheBytes],
  /// the system performs aggressive eviction. Defaults to 0.9 (90%).
  @override
  @JsonKey()
  final double criticalThreshold;

  /// Number of items to evict per batch.
  ///
  /// When eviction is triggered, this many items are removed at once.
  /// Larger batches are more efficient but may cause UI jank.
  /// Defaults to 10.
  @override
  @JsonKey()
  final int evictionBatchSize;

  /// Strategy for selecting which items to evict.
  ///
  /// Defaults to [EvictionStrategy.lru] (least recently used).
  @override
  @JsonKey()
  final EvictionStrategy strategy;

  /// Create a copy of MemoryConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MemoryConfigCopyWith<_MemoryConfig> get copyWith =>
      __$MemoryConfigCopyWithImpl<_MemoryConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MemoryConfig &&
            (identical(other.maxCacheBytes, maxCacheBytes) ||
                other.maxCacheBytes == maxCacheBytes) &&
            (identical(other.moderateThreshold, moderateThreshold) ||
                other.moderateThreshold == moderateThreshold) &&
            (identical(other.criticalThreshold, criticalThreshold) ||
                other.criticalThreshold == criticalThreshold) &&
            (identical(other.evictionBatchSize, evictionBatchSize) ||
                other.evictionBatchSize == evictionBatchSize) &&
            (identical(other.strategy, strategy) ||
                other.strategy == strategy));
  }

  @override
  int get hashCode => Object.hash(runtimeType, maxCacheBytes, moderateThreshold,
      criticalThreshold, evictionBatchSize, strategy);

  @override
  String toString() {
    return 'MemoryConfig(maxCacheBytes: $maxCacheBytes, moderateThreshold: $moderateThreshold, criticalThreshold: $criticalThreshold, evictionBatchSize: $evictionBatchSize, strategy: $strategy)';
  }
}

/// @nodoc
abstract mixin class _$MemoryConfigCopyWith<$Res>
    implements $MemoryConfigCopyWith<$Res> {
  factory _$MemoryConfigCopyWith(
          _MemoryConfig value, $Res Function(_MemoryConfig) _then) =
      __$MemoryConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? maxCacheBytes,
      double moderateThreshold,
      double criticalThreshold,
      int evictionBatchSize,
      EvictionStrategy strategy});
}

/// @nodoc
class __$MemoryConfigCopyWithImpl<$Res>
    implements _$MemoryConfigCopyWith<$Res> {
  __$MemoryConfigCopyWithImpl(this._self, this._then);

  final _MemoryConfig _self;
  final $Res Function(_MemoryConfig) _then;

  /// Create a copy of MemoryConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? maxCacheBytes = freezed,
    Object? moderateThreshold = null,
    Object? criticalThreshold = null,
    Object? evictionBatchSize = null,
    Object? strategy = null,
  }) {
    return _then(_MemoryConfig(
      maxCacheBytes: freezed == maxCacheBytes
          ? _self.maxCacheBytes
          : maxCacheBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      moderateThreshold: null == moderateThreshold
          ? _self.moderateThreshold
          : moderateThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      criticalThreshold: null == criticalThreshold
          ? _self.criticalThreshold
          : criticalThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      evictionBatchSize: null == evictionBatchSize
          ? _self.evictionBatchSize
          : evictionBatchSize // ignore: cast_nullable_to_non_nullable
              as int,
      strategy: null == strategy
          ? _self.strategy
          : strategy // ignore: cast_nullable_to_non_nullable
              as EvictionStrategy,
    ));
  }
}

// dart format on
