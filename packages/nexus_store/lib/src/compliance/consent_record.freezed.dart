// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consent_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConsentStatus {
  /// Whether consent is currently granted.
  bool get granted;

  /// When consent was granted.
  DateTime? get grantedAt;

  /// When consent was withdrawn.
  DateTime? get withdrawnAt;

  /// Source of the consent (e.g., 'signup-form', 'settings-page').
  String? get source;

  /// Create a copy of ConsentStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ConsentStatusCopyWith<ConsentStatus> get copyWith =>
      _$ConsentStatusCopyWithImpl<ConsentStatus>(
          this as ConsentStatus, _$identity);

  /// Serializes this ConsentStatus to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ConsentStatus &&
            (identical(other.granted, granted) || other.granted == granted) &&
            (identical(other.grantedAt, grantedAt) ||
                other.grantedAt == grantedAt) &&
            (identical(other.withdrawnAt, withdrawnAt) ||
                other.withdrawnAt == withdrawnAt) &&
            (identical(other.source, source) || other.source == source));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, granted, grantedAt, withdrawnAt, source);

  @override
  String toString() {
    return 'ConsentStatus(granted: $granted, grantedAt: $grantedAt, withdrawnAt: $withdrawnAt, source: $source)';
  }
}

/// @nodoc
abstract mixin class $ConsentStatusCopyWith<$Res> {
  factory $ConsentStatusCopyWith(
          ConsentStatus value, $Res Function(ConsentStatus) _then) =
      _$ConsentStatusCopyWithImpl;
  @useResult
  $Res call(
      {bool granted,
      DateTime? grantedAt,
      DateTime? withdrawnAt,
      String? source});
}

/// @nodoc
class _$ConsentStatusCopyWithImpl<$Res>
    implements $ConsentStatusCopyWith<$Res> {
  _$ConsentStatusCopyWithImpl(this._self, this._then);

  final ConsentStatus _self;
  final $Res Function(ConsentStatus) _then;

  /// Create a copy of ConsentStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? granted = null,
    Object? grantedAt = freezed,
    Object? withdrawnAt = freezed,
    Object? source = freezed,
  }) {
    return _then(_self.copyWith(
      granted: null == granted
          ? _self.granted
          : granted // ignore: cast_nullable_to_non_nullable
              as bool,
      grantedAt: freezed == grantedAt
          ? _self.grantedAt
          : grantedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      withdrawnAt: freezed == withdrawnAt
          ? _self.withdrawnAt
          : withdrawnAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      source: freezed == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ConsentStatus].
extension ConsentStatusPatterns on ConsentStatus {
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
    TResult Function(_ConsentStatus value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConsentStatus() when $default != null:
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
    TResult Function(_ConsentStatus value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentStatus():
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
    TResult? Function(_ConsentStatus value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentStatus() when $default != null:
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
    TResult Function(bool granted, DateTime? grantedAt, DateTime? withdrawnAt,
            String? source)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConsentStatus() when $default != null:
        return $default(
            _that.granted, _that.grantedAt, _that.withdrawnAt, _that.source);
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
    TResult Function(bool granted, DateTime? grantedAt, DateTime? withdrawnAt,
            String? source)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentStatus():
        return $default(
            _that.granted, _that.grantedAt, _that.withdrawnAt, _that.source);
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
    TResult? Function(bool granted, DateTime? grantedAt, DateTime? withdrawnAt,
            String? source)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentStatus() when $default != null:
        return $default(
            _that.granted, _that.grantedAt, _that.withdrawnAt, _that.source);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ConsentStatus extends ConsentStatus {
  const _ConsentStatus(
      {required this.granted, this.grantedAt, this.withdrawnAt, this.source})
      : super._();
  factory _ConsentStatus.fromJson(Map<String, dynamic> json) =>
      _$ConsentStatusFromJson(json);

  /// Whether consent is currently granted.
  @override
  final bool granted;

  /// When consent was granted.
  @override
  final DateTime? grantedAt;

  /// When consent was withdrawn.
  @override
  final DateTime? withdrawnAt;

  /// Source of the consent (e.g., 'signup-form', 'settings-page').
  @override
  final String? source;

  /// Create a copy of ConsentStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ConsentStatusCopyWith<_ConsentStatus> get copyWith =>
      __$ConsentStatusCopyWithImpl<_ConsentStatus>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ConsentStatusToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ConsentStatus &&
            (identical(other.granted, granted) || other.granted == granted) &&
            (identical(other.grantedAt, grantedAt) ||
                other.grantedAt == grantedAt) &&
            (identical(other.withdrawnAt, withdrawnAt) ||
                other.withdrawnAt == withdrawnAt) &&
            (identical(other.source, source) || other.source == source));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, granted, grantedAt, withdrawnAt, source);

  @override
  String toString() {
    return 'ConsentStatus(granted: $granted, grantedAt: $grantedAt, withdrawnAt: $withdrawnAt, source: $source)';
  }
}

/// @nodoc
abstract mixin class _$ConsentStatusCopyWith<$Res>
    implements $ConsentStatusCopyWith<$Res> {
  factory _$ConsentStatusCopyWith(
          _ConsentStatus value, $Res Function(_ConsentStatus) _then) =
      __$ConsentStatusCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool granted,
      DateTime? grantedAt,
      DateTime? withdrawnAt,
      String? source});
}

/// @nodoc
class __$ConsentStatusCopyWithImpl<$Res>
    implements _$ConsentStatusCopyWith<$Res> {
  __$ConsentStatusCopyWithImpl(this._self, this._then);

  final _ConsentStatus _self;
  final $Res Function(_ConsentStatus) _then;

  /// Create a copy of ConsentStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? granted = null,
    Object? grantedAt = freezed,
    Object? withdrawnAt = freezed,
    Object? source = freezed,
  }) {
    return _then(_ConsentStatus(
      granted: null == granted
          ? _self.granted
          : granted // ignore: cast_nullable_to_non_nullable
              as bool,
      grantedAt: freezed == grantedAt
          ? _self.grantedAt
          : grantedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      withdrawnAt: freezed == withdrawnAt
          ? _self.withdrawnAt
          : withdrawnAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      source: freezed == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$ConsentEvent {
  /// The purpose this event relates to.
  String get purpose;

  /// The action taken (granted or withdrawn).
  ConsentAction get action;

  /// When this event occurred.
  DateTime get timestamp;

  /// Source of the consent action.
  String? get source;

  /// IP address of the user when action was taken.
  String? get ipAddress;

  /// Create a copy of ConsentEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ConsentEventCopyWith<ConsentEvent> get copyWith =>
      _$ConsentEventCopyWithImpl<ConsentEvent>(
          this as ConsentEvent, _$identity);

  /// Serializes this ConsentEvent to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ConsentEvent &&
            (identical(other.purpose, purpose) || other.purpose == purpose) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, purpose, action, timestamp, source, ipAddress);

  @override
  String toString() {
    return 'ConsentEvent(purpose: $purpose, action: $action, timestamp: $timestamp, source: $source, ipAddress: $ipAddress)';
  }
}

/// @nodoc
abstract mixin class $ConsentEventCopyWith<$Res> {
  factory $ConsentEventCopyWith(
          ConsentEvent value, $Res Function(ConsentEvent) _then) =
      _$ConsentEventCopyWithImpl;
  @useResult
  $Res call(
      {String purpose,
      ConsentAction action,
      DateTime timestamp,
      String? source,
      String? ipAddress});
}

/// @nodoc
class _$ConsentEventCopyWithImpl<$Res> implements $ConsentEventCopyWith<$Res> {
  _$ConsentEventCopyWithImpl(this._self, this._then);

  final ConsentEvent _self;
  final $Res Function(ConsentEvent) _then;

  /// Create a copy of ConsentEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? purpose = null,
    Object? action = null,
    Object? timestamp = null,
    Object? source = freezed,
    Object? ipAddress = freezed,
  }) {
    return _then(_self.copyWith(
      purpose: null == purpose
          ? _self.purpose
          : purpose // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as ConsentAction,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      source: freezed == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      ipAddress: freezed == ipAddress
          ? _self.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ConsentEvent].
extension ConsentEventPatterns on ConsentEvent {
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
    TResult Function(_ConsentEvent value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConsentEvent() when $default != null:
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
    TResult Function(_ConsentEvent value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentEvent():
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
    TResult? Function(_ConsentEvent value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentEvent() when $default != null:
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
    TResult Function(String purpose, ConsentAction action, DateTime timestamp,
            String? source, String? ipAddress)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConsentEvent() when $default != null:
        return $default(_that.purpose, _that.action, _that.timestamp,
            _that.source, _that.ipAddress);
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
    TResult Function(String purpose, ConsentAction action, DateTime timestamp,
            String? source, String? ipAddress)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentEvent():
        return $default(_that.purpose, _that.action, _that.timestamp,
            _that.source, _that.ipAddress);
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
    TResult? Function(String purpose, ConsentAction action, DateTime timestamp,
            String? source, String? ipAddress)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentEvent() when $default != null:
        return $default(_that.purpose, _that.action, _that.timestamp,
            _that.source, _that.ipAddress);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ConsentEvent extends ConsentEvent {
  const _ConsentEvent(
      {required this.purpose,
      required this.action,
      required this.timestamp,
      this.source,
      this.ipAddress})
      : super._();
  factory _ConsentEvent.fromJson(Map<String, dynamic> json) =>
      _$ConsentEventFromJson(json);

  /// The purpose this event relates to.
  @override
  final String purpose;

  /// The action taken (granted or withdrawn).
  @override
  final ConsentAction action;

  /// When this event occurred.
  @override
  final DateTime timestamp;

  /// Source of the consent action.
  @override
  final String? source;

  /// IP address of the user when action was taken.
  @override
  final String? ipAddress;

  /// Create a copy of ConsentEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ConsentEventCopyWith<_ConsentEvent> get copyWith =>
      __$ConsentEventCopyWithImpl<_ConsentEvent>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ConsentEventToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ConsentEvent &&
            (identical(other.purpose, purpose) || other.purpose == purpose) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, purpose, action, timestamp, source, ipAddress);

  @override
  String toString() {
    return 'ConsentEvent(purpose: $purpose, action: $action, timestamp: $timestamp, source: $source, ipAddress: $ipAddress)';
  }
}

/// @nodoc
abstract mixin class _$ConsentEventCopyWith<$Res>
    implements $ConsentEventCopyWith<$Res> {
  factory _$ConsentEventCopyWith(
          _ConsentEvent value, $Res Function(_ConsentEvent) _then) =
      __$ConsentEventCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String purpose,
      ConsentAction action,
      DateTime timestamp,
      String? source,
      String? ipAddress});
}

/// @nodoc
class __$ConsentEventCopyWithImpl<$Res>
    implements _$ConsentEventCopyWith<$Res> {
  __$ConsentEventCopyWithImpl(this._self, this._then);

  final _ConsentEvent _self;
  final $Res Function(_ConsentEvent) _then;

  /// Create a copy of ConsentEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? purpose = null,
    Object? action = null,
    Object? timestamp = null,
    Object? source = freezed,
    Object? ipAddress = freezed,
  }) {
    return _then(_ConsentEvent(
      purpose: null == purpose
          ? _self.purpose
          : purpose // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as ConsentAction,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      source: freezed == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      ipAddress: freezed == ipAddress
          ? _self.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$ConsentRecord {
  /// Unique identifier for the data subject.
  String get userId;

  /// Map of purpose to current consent status.
  Map<String, ConsentStatus> get purposes;

  /// Full history of all consent events.
  List<ConsentEvent> get history;

  /// When this record was last updated.
  DateTime get lastUpdated;

  /// Create a copy of ConsentRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ConsentRecordCopyWith<ConsentRecord> get copyWith =>
      _$ConsentRecordCopyWithImpl<ConsentRecord>(
          this as ConsentRecord, _$identity);

  /// Serializes this ConsentRecord to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ConsentRecord &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(other.purposes, purposes) &&
            const DeepCollectionEquality().equals(other.history, history) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      const DeepCollectionEquality().hash(purposes),
      const DeepCollectionEquality().hash(history),
      lastUpdated);

  @override
  String toString() {
    return 'ConsentRecord(userId: $userId, purposes: $purposes, history: $history, lastUpdated: $lastUpdated)';
  }
}

/// @nodoc
abstract mixin class $ConsentRecordCopyWith<$Res> {
  factory $ConsentRecordCopyWith(
          ConsentRecord value, $Res Function(ConsentRecord) _then) =
      _$ConsentRecordCopyWithImpl;
  @useResult
  $Res call(
      {String userId,
      Map<String, ConsentStatus> purposes,
      List<ConsentEvent> history,
      DateTime lastUpdated});
}

/// @nodoc
class _$ConsentRecordCopyWithImpl<$Res>
    implements $ConsentRecordCopyWith<$Res> {
  _$ConsentRecordCopyWithImpl(this._self, this._then);

  final ConsentRecord _self;
  final $Res Function(ConsentRecord) _then;

  /// Create a copy of ConsentRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? purposes = null,
    Object? history = null,
    Object? lastUpdated = null,
  }) {
    return _then(_self.copyWith(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      purposes: null == purposes
          ? _self.purposes
          : purposes // ignore: cast_nullable_to_non_nullable
              as Map<String, ConsentStatus>,
      history: null == history
          ? _self.history
          : history // ignore: cast_nullable_to_non_nullable
              as List<ConsentEvent>,
      lastUpdated: null == lastUpdated
          ? _self.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [ConsentRecord].
extension ConsentRecordPatterns on ConsentRecord {
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
    TResult Function(_ConsentRecord value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConsentRecord() when $default != null:
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
    TResult Function(_ConsentRecord value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentRecord():
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
    TResult? Function(_ConsentRecord value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentRecord() when $default != null:
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
    TResult Function(String userId, Map<String, ConsentStatus> purposes,
            List<ConsentEvent> history, DateTime lastUpdated)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConsentRecord() when $default != null:
        return $default(
            _that.userId, _that.purposes, _that.history, _that.lastUpdated);
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
    TResult Function(String userId, Map<String, ConsentStatus> purposes,
            List<ConsentEvent> history, DateTime lastUpdated)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentRecord():
        return $default(
            _that.userId, _that.purposes, _that.history, _that.lastUpdated);
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
    TResult? Function(String userId, Map<String, ConsentStatus> purposes,
            List<ConsentEvent> history, DateTime lastUpdated)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConsentRecord() when $default != null:
        return $default(
            _that.userId, _that.purposes, _that.history, _that.lastUpdated);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ConsentRecord extends ConsentRecord {
  const _ConsentRecord(
      {required this.userId,
      required final Map<String, ConsentStatus> purposes,
      required final List<ConsentEvent> history,
      required this.lastUpdated})
      : _purposes = purposes,
        _history = history,
        super._();
  factory _ConsentRecord.fromJson(Map<String, dynamic> json) =>
      _$ConsentRecordFromJson(json);

  /// Unique identifier for the data subject.
  @override
  final String userId;

  /// Map of purpose to current consent status.
  final Map<String, ConsentStatus> _purposes;

  /// Map of purpose to current consent status.
  @override
  Map<String, ConsentStatus> get purposes {
    if (_purposes is EqualUnmodifiableMapView) return _purposes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_purposes);
  }

  /// Full history of all consent events.
  final List<ConsentEvent> _history;

  /// Full history of all consent events.
  @override
  List<ConsentEvent> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  /// When this record was last updated.
  @override
  final DateTime lastUpdated;

  /// Create a copy of ConsentRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ConsentRecordCopyWith<_ConsentRecord> get copyWith =>
      __$ConsentRecordCopyWithImpl<_ConsentRecord>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ConsentRecordToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ConsentRecord &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(other._purposes, _purposes) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      const DeepCollectionEquality().hash(_purposes),
      const DeepCollectionEquality().hash(_history),
      lastUpdated);

  @override
  String toString() {
    return 'ConsentRecord(userId: $userId, purposes: $purposes, history: $history, lastUpdated: $lastUpdated)';
  }
}

/// @nodoc
abstract mixin class _$ConsentRecordCopyWith<$Res>
    implements $ConsentRecordCopyWith<$Res> {
  factory _$ConsentRecordCopyWith(
          _ConsentRecord value, $Res Function(_ConsentRecord) _then) =
      __$ConsentRecordCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String userId,
      Map<String, ConsentStatus> purposes,
      List<ConsentEvent> history,
      DateTime lastUpdated});
}

/// @nodoc
class __$ConsentRecordCopyWithImpl<$Res>
    implements _$ConsentRecordCopyWith<$Res> {
  __$ConsentRecordCopyWithImpl(this._self, this._then);

  final _ConsentRecord _self;
  final $Res Function(_ConsentRecord) _then;

  /// Create a copy of ConsentRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? userId = null,
    Object? purposes = null,
    Object? history = null,
    Object? lastUpdated = null,
  }) {
    return _then(_ConsentRecord(
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      purposes: null == purposes
          ? _self._purposes
          : purposes // ignore: cast_nullable_to_non_nullable
              as Map<String, ConsentStatus>,
      history: null == history
          ? _self._history
          : history // ignore: cast_nullable_to_non_nullable
              as List<ConsentEvent>,
      lastUpdated: null == lastUpdated
          ? _self.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
