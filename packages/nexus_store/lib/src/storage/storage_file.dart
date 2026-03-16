import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// A file stored in a storage bucket.
@immutable
class StorageFile {
  /// Creates a storage file.
  const StorageFile({
    required this.name,
    required this.bucketId,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.lastAccessedAt,
    this.metadata = const {},
    this.size,
    this.mimeType,
  });

  /// File name including extension.
  final String name;

  /// The bucket this file belongs to.
  final String bucketId;

  /// Unique identifier for this file.
  final String? id;

  /// When this file was created.
  final DateTime? createdAt;

  /// When this file was last updated.
  final DateTime? updatedAt;

  /// When this file was last accessed.
  final DateTime? lastAccessedAt;

  /// Arbitrary metadata associated with this file.
  final Map<String, dynamic> metadata;

  /// File size in bytes.
  final int? size;

  /// MIME type of the file.
  final String? mimeType;

  /// Creates a copy with the specified fields replaced.
  StorageFile copyWith({
    String? name,
    String? bucketId,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    Map<String, dynamic>? metadata,
    int? size,
    String? mimeType,
  }) {
    return StorageFile(
      name: name ?? this.name,
      bucketId: bucketId ?? this.bucketId,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      metadata: metadata ?? this.metadata,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StorageFile) return false;
    return name == other.name &&
        bucketId == other.bucketId &&
        id == other.id &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        lastAccessedAt == other.lastAccessedAt &&
        const MapEquality<String, dynamic>().equals(metadata, other.metadata) &&
        size == other.size &&
        mimeType == other.mimeType;
  }

  @override
  int get hashCode => Object.hash(
        name,
        bucketId,
        id,
        createdAt,
        updatedAt,
        lastAccessedAt,
        const MapEquality<String, dynamic>().hash(metadata),
        size,
        mimeType,
      );

  @override
  String toString() => 'StorageFile('
      'name: $name, '
      'bucketId: $bucketId, '
      'id: $id, '
      'size: $size, '
      'mimeType: $mimeType)';
}
