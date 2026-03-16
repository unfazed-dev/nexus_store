import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('FileOptions', () {
    test('constructs with defaults', () {
      const options = FileOptions();

      expect(options.contentType, 'application/octet-stream');
      expect(options.cacheControl, '3600');
      expect(options.upsert, false);
    });

    test('overrides defaults', () {
      const options = FileOptions(
        contentType: 'image/png',
        cacheControl: '86400',
        upsert: true,
      );

      expect(options.contentType, 'image/png');
      expect(options.cacheControl, '86400');
      expect(options.upsert, true);
    });

    test('equality compares all fields', () {
      const a = FileOptions(contentType: 'image/png', upsert: true);
      const b = FileOptions(contentType: 'image/png', upsert: true);
      const c = FileOptions(contentType: 'image/jpeg', upsert: false);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('toString includes all fields', () {
      const options = FileOptions(contentType: 'image/png');
      final str = options.toString();
      expect(str, contains('FileOptions'));
      expect(str, contains('image/png'));
    });
  });
}
