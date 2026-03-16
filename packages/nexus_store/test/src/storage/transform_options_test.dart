import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('TransformOptions', () {
    test('constructs with no fields', () {
      const options = TransformOptions();

      expect(options.width, isNull);
      expect(options.height, isNull);
      expect(options.quality, isNull);
      expect(options.format, isNull);
      expect(options.resize, isNull);
    });

    test('constructs with all fields', () {
      const options = TransformOptions(
        width: 200,
        height: 150,
        quality: 80,
        format: ImageFormat.webp,
        resize: ResizeMode.cover,
      );

      expect(options.width, 200);
      expect(options.height, 150);
      expect(options.quality, 80);
      expect(options.format, ImageFormat.webp);
      expect(options.resize, ResizeMode.cover);
    });

    test('equality compares all fields', () {
      const a = TransformOptions(width: 100, height: 100);
      const b = TransformOptions(width: 100, height: 100);
      const c = TransformOptions(width: 200, height: 200);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on later fields', () {
      const a = TransformOptions(
        width: 100,
        height: 100,
        quality: 80,
        format: ImageFormat.origin,
        resize: ResizeMode.cover,
      );
      const diffHeight = TransformOptions(
        width: 100,
        height: 200,
        quality: 80,
        format: ImageFormat.origin,
        resize: ResizeMode.cover,
      );
      const diffQuality = TransformOptions(
        width: 100,
        height: 100,
        quality: 50,
        format: ImageFormat.origin,
        resize: ResizeMode.cover,
      );
      const diffFormat = TransformOptions(
        width: 100,
        height: 100,
        quality: 80,
        format: ImageFormat.avif,
        resize: ResizeMode.cover,
      );
      const diffResize = TransformOptions(
        width: 100,
        height: 100,
        quality: 80,
        format: ImageFormat.origin,
        resize: ResizeMode.fill,
      );
      expect(a, isNot(equals(diffHeight)));
      expect(a, isNot(equals(diffQuality)));
      expect(a, isNot(equals(diffFormat)));
      expect(a, isNot(equals(diffResize)));
    });

    test('toString includes set fields', () {
      const options = TransformOptions(width: 200, format: ImageFormat.avif);
      final str = options.toString();
      expect(str, contains('TransformOptions'));
      expect(str, contains('200'));
    });
  });

  group('ImageFormat', () {
    test('has expected values', () {
      expect(
          ImageFormat.values,
          containsAll([
            ImageFormat.origin,
            ImageFormat.avif,
            ImageFormat.webp,
          ]));
    });
  });

  group('ResizeMode', () {
    test('has expected values', () {
      expect(
          ResizeMode.values,
          containsAll([
            ResizeMode.cover,
            ResizeMode.contain,
            ResizeMode.fill,
          ]));
    });
  });
}
