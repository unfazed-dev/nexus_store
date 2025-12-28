import 'package:nexus_store/src/lazy/lazy_load_config.dart';
import 'package:test/test.dart';

void main() {
  group('LazyLoadConfig', () {
    group('creation', () {
      test('creates with default values', () {
        const config = LazyLoadConfig();

        expect(config.lazyFields, isEmpty);
        expect(config.batchSize, equals(10));
        expect(config.batchDelay, equals(const Duration(milliseconds: 50)));
        expect(config.preloadOnWatch, isFalse);
        expect(config.placeholders, isEmpty);
      });

      test('creates with custom lazyFields', () {
        const config = LazyLoadConfig(
          lazyFields: {'thumbnail', 'fullImage'},
        );

        expect(config.lazyFields, equals({'thumbnail', 'fullImage'}));
      });

      test('creates with custom batchSize', () {
        const config = LazyLoadConfig(batchSize: 25);

        expect(config.batchSize, equals(25));
      });

      test('creates with custom batchDelay', () {
        const config = LazyLoadConfig(
          batchDelay: Duration(milliseconds: 100),
        );

        expect(config.batchDelay, equals(const Duration(milliseconds: 100)));
      });

      test('creates with preloadOnWatch enabled', () {
        const config = LazyLoadConfig(preloadOnWatch: true);

        expect(config.preloadOnWatch, isTrue);
      });

      test('creates with placeholders', () {
        const config = LazyLoadConfig(
          placeholders: {
            'thumbnail': null,
            'description': '',
          },
        );

        expect(config.placeholders, equals({'thumbnail': null, 'description': ''}));
      });
    });

    group('presets', () {
      test('off preset has lazy loading disabled', () {
        expect(LazyLoadConfig.off.lazyFields, isEmpty);
        expect(LazyLoadConfig.off.batchSize, equals(10));
      });

      test('media preset has common media fields', () {
        expect(
          LazyLoadConfig.media.lazyFields,
          containsAll(['thumbnail', 'fullImage', 'video']),
        );
        expect(LazyLoadConfig.media.batchSize, equals(5));
      });
    });

    group('isLazyField', () {
      test('returns true for configured lazy fields', () {
        const config = LazyLoadConfig(
          lazyFields: {'thumbnail', 'fullImage'},
        );

        expect(config.isLazyField('thumbnail'), isTrue);
        expect(config.isLazyField('fullImage'), isTrue);
      });

      test('returns false for non-lazy fields', () {
        const config = LazyLoadConfig(
          lazyFields: {'thumbnail'},
        );

        expect(config.isLazyField('name'), isFalse);
        expect(config.isLazyField('id'), isFalse);
      });

      test('returns false when no lazy fields configured', () {
        const config = LazyLoadConfig();

        expect(config.isLazyField('thumbnail'), isFalse);
      });
    });

    group('getPlaceholder', () {
      test('returns configured placeholder for field', () {
        const config = LazyLoadConfig(
          placeholders: {
            'thumbnail': null,
            'description': 'Loading...',
          },
        );

        expect(config.getPlaceholder('thumbnail'), isNull);
        expect(config.getPlaceholder('description'), equals('Loading...'));
      });

      test('returns null for unconfigured field', () {
        const config = LazyLoadConfig(
          placeholders: {'thumbnail': null},
        );

        expect(config.getPlaceholder('fullImage'), isNull);
      });

      test('returns null when no placeholders configured', () {
        const config = LazyLoadConfig();

        expect(config.getPlaceholder('thumbnail'), isNull);
      });
    });

    group('hasLazyFields', () {
      test('returns true when lazy fields are configured', () {
        const config = LazyLoadConfig(
          lazyFields: {'thumbnail'},
        );

        expect(config.hasLazyFields, isTrue);
      });

      test('returns false when no lazy fields configured', () {
        const config = LazyLoadConfig();

        expect(config.hasLazyFields, isFalse);
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = LazyLoadConfig(
          lazyFields: {'thumbnail'},
          batchSize: 10,
        );
        const config2 = LazyLoadConfig(
          lazyFields: {'thumbnail'},
          batchSize: 10,
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('different configs are not equal', () {
        const config1 = LazyLoadConfig(
          lazyFields: {'thumbnail'},
        );
        const config2 = LazyLoadConfig(
          lazyFields: {'fullImage'},
        );

        expect(config1, isNot(equals(config2)));
      });
    });

    group('copyWith', () {
      test('copies with new lazyFields', () {
        const original = LazyLoadConfig(
          lazyFields: {'thumbnail'},
          batchSize: 10,
        );

        final copied = original.copyWith(
          lazyFields: {'fullImage', 'video'},
        );

        expect(copied.lazyFields, equals({'fullImage', 'video'}));
        expect(copied.batchSize, equals(10)); // Unchanged
      });

      test('copies with new batchSize', () {
        const original = LazyLoadConfig(
          lazyFields: {'thumbnail'},
          batchSize: 10,
        );

        final copied = original.copyWith(batchSize: 25);

        expect(copied.lazyFields, equals({'thumbnail'})); // Unchanged
        expect(copied.batchSize, equals(25));
      });
    });
  });
}
