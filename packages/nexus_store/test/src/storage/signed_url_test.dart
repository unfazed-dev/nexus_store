import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('SignedUrl', () {
    test('constructs with required fields', () {
      const signedUrl = SignedUrl(
        path: 'avatars/photo.jpg',
        signedUrl: 'https://storage.example.com/avatars/photo.jpg?token=abc',
      );

      expect(signedUrl.path, 'avatars/photo.jpg');
      expect(signedUrl.signedUrl,
          'https://storage.example.com/avatars/photo.jpg?token=abc');
      expect(signedUrl.error, isNull);
    });

    test('constructs with error', () {
      const signedUrl = SignedUrl(
        path: 'avatars/missing.jpg',
        signedUrl: '',
        error: 'Object not found',
      );

      expect(signedUrl.error, 'Object not found');
    });

    test('equality compares all fields', () {
      const a = SignedUrl(path: 'a.jpg', signedUrl: 'https://url-a');
      const b = SignedUrl(path: 'a.jpg', signedUrl: 'https://url-a');
      const c = SignedUrl(path: 'b.jpg', signedUrl: 'https://url-b');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on later fields', () {
      const a = SignedUrl(path: 'a.jpg', signedUrl: 'https://url-a');
      const diffUrl = SignedUrl(path: 'a.jpg', signedUrl: 'https://url-b');
      const diffError = SignedUrl(
        path: 'a.jpg',
        signedUrl: 'https://url-a',
        error: 'fail',
      );
      expect(a, isNot(equals(diffUrl)));
      expect(a, isNot(equals(diffError)));
    });

    test('toString includes key fields', () {
      const signedUrl = SignedUrl(path: 'a.jpg', signedUrl: 'https://url');
      final str = signedUrl.toString();
      expect(str, contains('SignedUrl'));
      expect(str, contains('a.jpg'));
    });
  });
}
