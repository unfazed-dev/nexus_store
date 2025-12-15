// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_log_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditLogEntry {
  /// Unique identifier for this log entry.
  String get id;

  /// Timestamp when the action occurred.
  DateTime get timestamp;

  /// The action that was performed.
  AuditAction get action;

  /// Type of entity that was accessed/modified.
  String get entityType;

  /// Identifier of the entity.
  String get entityId;

  /// User or service that performed the action.
  String get actorId;

  /// Type of actor (user, service, system).
  ActorType get actorType;

  /// Fields that were accessed or modified.
  List<String> get fields;

  /// Previous values (for updates/deletes).
  Map<String, dynamic>? get previousValues;

  /// New values (for creates/updates).
  Map<String, dynamic>? get newValues;

  /// IP address of the client.
  String? get ipAddress;

  /// User agent string.
  String? get userAgent;

  /// Session identifier.
  String? get sessionId;

  /// Request identifier for correlation.
  String? get requestId;

  /// Whether the operation succeeded.
  bool get success;

  /// Error message if operation failed.
  String? get errorMessage;

  /// Additional metadata.
  Map<String, dynamic> get metadata;

  /// Hash of previous log entry (for chain integrity).
  String? get previousHash;

  /// Hash of this entry (computed after creation).
  String? get hash;

  /// Create a copy of AuditLogEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuditLogEntryCopyWith<AuditLogEntry> get copyWith =>
      _$AuditLogEntryCopyWithImpl<AuditLogEntry>(
          this as AuditLogEntry, _$identity);

  /// Serializes this AuditLogEntry to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuditLogEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.actorId, actorId) || other.actorId == actorId) &&
            (identical(other.actorType, actorType) ||
                other.actorType == actorType) &&
            const DeepCollectionEquality().equals(other.fields, fields) &&
            const DeepCollectionEquality()
                .equals(other.previousValues, previousValues) &&
            const DeepCollectionEquality().equals(other.newValues, newValues) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.userAgent, userAgent) ||
                other.userAgent == userAgent) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality().equals(other.metadata, metadata) &&
            (identical(other.previousHash, previousHash) ||
                other.previousHash == previousHash) &&
            (identical(other.hash, hash) || other.hash == hash));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        timestamp,
        action,
        entityType,
        entityId,
        actorId,
        actorType,
        const DeepCollectionEquality().hash(fields),
        const DeepCollectionEquality().hash(previousValues),
        const DeepCollectionEquality().hash(newValues),
        ipAddress,
        userAgent,
        sessionId,
        requestId,
        success,
        errorMessage,
        const DeepCollectionEquality().hash(metadata),
        previousHash,
        hash
      ]);

  @override
  String toString() {
    return 'AuditLogEntry(id: $id, timestamp: $timestamp, action: $action, entityType: $entityType, entityId: $entityId, actorId: $actorId, actorType: $actorType, fields: $fields, previousValues: $previousValues, newValues: $newValues, ipAddress: $ipAddress, userAgent: $userAgent, sessionId: $sessionId, requestId: $requestId, success: $success, errorMessage: $errorMessage, metadata: $metadata, previousHash: $previousHash, hash: $hash)';
  }
}

/// @nodoc
abstract mixin class $AuditLogEntryCopyWith<$Res> {
  factory $AuditLogEntryCopyWith(
          AuditLogEntry value, $Res Function(AuditLogEntry) _then) =
      _$AuditLogEntryCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      DateTime timestamp,
      AuditAction action,
      String entityType,
      String entityId,
      String actorId,
      ActorType actorType,
      List<String> fields,
      Map<String, dynamic>? previousValues,
      Map<String, dynamic>? newValues,
      String? ipAddress,
      String? userAgent,
      String? sessionId,
      String? requestId,
      bool success,
      String? errorMessage,
      Map<String, dynamic> metadata,
      String? previousHash,
      String? hash});
}

/// @nodoc
class _$AuditLogEntryCopyWithImpl<$Res>
    implements $AuditLogEntryCopyWith<$Res> {
  _$AuditLogEntryCopyWithImpl(this._self, this._then);

  final AuditLogEntry _self;
  final $Res Function(AuditLogEntry) _then;

  /// Create a copy of AuditLogEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? timestamp = null,
    Object? action = null,
    Object? entityType = null,
    Object? entityId = null,
    Object? actorId = null,
    Object? actorType = null,
    Object? fields = null,
    Object? previousValues = freezed,
    Object? newValues = freezed,
    Object? ipAddress = freezed,
    Object? userAgent = freezed,
    Object? sessionId = freezed,
    Object? requestId = freezed,
    Object? success = null,
    Object? errorMessage = freezed,
    Object? metadata = null,
    Object? previousHash = freezed,
    Object? hash = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as AuditAction,
      entityType: null == entityType
          ? _self.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: null == entityId
          ? _self.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      actorId: null == actorId
          ? _self.actorId
          : actorId // ignore: cast_nullable_to_non_nullable
              as String,
      actorType: null == actorType
          ? _self.actorType
          : actorType // ignore: cast_nullable_to_non_nullable
              as ActorType,
      fields: null == fields
          ? _self.fields
          : fields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      previousValues: freezed == previousValues
          ? _self.previousValues
          : previousValues // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      newValues: freezed == newValues
          ? _self.newValues
          : newValues // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      ipAddress: freezed == ipAddress
          ? _self.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      userAgent: freezed == userAgent
          ? _self.userAgent
          : userAgent // ignore: cast_nullable_to_non_nullable
              as String?,
      sessionId: freezed == sessionId
          ? _self.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      requestId: freezed == requestId
          ? _self.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as String?,
      success: null == success
          ? _self.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      previousHash: freezed == previousHash
          ? _self.previousHash
          : previousHash // ignore: cast_nullable_to_non_nullable
              as String?,
      hash: freezed == hash
          ? _self.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [AuditLogEntry].
extension AuditLogEntryPatterns on AuditLogEntry {
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
    TResult Function(_AuditLogEntry value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry() when $default != null:
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
    TResult Function(_AuditLogEntry value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry():
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
    TResult? Function(_AuditLogEntry value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry() when $default != null:
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
            String id,
            DateTime timestamp,
            AuditAction action,
            String entityType,
            String entityId,
            String actorId,
            ActorType actorType,
            List<String> fields,
            Map<String, dynamic>? previousValues,
            Map<String, dynamic>? newValues,
            String? ipAddress,
            String? userAgent,
            String? sessionId,
            String? requestId,
            bool success,
            String? errorMessage,
            Map<String, dynamic> metadata,
            String? previousHash,
            String? hash)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry() when $default != null:
        return $default(
            _that.id,
            _that.timestamp,
            _that.action,
            _that.entityType,
            _that.entityId,
            _that.actorId,
            _that.actorType,
            _that.fields,
            _that.previousValues,
            _that.newValues,
            _that.ipAddress,
            _that.userAgent,
            _that.sessionId,
            _that.requestId,
            _that.success,
            _that.errorMessage,
            _that.metadata,
            _that.previousHash,
            _that.hash);
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
            String id,
            DateTime timestamp,
            AuditAction action,
            String entityType,
            String entityId,
            String actorId,
            ActorType actorType,
            List<String> fields,
            Map<String, dynamic>? previousValues,
            Map<String, dynamic>? newValues,
            String? ipAddress,
            String? userAgent,
            String? sessionId,
            String? requestId,
            bool success,
            String? errorMessage,
            Map<String, dynamic> metadata,
            String? previousHash,
            String? hash)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry():
        return $default(
            _that.id,
            _that.timestamp,
            _that.action,
            _that.entityType,
            _that.entityId,
            _that.actorId,
            _that.actorType,
            _that.fields,
            _that.previousValues,
            _that.newValues,
            _that.ipAddress,
            _that.userAgent,
            _that.sessionId,
            _that.requestId,
            _that.success,
            _that.errorMessage,
            _that.metadata,
            _that.previousHash,
            _that.hash);
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
            String id,
            DateTime timestamp,
            AuditAction action,
            String entityType,
            String entityId,
            String actorId,
            ActorType actorType,
            List<String> fields,
            Map<String, dynamic>? previousValues,
            Map<String, dynamic>? newValues,
            String? ipAddress,
            String? userAgent,
            String? sessionId,
            String? requestId,
            bool success,
            String? errorMessage,
            Map<String, dynamic> metadata,
            String? previousHash,
            String? hash)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry() when $default != null:
        return $default(
            _that.id,
            _that.timestamp,
            _that.action,
            _that.entityType,
            _that.entityId,
            _that.actorId,
            _that.actorType,
            _that.fields,
            _that.previousValues,
            _that.newValues,
            _that.ipAddress,
            _that.userAgent,
            _that.sessionId,
            _that.requestId,
            _that.success,
            _that.errorMessage,
            _that.metadata,
            _that.previousHash,
            _that.hash);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AuditLogEntry extends AuditLogEntry {
  const _AuditLogEntry(
      {required this.id,
      required this.timestamp,
      required this.action,
      required this.entityType,
      required this.entityId,
      required this.actorId,
      this.actorType = ActorType.user,
      final List<String> fields = const [],
      final Map<String, dynamic>? previousValues,
      final Map<String, dynamic>? newValues,
      this.ipAddress,
      this.userAgent,
      this.sessionId,
      this.requestId,
      this.success = true,
      this.errorMessage,
      final Map<String, dynamic> metadata = const {},
      this.previousHash,
      this.hash})
      : _fields = fields,
        _previousValues = previousValues,
        _newValues = newValues,
        _metadata = metadata,
        super._();
  factory _AuditLogEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditLogEntryFromJson(json);

  /// Unique identifier for this log entry.
  @override
  final String id;

  /// Timestamp when the action occurred.
  @override
  final DateTime timestamp;

  /// The action that was performed.
  @override
  final AuditAction action;

  /// Type of entity that was accessed/modified.
  @override
  final String entityType;

  /// Identifier of the entity.
  @override
  final String entityId;

  /// User or service that performed the action.
  @override
  final String actorId;

  /// Type of actor (user, service, system).
  @override
  @JsonKey()
  final ActorType actorType;

  /// Fields that were accessed or modified.
  final List<String> _fields;

  /// Fields that were accessed or modified.
  @override
  @JsonKey()
  List<String> get fields {
    if (_fields is EqualUnmodifiableListView) return _fields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fields);
  }

  /// Previous values (for updates/deletes).
  final Map<String, dynamic>? _previousValues;

  /// Previous values (for updates/deletes).
  @override
  Map<String, dynamic>? get previousValues {
    final value = _previousValues;
    if (value == null) return null;
    if (_previousValues is EqualUnmodifiableMapView) return _previousValues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// New values (for creates/updates).
  final Map<String, dynamic>? _newValues;

  /// New values (for creates/updates).
  @override
  Map<String, dynamic>? get newValues {
    final value = _newValues;
    if (value == null) return null;
    if (_newValues is EqualUnmodifiableMapView) return _newValues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// IP address of the client.
  @override
  final String? ipAddress;

  /// User agent string.
  @override
  final String? userAgent;

  /// Session identifier.
  @override
  final String? sessionId;

  /// Request identifier for correlation.
  @override
  final String? requestId;

  /// Whether the operation succeeded.
  @override
  @JsonKey()
  final bool success;

  /// Error message if operation failed.
  @override
  final String? errorMessage;

  /// Additional metadata.
  final Map<String, dynamic> _metadata;

  /// Additional metadata.
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// Hash of previous log entry (for chain integrity).
  @override
  final String? previousHash;

  /// Hash of this entry (computed after creation).
  @override
  final String? hash;

  /// Create a copy of AuditLogEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AuditLogEntryCopyWith<_AuditLogEntry> get copyWith =>
      __$AuditLogEntryCopyWithImpl<_AuditLogEntry>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AuditLogEntryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AuditLogEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.actorId, actorId) || other.actorId == actorId) &&
            (identical(other.actorType, actorType) ||
                other.actorType == actorType) &&
            const DeepCollectionEquality().equals(other._fields, _fields) &&
            const DeepCollectionEquality()
                .equals(other._previousValues, _previousValues) &&
            const DeepCollectionEquality()
                .equals(other._newValues, _newValues) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.userAgent, userAgent) ||
                other.userAgent == userAgent) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.previousHash, previousHash) ||
                other.previousHash == previousHash) &&
            (identical(other.hash, hash) || other.hash == hash));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        timestamp,
        action,
        entityType,
        entityId,
        actorId,
        actorType,
        const DeepCollectionEquality().hash(_fields),
        const DeepCollectionEquality().hash(_previousValues),
        const DeepCollectionEquality().hash(_newValues),
        ipAddress,
        userAgent,
        sessionId,
        requestId,
        success,
        errorMessage,
        const DeepCollectionEquality().hash(_metadata),
        previousHash,
        hash
      ]);

  @override
  String toString() {
    return 'AuditLogEntry(id: $id, timestamp: $timestamp, action: $action, entityType: $entityType, entityId: $entityId, actorId: $actorId, actorType: $actorType, fields: $fields, previousValues: $previousValues, newValues: $newValues, ipAddress: $ipAddress, userAgent: $userAgent, sessionId: $sessionId, requestId: $requestId, success: $success, errorMessage: $errorMessage, metadata: $metadata, previousHash: $previousHash, hash: $hash)';
  }
}

/// @nodoc
abstract mixin class _$AuditLogEntryCopyWith<$Res>
    implements $AuditLogEntryCopyWith<$Res> {
  factory _$AuditLogEntryCopyWith(
          _AuditLogEntry value, $Res Function(_AuditLogEntry) _then) =
      __$AuditLogEntryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime timestamp,
      AuditAction action,
      String entityType,
      String entityId,
      String actorId,
      ActorType actorType,
      List<String> fields,
      Map<String, dynamic>? previousValues,
      Map<String, dynamic>? newValues,
      String? ipAddress,
      String? userAgent,
      String? sessionId,
      String? requestId,
      bool success,
      String? errorMessage,
      Map<String, dynamic> metadata,
      String? previousHash,
      String? hash});
}

/// @nodoc
class __$AuditLogEntryCopyWithImpl<$Res>
    implements _$AuditLogEntryCopyWith<$Res> {
  __$AuditLogEntryCopyWithImpl(this._self, this._then);

  final _AuditLogEntry _self;
  final $Res Function(_AuditLogEntry) _then;

  /// Create a copy of AuditLogEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? timestamp = null,
    Object? action = null,
    Object? entityType = null,
    Object? entityId = null,
    Object? actorId = null,
    Object? actorType = null,
    Object? fields = null,
    Object? previousValues = freezed,
    Object? newValues = freezed,
    Object? ipAddress = freezed,
    Object? userAgent = freezed,
    Object? sessionId = freezed,
    Object? requestId = freezed,
    Object? success = null,
    Object? errorMessage = freezed,
    Object? metadata = null,
    Object? previousHash = freezed,
    Object? hash = freezed,
  }) {
    return _then(_AuditLogEntry(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as AuditAction,
      entityType: null == entityType
          ? _self.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: null == entityId
          ? _self.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      actorId: null == actorId
          ? _self.actorId
          : actorId // ignore: cast_nullable_to_non_nullable
              as String,
      actorType: null == actorType
          ? _self.actorType
          : actorType // ignore: cast_nullable_to_non_nullable
              as ActorType,
      fields: null == fields
          ? _self._fields
          : fields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      previousValues: freezed == previousValues
          ? _self._previousValues
          : previousValues // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      newValues: freezed == newValues
          ? _self._newValues
          : newValues // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      ipAddress: freezed == ipAddress
          ? _self.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      userAgent: freezed == userAgent
          ? _self.userAgent
          : userAgent // ignore: cast_nullable_to_non_nullable
              as String?,
      sessionId: freezed == sessionId
          ? _self.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      requestId: freezed == requestId
          ? _self.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as String?,
      success: null == success
          ? _self.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      previousHash: freezed == previousHash
          ? _self.previousHash
          : previousHash // ignore: cast_nullable_to_non_nullable
              as String?,
      hash: freezed == hash
          ? _self.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
