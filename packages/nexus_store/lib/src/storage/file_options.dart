import 'package:meta/meta.dart';

/// Options for uploading or updating a file.
@immutable
class FileOptions {
  /// Creates file options with sensible defaults.
  const FileOptions({
    this.contentType = 'application/octet-stream',
    this.cacheControl = '3600',
    this.upsert = false,
  });

  /// MIME type of the file.
  final String contentType;

  /// Cache-Control header value in seconds.
  final String cacheControl;

  /// Whether to overwrite existing files at the same path.
  final bool upsert;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FileOptions) return false;
    return contentType == other.contentType &&
        cacheControl == other.cacheControl &&
        upsert == other.upsert;
  }

  @override
  int get hashCode => Object.hash(contentType, cacheControl, upsert);

  @override
  String toString() => 'FileOptions('
      'contentType: $contentType, '
      'cacheControl: $cacheControl, '
      'upsert: $upsert)';
}
