import 'package:nexus_store_crdt_adapter/src/crdt_merge_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('CrdtMergeStrategy', () {
    test('has all expected values', () {
      expect(CrdtMergeStrategy.values, hasLength(3));
      expect(CrdtMergeStrategy.values, contains(CrdtMergeStrategy.lww));
      expect(CrdtMergeStrategy.values, contains(CrdtMergeStrategy.fww));
      expect(CrdtMergeStrategy.values, contains(CrdtMergeStrategy.custom));
    });

    test('lww is the default strategy', () {
      expect(CrdtMergeStrategy.lww.name, 'lww');
    });
  });

  group('CrdtMergeConfig', () {
    test('creates config with default strategy (lww)', () {
      const config = CrdtMergeConfig<_TestEntity>();

      expect(config.defaultStrategy, CrdtMergeStrategy.lww);
      expect(config.fieldStrategies, isEmpty);
      expect(config.customMerge, isNull);
    });

    test('creates config with specified strategy', () {
      const config = CrdtMergeConfig<_TestEntity>(
        defaultStrategy: CrdtMergeStrategy.fww,
      );

      expect(config.defaultStrategy, CrdtMergeStrategy.fww);
    });

    test('creates config with field-level strategies', () {
      const config = CrdtMergeConfig<_TestEntity>(
        fieldStrategies: {
          'name': CrdtMergeStrategy.fww,
          'age': CrdtMergeStrategy.lww,
        },
      );

      expect(config.fieldStrategies['name'], CrdtMergeStrategy.fww);
      expect(config.fieldStrategies['age'], CrdtMergeStrategy.lww);
    });

    test('creates config with custom merge function', () {
      _TestEntity customMergeFn(
        _TestEntity local,
        _TestEntity remote,
        DateTime localTimestamp,
        DateTime remoteTimestamp,
      ) =>
          local; // Custom merge logic returns local

      final config = CrdtMergeConfig<_TestEntity>(
        defaultStrategy: CrdtMergeStrategy.custom,
        customMerge: customMergeFn,
      );

      expect(config.defaultStrategy, CrdtMergeStrategy.custom);
      expect(config.customMerge, isNotNull);
    });

    test('getStrategyForField returns field strategy when defined', () {
      const config = CrdtMergeConfig<_TestEntity>(
        fieldStrategies: {
          'name': CrdtMergeStrategy.fww,
        },
      );

      expect(config.getStrategyForField('name'), CrdtMergeStrategy.fww);
    });

    test('getStrategyForField returns default strategy when not defined', () {
      const config = CrdtMergeConfig<_TestEntity>(
        fieldStrategies: {
          'name': CrdtMergeStrategy.fww,
        },
      );

      expect(config.getStrategyForField('age'), CrdtMergeStrategy.lww);
    });
  });

  group('CrdtFieldMerger', () {
    test('merges using lww strategy', () {
      const merger = CrdtFieldMerger();
      final earlier = DateTime(2024, 1, 1, 10);
      final later = DateTime(2024, 1, 1, 11);

      final result = merger.mergeField(
        localValue: 'local',
        remoteValue: 'remote',
        localTimestamp: earlier,
        remoteTimestamp: later,
        strategy: CrdtMergeStrategy.lww,
      );

      expect(result, 'remote'); // Last writer wins
    });

    test('merges using lww strategy when local is later', () {
      const merger = CrdtFieldMerger();
      final earlier = DateTime(2024, 1, 1, 10);
      final later = DateTime(2024, 1, 1, 11);

      final result = merger.mergeField(
        localValue: 'local',
        remoteValue: 'remote',
        localTimestamp: later,
        remoteTimestamp: earlier,
        strategy: CrdtMergeStrategy.lww,
      );

      expect(result, 'local'); // Local is the last writer
    });

    test('merges using fww strategy', () {
      const merger = CrdtFieldMerger();
      final earlier = DateTime(2024, 1, 1, 10);
      final later = DateTime(2024, 1, 1, 11);

      final result = merger.mergeField(
        localValue: 'local',
        remoteValue: 'remote',
        localTimestamp: earlier,
        remoteTimestamp: later,
        strategy: CrdtMergeStrategy.fww,
      );

      expect(result, 'local'); // First writer wins
    });

    test('merges using fww strategy when remote is earlier', () {
      const merger = CrdtFieldMerger();
      final earlier = DateTime(2024, 1, 1, 10);
      final later = DateTime(2024, 1, 1, 11);

      final result = merger.mergeField(
        localValue: 'local',
        remoteValue: 'remote',
        localTimestamp: later,
        remoteTimestamp: earlier,
        strategy: CrdtMergeStrategy.fww,
      );

      expect(result, 'remote'); // Remote is the first writer
    });

    test('returns local for equal timestamps with lww', () {
      const merger = CrdtFieldMerger();
      final timestamp = DateTime(2024, 1, 1, 10);

      final result = merger.mergeField(
        localValue: 'local',
        remoteValue: 'remote',
        localTimestamp: timestamp,
        remoteTimestamp: timestamp,
        strategy: CrdtMergeStrategy.lww,
      );

      expect(result, 'local'); // Local wins on tie
    });

    test('throws for custom strategy without handler', () {
      const merger = CrdtFieldMerger();
      final timestamp = DateTime(2024, 1, 1, 10);

      expect(
        () => merger.mergeField(
          localValue: 'local',
          remoteValue: 'remote',
          localTimestamp: timestamp,
          remoteTimestamp: timestamp,
          strategy: CrdtMergeStrategy.custom,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('CrdtMergeResult', () {
    test('creates result with merged entity', () {
      final entity = _TestEntity('merged');
      final result = CrdtMergeResult<_TestEntity>(
        mergedEntity: entity,
        hadConflict: false,
      );

      expect(result.mergedEntity, entity);
      expect(result.hadConflict, false);
      expect(result.conflictDetails, isNull);
    });

    test('creates result with conflict', () {
      final entity = _TestEntity('merged');
      final result = CrdtMergeResult<_TestEntity>(
        mergedEntity: entity,
        hadConflict: true,
        conflictDetails: {
          'name': const CrdtConflictDetail(
            localValue: 'local',
            remoteValue: 'remote',
            resolvedValue: 'merged',
            strategy: CrdtMergeStrategy.lww,
          ),
        },
      );

      expect(result.hadConflict, true);
      expect(result.conflictDetails, isNotNull);
      expect(result.conflictDetails!['name']!.resolvedValue, 'merged');
    });
  });

  group('CrdtConflictDetail', () {
    test('stores conflict information', () {
      const detail = CrdtConflictDetail(
        localValue: 'local',
        remoteValue: 'remote',
        resolvedValue: 'remote',
        strategy: CrdtMergeStrategy.lww,
      );

      expect(detail.localValue, 'local');
      expect(detail.remoteValue, 'remote');
      expect(detail.resolvedValue, 'remote');
      expect(detail.strategy, CrdtMergeStrategy.lww);
    });
  });
}

class _TestEntity {
  _TestEntity(this.name);
  final String name;
}
