import 'package:nexus_store/src/lazy/annotations.dart';
import 'package:test/test.dart';

void main() {
  group('Lazy annotation', () {
    test('can be instantiated with default values', () {
      const annotation = Lazy();

      expect(annotation.placeholder, isNull);
      expect(annotation.preloadOnWatch, isFalse);
    });

    test('can be instantiated with custom placeholder', () {
      const annotation = Lazy(placeholder: 'loading...');

      expect(annotation.placeholder, equals('loading...'));
    });

    test('can be instantiated with preloadOnWatch enabled', () {
      const annotation = Lazy(preloadOnWatch: true);

      expect(annotation.preloadOnWatch, isTrue);
    });

    test('can be instantiated with all parameters', () {
      const annotation = Lazy(
        placeholder: 'default.png',
        preloadOnWatch: true,
      );

      expect(annotation.placeholder, equals('default.png'));
      expect(annotation.preloadOnWatch, isTrue);
    });
  });

  group('NexusLazy annotation', () {
    test('can be instantiated with default values', () {
      const annotation = NexusLazy();

      expect(annotation.generateAccessors, isTrue);
      expect(annotation.generateWrapper, isTrue);
    });

    test('can disable accessor generation', () {
      const annotation = NexusLazy(generateAccessors: false);

      expect(annotation.generateAccessors, isFalse);
      expect(annotation.generateWrapper, isTrue);
    });

    test('can disable wrapper generation', () {
      const annotation = NexusLazy(generateWrapper: false);

      expect(annotation.generateAccessors, isTrue);
      expect(annotation.generateWrapper, isFalse);
    });

    test('can disable both features', () {
      const annotation = NexusLazy(
        generateAccessors: false,
        generateWrapper: false,
      );

      expect(annotation.generateAccessors, isFalse);
      expect(annotation.generateWrapper, isFalse);
    });
  });

  group('LazyAccessor annotation', () {
    test('can be instantiated with field name', () {
      const annotation = LazyAccessor('thumbnail');

      expect(annotation.fieldName, equals('thumbnail'));
      expect(annotation.returnType, isNull);
    });

    test('can be instantiated with return type', () {
      const annotation = LazyAccessor('thumbnail', returnType: 'Uint8List');

      expect(annotation.fieldName, equals('thumbnail'));
      expect(annotation.returnType, equals('Uint8List'));
    });
  });

  group('annotation usage examples', () {
    test('annotations are const constructors', () {
      // All annotations should be usable as const
      const lazy = Lazy();
      const nexusLazy = NexusLazy();
      const accessor = LazyAccessor('test');

      expect(lazy, isNotNull);
      expect(nexusLazy, isNotNull);
      expect(accessor, isNotNull);
    });
  });
}
