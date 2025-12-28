// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StoreConfig {
  /// Default fetch policy for read operations.
  FetchPolicy get fetchPolicy;

  /// Default write policy for write operations.
  WritePolicy get writePolicy;

  /// Synchronization mode.
  SyncMode get syncMode;

  /// Conflict resolution strategy.
  ConflictResolution get conflictResolution;

  /// Retry configuration for failed operations.
  RetryConfig get retryConfig;

  /// Encryption configuration.
  EncryptionConfig get encryption;

  /// Whether to enable audit logging.
  bool get enableAuditLogging;

  /// Whether to enable GDPR compliance features.
  bool get enableGdpr;

  /// GDPR configuration for enhanced compliance features.
  ///
  /// Provides configuration for data minimization, consent tracking,
  /// and breach notification. When provided, enables the enhanced GDPR
  /// compliance features (REQ-026, REQ-027, REQ-028).
  GdprConfig? get gdpr;

  /// Duration to cache data before considering it stale.
  Duration? get staleDuration;

  /// Interval for periodic sync (when syncMode is periodic).
  Duration? get syncInterval;

  /// Custom table/collection name override.
  String? get tableName;

  /// Metrics reporter for telemetry (defaults to no-op).
  MetricsReporter get metricsReporter;

  /// Metrics configuration for sampling and buffering.
  MetricsConfig get metricsConfig;

  /// Default timeout for transactions.
  ///
  /// If a transaction takes longer than this duration, it will be
  /// automatically rolled back with a [TransactionError].
  Duration get transactionTimeout;

  /// Delta sync configuration for field-level change tracking.
  ///
  /// When enabled, only changed fields are synced instead of entire entities,
  /// reducing bandwidth usage. See [DeltaSyncConfig] for options.
  DeltaSyncConfig? get deltaSync;

  /// Interceptors for pre/post processing of store operations.
  ///
  /// Interceptors are called in order for requests (first to last) and
  /// in reverse order for responses/errors (last to first).
  ///
  /// ## Example
  ///
  /// ```dart
  /// final config = StoreConfig(
  ///   interceptors: [
  ///     LoggingInterceptor(),
  ///     AuthInterceptor(authService),
  ///     CachingInterceptor(cache),
  ///   ],
  /// );
  /// ```
  List<StoreInterceptor> get interceptors;

  /// Lazy loading configuration for heavy fields.
  ///
  /// When configured, enables on-demand loading for specified fields
  /// (e.g., images, blobs, large text) to improve initial load performance.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final config = StoreConfig(
  ///   lazyLoad: LazyLoadConfig(
  ///     lazyFields: {'thumbnail', 'fullImage', 'video'},
  ///     batchSize: 10,
  ///   ),
  /// );
  /// ```
  LazyLoadConfig? get lazyLoad;

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StoreConfigCopyWith<StoreConfig> get copyWith =>
      _$StoreConfigCopyWithImpl<StoreConfig>(this as StoreConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StoreConfig &&
            (identical(other.fetchPolicy, fetchPolicy) ||
                other.fetchPolicy == fetchPolicy) &&
            (identical(other.writePolicy, writePolicy) ||
                other.writePolicy == writePolicy) &&
            (identical(other.syncMode, syncMode) ||
                other.syncMode == syncMode) &&
            (identical(other.conflictResolution, conflictResolution) ||
                other.conflictResolution == conflictResolution) &&
            (identical(other.retryConfig, retryConfig) ||
                other.retryConfig == retryConfig) &&
            (identical(other.encryption, encryption) ||
                other.encryption == encryption) &&
            (identical(other.enableAuditLogging, enableAuditLogging) ||
                other.enableAuditLogging == enableAuditLogging) &&
            (identical(other.enableGdpr, enableGdpr) ||
                other.enableGdpr == enableGdpr) &&
            (identical(other.gdpr, gdpr) || other.gdpr == gdpr) &&
            (identical(other.staleDuration, staleDuration) ||
                other.staleDuration == staleDuration) &&
            (identical(other.syncInterval, syncInterval) ||
                other.syncInterval == syncInterval) &&
            (identical(other.tableName, tableName) ||
                other.tableName == tableName) &&
            (identical(other.metricsReporter, metricsReporter) ||
                other.metricsReporter == metricsReporter) &&
            (identical(other.metricsConfig, metricsConfig) ||
                other.metricsConfig == metricsConfig) &&
            (identical(other.transactionTimeout, transactionTimeout) ||
                other.transactionTimeout == transactionTimeout) &&
            (identical(other.deltaSync, deltaSync) ||
                other.deltaSync == deltaSync) &&
            const DeepCollectionEquality()
                .equals(other.interceptors, interceptors) &&
            (identical(other.lazyLoad, lazyLoad) ||
                other.lazyLoad == lazyLoad));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      fetchPolicy,
      writePolicy,
      syncMode,
      conflictResolution,
      retryConfig,
      encryption,
      enableAuditLogging,
      enableGdpr,
      gdpr,
      staleDuration,
      syncInterval,
      tableName,
      metricsReporter,
      metricsConfig,
      transactionTimeout,
      deltaSync,
      const DeepCollectionEquality().hash(interceptors),
      lazyLoad);

  @override
  String toString() {
    return 'StoreConfig(fetchPolicy: $fetchPolicy, writePolicy: $writePolicy, syncMode: $syncMode, conflictResolution: $conflictResolution, retryConfig: $retryConfig, encryption: $encryption, enableAuditLogging: $enableAuditLogging, enableGdpr: $enableGdpr, gdpr: $gdpr, staleDuration: $staleDuration, syncInterval: $syncInterval, tableName: $tableName, metricsReporter: $metricsReporter, metricsConfig: $metricsConfig, transactionTimeout: $transactionTimeout, deltaSync: $deltaSync, interceptors: $interceptors, lazyLoad: $lazyLoad)';
  }
}

/// @nodoc
abstract mixin class $StoreConfigCopyWith<$Res> {
  factory $StoreConfigCopyWith(
          StoreConfig value, $Res Function(StoreConfig) _then) =
      _$StoreConfigCopyWithImpl;
  @useResult
  $Res call(
      {FetchPolicy fetchPolicy,
      WritePolicy writePolicy,
      SyncMode syncMode,
      ConflictResolution conflictResolution,
      RetryConfig retryConfig,
      EncryptionConfig encryption,
      bool enableAuditLogging,
      bool enableGdpr,
      GdprConfig? gdpr,
      Duration? staleDuration,
      Duration? syncInterval,
      String? tableName,
      MetricsReporter metricsReporter,
      MetricsConfig metricsConfig,
      Duration transactionTimeout,
      DeltaSyncConfig? deltaSync,
      List<StoreInterceptor> interceptors,
      LazyLoadConfig? lazyLoad});

  $EncryptionConfigCopyWith<$Res> get encryption;
  $GdprConfigCopyWith<$Res>? get gdpr;
  $MetricsConfigCopyWith<$Res> get metricsConfig;
  $DeltaSyncConfigCopyWith<$Res>? get deltaSync;
  $LazyLoadConfigCopyWith<$Res>? get lazyLoad;
}

/// @nodoc
class _$StoreConfigCopyWithImpl<$Res> implements $StoreConfigCopyWith<$Res> {
  _$StoreConfigCopyWithImpl(this._self, this._then);

  final StoreConfig _self;
  final $Res Function(StoreConfig) _then;

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fetchPolicy = null,
    Object? writePolicy = null,
    Object? syncMode = null,
    Object? conflictResolution = null,
    Object? retryConfig = null,
    Object? encryption = null,
    Object? enableAuditLogging = null,
    Object? enableGdpr = null,
    Object? gdpr = freezed,
    Object? staleDuration = freezed,
    Object? syncInterval = freezed,
    Object? tableName = freezed,
    Object? metricsReporter = null,
    Object? metricsConfig = null,
    Object? transactionTimeout = null,
    Object? deltaSync = freezed,
    Object? interceptors = null,
    Object? lazyLoad = freezed,
  }) {
    return _then(_self.copyWith(
      fetchPolicy: null == fetchPolicy
          ? _self.fetchPolicy
          : fetchPolicy // ignore: cast_nullable_to_non_nullable
              as FetchPolicy,
      writePolicy: null == writePolicy
          ? _self.writePolicy
          : writePolicy // ignore: cast_nullable_to_non_nullable
              as WritePolicy,
      syncMode: null == syncMode
          ? _self.syncMode
          : syncMode // ignore: cast_nullable_to_non_nullable
              as SyncMode,
      conflictResolution: null == conflictResolution
          ? _self.conflictResolution
          : conflictResolution // ignore: cast_nullable_to_non_nullable
              as ConflictResolution,
      retryConfig: null == retryConfig
          ? _self.retryConfig
          : retryConfig // ignore: cast_nullable_to_non_nullable
              as RetryConfig,
      encryption: null == encryption
          ? _self.encryption
          : encryption // ignore: cast_nullable_to_non_nullable
              as EncryptionConfig,
      enableAuditLogging: null == enableAuditLogging
          ? _self.enableAuditLogging
          : enableAuditLogging // ignore: cast_nullable_to_non_nullable
              as bool,
      enableGdpr: null == enableGdpr
          ? _self.enableGdpr
          : enableGdpr // ignore: cast_nullable_to_non_nullable
              as bool,
      gdpr: freezed == gdpr
          ? _self.gdpr
          : gdpr // ignore: cast_nullable_to_non_nullable
              as GdprConfig?,
      staleDuration: freezed == staleDuration
          ? _self.staleDuration
          : staleDuration // ignore: cast_nullable_to_non_nullable
              as Duration?,
      syncInterval: freezed == syncInterval
          ? _self.syncInterval
          : syncInterval // ignore: cast_nullable_to_non_nullable
              as Duration?,
      tableName: freezed == tableName
          ? _self.tableName
          : tableName // ignore: cast_nullable_to_non_nullable
              as String?,
      metricsReporter: null == metricsReporter
          ? _self.metricsReporter
          : metricsReporter // ignore: cast_nullable_to_non_nullable
              as MetricsReporter,
      metricsConfig: null == metricsConfig
          ? _self.metricsConfig
          : metricsConfig // ignore: cast_nullable_to_non_nullable
              as MetricsConfig,
      transactionTimeout: null == transactionTimeout
          ? _self.transactionTimeout
          : transactionTimeout // ignore: cast_nullable_to_non_nullable
              as Duration,
      deltaSync: freezed == deltaSync
          ? _self.deltaSync
          : deltaSync // ignore: cast_nullable_to_non_nullable
              as DeltaSyncConfig?,
      interceptors: null == interceptors
          ? _self.interceptors
          : interceptors // ignore: cast_nullable_to_non_nullable
              as List<StoreInterceptor>,
      lazyLoad: freezed == lazyLoad
          ? _self.lazyLoad
          : lazyLoad // ignore: cast_nullable_to_non_nullable
              as LazyLoadConfig?,
    ));
  }

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EncryptionConfigCopyWith<$Res> get encryption {
    return $EncryptionConfigCopyWith<$Res>(_self.encryption, (value) {
      return _then(_self.copyWith(encryption: value));
    });
  }

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GdprConfigCopyWith<$Res>? get gdpr {
    if (_self.gdpr == null) {
      return null;
    }

    return $GdprConfigCopyWith<$Res>(_self.gdpr!, (value) {
      return _then(_self.copyWith(gdpr: value));
    });
  }

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MetricsConfigCopyWith<$Res> get metricsConfig {
    return $MetricsConfigCopyWith<$Res>(_self.metricsConfig, (value) {
      return _then(_self.copyWith(metricsConfig: value));
    });
  }

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DeltaSyncConfigCopyWith<$Res>? get deltaSync {
    if (_self.deltaSync == null) {
      return null;
    }

    return $DeltaSyncConfigCopyWith<$Res>(_self.deltaSync!, (value) {
      return _then(_self.copyWith(deltaSync: value));
    });
  }

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LazyLoadConfigCopyWith<$Res>? get lazyLoad {
    if (_self.lazyLoad == null) {
      return null;
    }

    return $LazyLoadConfigCopyWith<$Res>(_self.lazyLoad!, (value) {
      return _then(_self.copyWith(lazyLoad: value));
    });
  }
}

/// Adds pattern-matching-related methods to [StoreConfig].
extension StoreConfigPatterns on StoreConfig {
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
    TResult Function(_StoreConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _StoreConfig() when $default != null:
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
    TResult Function(_StoreConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StoreConfig():
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
    TResult? Function(_StoreConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StoreConfig() when $default != null:
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
            FetchPolicy fetchPolicy,
            WritePolicy writePolicy,
            SyncMode syncMode,
            ConflictResolution conflictResolution,
            RetryConfig retryConfig,
            EncryptionConfig encryption,
            bool enableAuditLogging,
            bool enableGdpr,
            GdprConfig? gdpr,
            Duration? staleDuration,
            Duration? syncInterval,
            String? tableName,
            MetricsReporter metricsReporter,
            MetricsConfig metricsConfig,
            Duration transactionTimeout,
            DeltaSyncConfig? deltaSync,
            List<StoreInterceptor> interceptors,
            LazyLoadConfig? lazyLoad)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _StoreConfig() when $default != null:
        return $default(
            _that.fetchPolicy,
            _that.writePolicy,
            _that.syncMode,
            _that.conflictResolution,
            _that.retryConfig,
            _that.encryption,
            _that.enableAuditLogging,
            _that.enableGdpr,
            _that.gdpr,
            _that.staleDuration,
            _that.syncInterval,
            _that.tableName,
            _that.metricsReporter,
            _that.metricsConfig,
            _that.transactionTimeout,
            _that.deltaSync,
            _that.interceptors,
            _that.lazyLoad);
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
            FetchPolicy fetchPolicy,
            WritePolicy writePolicy,
            SyncMode syncMode,
            ConflictResolution conflictResolution,
            RetryConfig retryConfig,
            EncryptionConfig encryption,
            bool enableAuditLogging,
            bool enableGdpr,
            GdprConfig? gdpr,
            Duration? staleDuration,
            Duration? syncInterval,
            String? tableName,
            MetricsReporter metricsReporter,
            MetricsConfig metricsConfig,
            Duration transactionTimeout,
            DeltaSyncConfig? deltaSync,
            List<StoreInterceptor> interceptors,
            LazyLoadConfig? lazyLoad)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StoreConfig():
        return $default(
            _that.fetchPolicy,
            _that.writePolicy,
            _that.syncMode,
            _that.conflictResolution,
            _that.retryConfig,
            _that.encryption,
            _that.enableAuditLogging,
            _that.enableGdpr,
            _that.gdpr,
            _that.staleDuration,
            _that.syncInterval,
            _that.tableName,
            _that.metricsReporter,
            _that.metricsConfig,
            _that.transactionTimeout,
            _that.deltaSync,
            _that.interceptors,
            _that.lazyLoad);
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
            FetchPolicy fetchPolicy,
            WritePolicy writePolicy,
            SyncMode syncMode,
            ConflictResolution conflictResolution,
            RetryConfig retryConfig,
            EncryptionConfig encryption,
            bool enableAuditLogging,
            bool enableGdpr,
            GdprConfig? gdpr,
            Duration? staleDuration,
            Duration? syncInterval,
            String? tableName,
            MetricsReporter metricsReporter,
            MetricsConfig metricsConfig,
            Duration transactionTimeout,
            DeltaSyncConfig? deltaSync,
            List<StoreInterceptor> interceptors,
            LazyLoadConfig? lazyLoad)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StoreConfig() when $default != null:
        return $default(
            _that.fetchPolicy,
            _that.writePolicy,
            _that.syncMode,
            _that.conflictResolution,
            _that.retryConfig,
            _that.encryption,
            _that.enableAuditLogging,
            _that.enableGdpr,
            _that.gdpr,
            _that.staleDuration,
            _that.syncInterval,
            _that.tableName,
            _that.metricsReporter,
            _that.metricsConfig,
            _that.transactionTimeout,
            _that.deltaSync,
            _that.interceptors,
            _that.lazyLoad);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _StoreConfig extends StoreConfig {
  const _StoreConfig(
      {this.fetchPolicy = FetchPolicy.cacheFirst,
      this.writePolicy = WritePolicy.cacheAndNetwork,
      this.syncMode = SyncMode.realtime,
      this.conflictResolution = ConflictResolution.serverWins,
      this.retryConfig = RetryConfig.defaults,
      this.encryption = const EncryptionConfig.none(),
      this.enableAuditLogging = false,
      this.enableGdpr = false,
      this.gdpr,
      this.staleDuration,
      this.syncInterval,
      this.tableName,
      this.metricsReporter = const NoOpMetricsReporter(),
      this.metricsConfig = MetricsConfig.defaults,
      this.transactionTimeout = const Duration(seconds: 30),
      this.deltaSync,
      final List<StoreInterceptor> interceptors = const [],
      this.lazyLoad})
      : _interceptors = interceptors,
        super._();

  /// Default fetch policy for read operations.
  @override
  @JsonKey()
  final FetchPolicy fetchPolicy;

  /// Default write policy for write operations.
  @override
  @JsonKey()
  final WritePolicy writePolicy;

  /// Synchronization mode.
  @override
  @JsonKey()
  final SyncMode syncMode;

  /// Conflict resolution strategy.
  @override
  @JsonKey()
  final ConflictResolution conflictResolution;

  /// Retry configuration for failed operations.
  @override
  @JsonKey()
  final RetryConfig retryConfig;

  /// Encryption configuration.
  @override
  @JsonKey()
  final EncryptionConfig encryption;

  /// Whether to enable audit logging.
  @override
  @JsonKey()
  final bool enableAuditLogging;

  /// Whether to enable GDPR compliance features.
  @override
  @JsonKey()
  final bool enableGdpr;

  /// GDPR configuration for enhanced compliance features.
  ///
  /// Provides configuration for data minimization, consent tracking,
  /// and breach notification. When provided, enables the enhanced GDPR
  /// compliance features (REQ-026, REQ-027, REQ-028).
  @override
  final GdprConfig? gdpr;

  /// Duration to cache data before considering it stale.
  @override
  final Duration? staleDuration;

  /// Interval for periodic sync (when syncMode is periodic).
  @override
  final Duration? syncInterval;

  /// Custom table/collection name override.
  @override
  final String? tableName;

  /// Metrics reporter for telemetry (defaults to no-op).
  @override
  @JsonKey()
  final MetricsReporter metricsReporter;

  /// Metrics configuration for sampling and buffering.
  @override
  @JsonKey()
  final MetricsConfig metricsConfig;

  /// Default timeout for transactions.
  ///
  /// If a transaction takes longer than this duration, it will be
  /// automatically rolled back with a [TransactionError].
  @override
  @JsonKey()
  final Duration transactionTimeout;

  /// Delta sync configuration for field-level change tracking.
  ///
  /// When enabled, only changed fields are synced instead of entire entities,
  /// reducing bandwidth usage. See [DeltaSyncConfig] for options.
  @override
  final DeltaSyncConfig? deltaSync;

  /// Interceptors for pre/post processing of store operations.
  ///
  /// Interceptors are called in order for requests (first to last) and
  /// in reverse order for responses/errors (last to first).
  ///
  /// ## Example
  ///
  /// ```dart
  /// final config = StoreConfig(
  ///   interceptors: [
  ///     LoggingInterceptor(),
  ///     AuthInterceptor(authService),
  ///     CachingInterceptor(cache),
  ///   ],
  /// );
  /// ```
  final List<StoreInterceptor> _interceptors;

  /// Interceptors for pre/post processing of store operations.
  ///
  /// Interceptors are called in order for requests (first to last) and
  /// in reverse order for responses/errors (last to first).
  ///
  /// ## Example
  ///
  /// ```dart
  /// final config = StoreConfig(
  ///   interceptors: [
  ///     LoggingInterceptor(),
  ///     AuthInterceptor(authService),
  ///     CachingInterceptor(cache),
  ///   ],
  /// );
  /// ```
  @override
  @JsonKey()
  List<StoreInterceptor> get interceptors {
    if (_interceptors is EqualUnmodifiableListView) return _interceptors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_interceptors);
  }

  /// Lazy loading configuration for heavy fields.
  ///
  /// When configured, enables on-demand loading for specified fields
  /// (e.g., images, blobs, large text) to improve initial load performance.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final config = StoreConfig(
  ///   lazyLoad: LazyLoadConfig(
  ///     lazyFields: {'thumbnail', 'fullImage', 'video'},
  ///     batchSize: 10,
  ///   ),
  /// );
  /// ```
  @override
  final LazyLoadConfig? lazyLoad;

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StoreConfigCopyWith<_StoreConfig> get copyWith =>
      __$StoreConfigCopyWithImpl<_StoreConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StoreConfig &&
            (identical(other.fetchPolicy, fetchPolicy) ||
                other.fetchPolicy == fetchPolicy) &&
            (identical(other.writePolicy, writePolicy) ||
                other.writePolicy == writePolicy) &&
            (identical(other.syncMode, syncMode) ||
                other.syncMode == syncMode) &&
            (identical(other.conflictResolution, conflictResolution) ||
                other.conflictResolution == conflictResolution) &&
            (identical(other.retryConfig, retryConfig) ||
                other.retryConfig == retryConfig) &&
            (identical(other.encryption, encryption) ||
                other.encryption == encryption) &&
            (identical(other.enableAuditLogging, enableAuditLogging) ||
                other.enableAuditLogging == enableAuditLogging) &&
            (identical(other.enableGdpr, enableGdpr) ||
                other.enableGdpr == enableGdpr) &&
            (identical(other.gdpr, gdpr) || other.gdpr == gdpr) &&
            (identical(other.staleDuration, staleDuration) ||
                other.staleDuration == staleDuration) &&
            (identical(other.syncInterval, syncInterval) ||
                other.syncInterval == syncInterval) &&
            (identical(other.tableName, tableName) ||
                other.tableName == tableName) &&
            (identical(other.metricsReporter, metricsReporter) ||
                other.metricsReporter == metricsReporter) &&
            (identical(other.metricsConfig, metricsConfig) ||
                other.metricsConfig == metricsConfig) &&
            (identical(other.transactionTimeout, transactionTimeout) ||
                other.transactionTimeout == transactionTimeout) &&
            (identical(other.deltaSync, deltaSync) ||
                other.deltaSync == deltaSync) &&
            const DeepCollectionEquality()
                .equals(other._interceptors, _interceptors) &&
            (identical(other.lazyLoad, lazyLoad) ||
                other.lazyLoad == lazyLoad));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      fetchPolicy,
      writePolicy,
      syncMode,
      conflictResolution,
      retryConfig,
      encryption,
      enableAuditLogging,
      enableGdpr,
      gdpr,
      staleDuration,
      syncInterval,
      tableName,
      metricsReporter,
      metricsConfig,
      transactionTimeout,
      deltaSync,
      const DeepCollectionEquality().hash(_interceptors),
      lazyLoad);

  @override
  String toString() {
    return 'StoreConfig(fetchPolicy: $fetchPolicy, writePolicy: $writePolicy, syncMode: $syncMode, conflictResolution: $conflictResolution, retryConfig: $retryConfig, encryption: $encryption, enableAuditLogging: $enableAuditLogging, enableGdpr: $enableGdpr, gdpr: $gdpr, staleDuration: $staleDuration, syncInterval: $syncInterval, tableName: $tableName, metricsReporter: $metricsReporter, metricsConfig: $metricsConfig, transactionTimeout: $transactionTimeout, deltaSync: $deltaSync, interceptors: $interceptors, lazyLoad: $lazyLoad)';
  }
}

/// @nodoc
abstract mixin class _$StoreConfigCopyWith<$Res>
    implements $StoreConfigCopyWith<$Res> {
  factory _$StoreConfigCopyWith(
          _StoreConfig value, $Res Function(_StoreConfig) _then) =
      __$StoreConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {FetchPolicy fetchPolicy,
      WritePolicy writePolicy,
      SyncMode syncMode,
      ConflictResolution conflictResolution,
      RetryConfig retryConfig,
      EncryptionConfig encryption,
      bool enableAuditLogging,
      bool enableGdpr,
      GdprConfig? gdpr,
      Duration? staleDuration,
      Duration? syncInterval,
      String? tableName,
      MetricsReporter metricsReporter,
      MetricsConfig metricsConfig,
      Duration transactionTimeout,
      DeltaSyncConfig? deltaSync,
      List<StoreInterceptor> interceptors,
      LazyLoadConfig? lazyLoad});

  @override
  $EncryptionConfigCopyWith<$Res> get encryption;
  @override
  $GdprConfigCopyWith<$Res>? get gdpr;
  @override
  $MetricsConfigCopyWith<$Res> get metricsConfig;
  @override
  $DeltaSyncConfigCopyWith<$Res>? get deltaSync;
  @override
  $LazyLoadConfigCopyWith<$Res>? get lazyLoad;
}

/// @nodoc
class __$StoreConfigCopyWithImpl<$Res> implements _$StoreConfigCopyWith<$Res> {
  __$StoreConfigCopyWithImpl(this._self, this._then);

  final _StoreConfig _self;
  final $Res Function(_StoreConfig) _then;

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fetchPolicy = null,
    Object? writePolicy = null,
    Object? syncMode = null,
    Object? conflictResolution = null,
    Object? retryConfig = null,
    Object? encryption = null,
    Object? enableAuditLogging = null,
    Object? enableGdpr = null,
    Object? gdpr = freezed,
    Object? staleDuration = freezed,
    Object? syncInterval = freezed,
    Object? tableName = freezed,
    Object? metricsReporter = null,
    Object? metricsConfig = null,
    Object? transactionTimeout = null,
    Object? deltaSync = freezed,
    Object? interceptors = null,
    Object? lazyLoad = freezed,
  }) {
    return _then(_StoreConfig(
      fetchPolicy: null == fetchPolicy
          ? _self.fetchPolicy
          : fetchPolicy // ignore: cast_nullable_to_non_nullable
              as FetchPolicy,
      writePolicy: null == writePolicy
          ? _self.writePolicy
          : writePolicy // ignore: cast_nullable_to_non_nullable
              as WritePolicy,
      syncMode: null == syncMode
          ? _self.syncMode
          : syncMode // ignore: cast_nullable_to_non_nullable
              as SyncMode,
      conflictResolution: null == conflictResolution
          ? _self.conflictResolution
          : conflictResolution // ignore: cast_nullable_to_non_nullable
              as ConflictResolution,
      retryConfig: null == retryConfig
          ? _self.retryConfig
          : retryConfig // ignore: cast_nullable_to_non_nullable
              as RetryConfig,
      encryption: null == encryption
          ? _self.encryption
          : encryption // ignore: cast_nullable_to_non_nullable
              as EncryptionConfig,
      enableAuditLogging: null == enableAuditLogging
          ? _self.enableAuditLogging
          : enableAuditLogging // ignore: cast_nullable_to_non_nullable
              as bool,
      enableGdpr: null == enableGdpr
          ? _self.enableGdpr
          : enableGdpr // ignore: cast_nullable_to_non_nullable
              as bool,
      gdpr: freezed == gdpr
          ? _self.gdpr
          : gdpr // ignore: cast_nullable_to_non_nullable
              as GdprConfig?,
      staleDuration: freezed == staleDuration
          ? _self.staleDuration
          : staleDuration // ignore: cast_nullable_to_non_nullable
              as Duration?,
      syncInterval: freezed == syncInterval
          ? _self.syncInterval
          : syncInterval // ignore: cast_nullable_to_non_nullable
              as Duration?,
      tableName: freezed == tableName
          ? _self.tableName
          : tableName // ignore: cast_nullable_to_non_nullable
              as String?,
      metricsReporter: null == metricsReporter
          ? _self.metricsReporter
          : metricsReporter // ignore: cast_nullable_to_non_nullable
              as MetricsReporter,
      metricsConfig: null == metricsConfig
          ? _self.metricsConfig
          : metricsConfig // ignore: cast_nullable_to_non_nullable
              as MetricsConfig,
      transactionTimeout: null == transactionTimeout
          ? _self.transactionTimeout
          : transactionTimeout // ignore: cast_nullable_to_non_nullable
              as Duration,
      deltaSync: freezed == deltaSync
          ? _self.deltaSync
          : deltaSync // ignore: cast_nullable_to_non_nullable
              as DeltaSyncConfig?,
      interceptors: null == interceptors
          ? _self._interceptors
          : interceptors // ignore: cast_nullable_to_non_nullable
              as List<StoreInterceptor>,
      lazyLoad: freezed == lazyLoad
          ? _self.lazyLoad
          : lazyLoad // ignore: cast_nullable_to_non_nullable
              as LazyLoadConfig?,
    ));
  }

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EncryptionConfigCopyWith<$Res> get encryption {
    return $EncryptionConfigCopyWith<$Res>(_self.encryption, (value) {
      return _then(_self.copyWith(encryption: value));
    });
  }

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GdprConfigCopyWith<$Res>? get gdpr {
    if (_self.gdpr == null) {
      return null;
    }

    return $GdprConfigCopyWith<$Res>(_self.gdpr!, (value) {
      return _then(_self.copyWith(gdpr: value));
    });
  }

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MetricsConfigCopyWith<$Res> get metricsConfig {
    return $MetricsConfigCopyWith<$Res>(_self.metricsConfig, (value) {
      return _then(_self.copyWith(metricsConfig: value));
    });
  }

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DeltaSyncConfigCopyWith<$Res>? get deltaSync {
    if (_self.deltaSync == null) {
      return null;
    }

    return $DeltaSyncConfigCopyWith<$Res>(_self.deltaSync!, (value) {
      return _then(_self.copyWith(deltaSync: value));
    });
  }

  /// Create a copy of StoreConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LazyLoadConfigCopyWith<$Res>? get lazyLoad {
    if (_self.lazyLoad == null) {
      return null;
    }

    return $LazyLoadConfigCopyWith<$Res>(_self.lazyLoad!, (value) {
      return _then(_self.copyWith(lazyLoad: value));
    });
  }
}

// dart format on
