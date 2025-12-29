import 'package:freezed_annotation/freezed_annotation.dart';

part 'schema_validation_config.freezed.dart';

/// Mode for handling schema validation errors.
///
/// Controls how the schema validator behaves when validation fails.
enum SchemaValidationMode {
  /// Strict mode throws an exception on validation failure.
  ///
  /// Use for critical data where invalid data should never be stored.
  strict,

  /// Warn mode logs validation failures but allows the operation.
  ///
  /// Use during development or migration when tracking issues without blocking.
  warn,

  /// Silent mode ignores validation failures completely.
  ///
  /// Use when validation is temporarily disabled or for performance.
  silent;

  /// Returns `true` if this is strict mode.
  bool get isStrict => this == strict;

  /// Returns `true` if this is warn mode.
  bool get isWarn => this == warn;

  /// Returns `true` if this is silent mode.
  bool get isSilent => this == silent;

  /// Returns `true` if validation failures should throw exceptions.
  bool get shouldThrow => this == strict;

  /// Returns `true` if validation failures should be logged.
  bool get shouldLog => this != silent;
}

/// Configuration for schema validation behavior.
///
/// Controls when validation occurs, what mode to use, and how to
/// handle validation failures.
///
/// ## Example
///
/// ```dart
/// final config = SchemaValidationConfig(
///   mode: SchemaValidationMode.strict,
///   validateOnSave: true,
///   validateOnRead: false,
/// );
/// ```
@freezed
abstract class SchemaValidationConfig with _$SchemaValidationConfig {
  /// Creates a schema validation configuration.
  const factory SchemaValidationConfig({
    /// Validation mode determining error handling.
    ///
    /// Defaults to [SchemaValidationMode.warn].
    @Default(SchemaValidationMode.warn) SchemaValidationMode mode,

    /// Whether schema validation is enabled.
    ///
    /// When false, all validation is skipped. Defaults to true.
    @Default(true) bool enabled,

    /// Whether to validate entities before saving.
    ///
    /// Defaults to true.
    @Default(true) bool validateOnSave,

    /// Whether to validate entities after reading.
    ///
    /// Defaults to false (for performance).
    @Default(false) bool validateOnRead,
  }) = _SchemaValidationConfig;

  const SchemaValidationConfig._();

  /// Default configuration with warn mode.
  static const SchemaValidationConfig defaults = SchemaValidationConfig();

  /// Strict configuration that throws on validation errors.
  ///
  /// Validates on both save and read operations.
  static const SchemaValidationConfig strict = SchemaValidationConfig(
    mode: SchemaValidationMode.strict,
    validateOnSave: true,
    validateOnRead: true,
  );

  /// Lenient configuration that warns but doesn't throw.
  ///
  /// Only validates on save operations.
  static const SchemaValidationConfig lenient = SchemaValidationConfig(
    mode: SchemaValidationMode.warn,
    validateOnSave: true,
    validateOnRead: false,
  );

  /// Disabled configuration that skips all validation.
  static const SchemaValidationConfig disabled = SchemaValidationConfig(
    enabled: false,
  );
}
