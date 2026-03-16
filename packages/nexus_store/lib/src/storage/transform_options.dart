import 'package:meta/meta.dart';

/// Image transformation options for download or public URL generation.
@immutable
class TransformOptions {
  /// Creates transform options.
  const TransformOptions({
    this.width,
    this.height,
    this.quality,
    this.format,
    this.resize,
  });

  /// Target width in pixels.
  final int? width;

  /// Target height in pixels.
  final int? height;

  /// Image quality (1-100).
  final int? quality;

  /// Output image format.
  final ImageFormat? format;

  /// Resize mode.
  final ResizeMode? resize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransformOptions) return false;
    return width == other.width &&
        height == other.height &&
        quality == other.quality &&
        format == other.format &&
        resize == other.resize;
  }

  @override
  int get hashCode => Object.hash(width, height, quality, format, resize);

  @override
  String toString() => 'TransformOptions('
      'width: $width, '
      'height: $height, '
      'quality: $quality, '
      'format: $format, '
      'resize: $resize)';
}

/// Image output format.
enum ImageFormat {
  /// Original format (no conversion).
  origin,

  /// AVIF format.
  avif,

  /// WebP format.
  webp,
}

/// Resize mode for image transformations.
enum ResizeMode {
  /// Resize to cover the target dimensions, cropping if necessary.
  cover,

  /// Resize to fit within the target dimensions.
  contain,

  /// Stretch to fill the target dimensions exactly.
  fill,
}
