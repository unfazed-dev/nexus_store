import 'package:meta/meta.dart';

/// A signed URL for temporary access to a storage file.
@immutable
class SignedUrl {
  /// Creates a signed URL result.
  const SignedUrl({
    required this.path,
    required this.signedUrl,
    this.error,
  });

  /// The file path this URL corresponds to.
  final String path;

  /// The generated signed URL.
  final String signedUrl;

  /// Error message if URL generation failed for this path.
  final String? error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SignedUrl) return false;
    return path == other.path &&
        signedUrl == other.signedUrl &&
        error == other.error;
  }

  @override
  int get hashCode => Object.hash(path, signedUrl, error);

  @override
  String toString() => 'SignedUrl('
      'path: $path, '
      'signedUrl: $signedUrl, '
      'error: $error)';
}
