import 'package:nexus_store/src/sync/delta_merge_strategy.dart';
import 'package:nexus_store/src/sync/delta_sync_config.dart';
import 'package:test/test.dart';

void main() {
  group('DeltaSyncConfig', () {
    group('creation', () {
      test('should create with default values', () {
        const config = DeltaSyncConfig();

        expect(config.enabled, isFalse);
        expect(config.excludeFields, isEmpty);
        expect(config.mergeStrategy, equals(DeltaMergeStrategy.lastWriteWins));
        expect(config.onMergeConflict, isNull);
      });

      test('should create with enabled flag', () {
        const config = DeltaSyncConfig(enabled: true);

        expect(config.enabled, isTrue);
      });

      test('should create with excluded fields', () {
        const config = DeltaSyncConfig(
          excludeFields: {'updatedAt', 'createdAt'},
        );

        expect(config.excludeFields, contains('updatedAt'));
        expect(config.excludeFields, contains('createdAt'));
        expect(config.excludeFields, hasLength(2));
      });

      test('should create with merge strategy', () {
        const config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.fieldLevel,
        );

        expect(config.mergeStrategy, equals(DeltaMergeStrategy.fieldLevel));
      });

      test('should create with custom merge conflict callback', () {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.custom,
          onMergeConflict: (field, local, remote) async {
            return local; // Always prefer local
          },
        );

        expect(config.onMergeConflict, isNotNull);
      });
    });

    group('presets', () {
      test('off should have enabled = false', () {
        const config = DeltaSyncConfig.off;

        expect(config.enabled, isFalse);
      });

      test('defaults should have enabled = true', () {
        const config = DeltaSyncConfig.defaults;

        expect(config.enabled, isTrue);
        expect(
          config.mergeStrategy,
          equals(DeltaMergeStrategy.lastWriteWins),
        );
      });

      test('fieldLevelMerge should use fieldLevel strategy', () {
        const config = DeltaSyncConfig.fieldLevelMerge;

        expect(config.enabled, isTrue);
        expect(config.mergeStrategy, equals(DeltaMergeStrategy.fieldLevel));
      });
    });

    group('shouldTrackField', () {
      test('should return true for non-excluded field', () {
        const config = DeltaSyncConfig(
          excludeFields: {'updatedAt'},
        );

        expect(config.shouldTrackField('name'), isTrue);
        expect(config.shouldTrackField('email'), isTrue);
      });

      test('should return false for excluded field', () {
        const config = DeltaSyncConfig(
          excludeFields: {'updatedAt', 'createdAt'},
        );

        expect(config.shouldTrackField('updatedAt'), isFalse);
        expect(config.shouldTrackField('createdAt'), isFalse);
      });

      test('should return true when no exclusions', () {
        const config = DeltaSyncConfig();

        expect(config.shouldTrackField('updatedAt'), isTrue);
      });
    });

    group('isCustomStrategy', () {
      test('should return true for custom strategy', () {
        const config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.custom,
        );

        expect(config.isCustomStrategy, isTrue);
      });

      test('should return false for other strategies', () {
        const config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.lastWriteWins,
        );

        expect(config.isCustomStrategy, isFalse);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        const config1 = DeltaSyncConfig(
          enabled: true,
          excludeFields: {'updatedAt'},
          mergeStrategy: DeltaMergeStrategy.fieldLevel,
        );

        const config2 = DeltaSyncConfig(
          enabled: true,
          excludeFields: {'updatedAt'},
          mergeStrategy: DeltaMergeStrategy.fieldLevel,
        );

        expect(config1, equals(config2));
      });

      test('should not be equal when enabled differs', () {
        const config1 = DeltaSyncConfig(enabled: true);
        const config2 = DeltaSyncConfig(enabled: false);

        expect(config1, isNot(equals(config2)));
      });
    });

    group('copyWith', () {
      test('should create copy with updated enabled', () {
        const original = DeltaSyncConfig(enabled: false);
        final copied = original.copyWith(enabled: true);

        expect(copied.enabled, isTrue);
        expect(original.enabled, isFalse);
      });

      test('should create copy with updated excludeFields', () {
        const original = DeltaSyncConfig(excludeFields: {'a'});
        final copied = original.copyWith(excludeFields: {'b', 'c'});

        expect(copied.excludeFields, equals({'b', 'c'}));
        expect(original.excludeFields, equals({'a'}));
      });

      test('should create copy with updated strategy', () {
        const original = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.lastWriteWins,
        );
        final copied = original.copyWith(
          mergeStrategy: DeltaMergeStrategy.fieldLevel,
        );

        expect(copied.mergeStrategy, equals(DeltaMergeStrategy.fieldLevel));
      });
    });

    group('toString', () {
      test('should include key fields', () {
        const config = DeltaSyncConfig(
          enabled: true,
          mergeStrategy: DeltaMergeStrategy.fieldLevel,
        );

        final str = config.toString();

        expect(str, contains('enabled'));
        expect(str, contains('mergeStrategy'));
      });
    });
  });
}
