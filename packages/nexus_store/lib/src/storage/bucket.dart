import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// A storage bucket that contains files.
@immutable
class Bucket {
  /// Creates a bucket.
  const Bucket({
    required this.id,
    required this.name,
    required this.public,
    required this.createdAt,
    required this.updatedAt,
    this.fileSizeLimit,
    this.allowedMimeTypes = const [],
  });

  /// Unique identifier for this bucket.
  final String id;

  /// Display name of this bucket.
  final String name;

  /// Whether this bucket allows public access.
  final bool public;

  /// When this bucket was created.
  final DateTime createdAt;

  /// When this bucket was last updated.
  final DateTime updatedAt;

  /// Maximum file size in bytes, or null for no limit.
  final int? fileSizeLimit;

  /// Allowed MIME types, or empty for all types.
  final List<String> allowedMimeTypes;

  /// Creates a copy with the specified fields replaced.
  Bucket copyWith({
    String? id,
    String? name,
    bool? public,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? fileSizeLimit,
    List<String>? allowedMimeTypes,
  }) {
    return Bucket(
      id: id ?? this.id,
      name: name ?? this.name,
      public: public ?? this.public,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileSizeLimit: fileSizeLimit ?? this.fileSizeLimit,
      allowedMimeTypes: allowedMimeTypes ?? this.allowedMimeTypes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Bucket) return false;
    return id == other.id &&
        name == other.name &&
        public == other.public &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        fileSizeLimit == other.fileSizeLimit &&
        const ListEquality<String>()
            .equals(allowedMimeTypes, other.allowedMimeTypes);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        public,
        createdAt,
        updatedAt,
        fileSizeLimit,
        const ListEquality<String>().hash(allowedMimeTypes),
      );

  @override
  String toString() => 'Bucket('
      'id: $id, '
      'name: $name, '
      'public: $public, '
      'createdAt: $createdAt, '
      'updatedAt: $updatedAt, '
      'fileSizeLimit: $fileSizeLimit, '
      'allowedMimeTypes: $allowedMimeTypes)';
}

/// Options for creating or updating a bucket.
@immutable
class BucketOptions {
  /// Creates bucket options.
  const BucketOptions({
    this.public = false,
    this.fileSizeLimit,
    this.allowedMimeTypes = const [],
  });

  /// Whether the bucket allows public access.
  final bool public;

  /// Maximum file size in bytes, or null for no limit.
  final int? fileSizeLimit;

  /// Allowed MIME types, or empty for all types.
  final List<String> allowedMimeTypes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BucketOptions) return false;
    return public == other.public &&
        fileSizeLimit == other.fileSizeLimit &&
        const ListEquality<String>()
            .equals(allowedMimeTypes, other.allowedMimeTypes);
  }

  @override
  int get hashCode => Object.hash(
        public,
        fileSizeLimit,
        const ListEquality<String>().hash(allowedMimeTypes),
      );

  @override
  String toString() => 'BucketOptions('
      'public: $public, '
      'fileSizeLimit: $fileSizeLimit, '
      'allowedMimeTypes: $allowedMimeTypes)';
}
