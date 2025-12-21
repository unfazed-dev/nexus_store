import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// An opaque cursor for cursor-based pagination.
///
/// Cursors encode the position within a paginated result set, allowing
/// efficient navigation without offset-based pagination.
///
/// ## Example
///
/// ```dart
/// // Create cursor from field values
/// final cursor = Cursor.fromValues({
///   'id': 'user-123',
///   'createdAt': '2024-01-15T10:30:00Z',
/// });
///
/// // Encode for transmission
/// final encoded = cursor.encode(); // 'eyJpZCI6InVzZXItMTIzIi4uLn0='
///
/// // Decode from encoded string
/// final decoded = Cursor.decode(encoded);
/// print(decoded.toValues()); // {'id': 'user-123', ...}
/// ```
@immutable
class Cursor {
  /// Creates a cursor from a map of field values.
  ///
  /// The values should be JSON-serializable types (String, num, bool, null).
  Cursor.fromValues(Map<String, Object?> values)
      : _values = Map<String, Object?>.unmodifiable(
          Map<String, Object?>.from(values),
        );

  const Cursor._(this._values);

  final Map<String, Object?> _values;

  /// Encodes this cursor to a base64 string.
  ///
  /// The encoded string is opaque and should not be parsed by clients.
  String encode() {
    final json = jsonEncode(_values);
    return base64Encode(utf8.encode(json));
  }

  /// Decodes a base64 encoded cursor string.
  ///
  /// Throws [InvalidCursorException] if the string is invalid.
  static Cursor decode(String encoded) {
    if (encoded.isEmpty) {
      throw InvalidCursorException('Cursor string cannot be empty');
    }

    try {
      final bytes = base64Decode(encoded);
      final json = utf8.decode(bytes);
      final decoded = jsonDecode(json);

      if (decoded is! Map<String, dynamic>) {
        throw InvalidCursorException(
          'Invalid cursor format: expected JSON object',
        );
      }

      return Cursor._(Map<String, Object?>.unmodifiable(decoded));
    } on FormatException catch (e) {
      throw InvalidCursorException('Invalid cursor encoding: ${e.message}');
    }
  }

  /// Returns the field values encoded in this cursor.
  Map<String, Object?> toValues() => _values;

  /// Returns `true` if this cursor has no values.
  bool get isEmpty => _values.isEmpty;

  /// Returns `true` if this cursor has values.
  bool get isNotEmpty => _values.isNotEmpty;

  /// Creates a copy of this cursor with updated values.
  ///
  /// The [updates] map is merged with existing values, with updates
  /// taking precedence.
  Cursor copyWith(Map<String, Object?> updates) {
    return Cursor.fromValues({..._values, ...updates});
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Cursor) return false;
    return const MapEquality<String, Object?>().equals(_values, other._values);
  }

  @override
  int get hashCode => const MapEquality<String, Object?>().hash(_values);

  @override
  String toString() => 'Cursor($_values)';
}

/// Exception thrown when a cursor string is invalid.
class InvalidCursorException implements Exception {
  /// Creates an invalid cursor exception with the given message.
  const InvalidCursorException(this.message);

  /// A description of the error.
  final String message;

  @override
  String toString() => 'InvalidCursorException: $message';
}
