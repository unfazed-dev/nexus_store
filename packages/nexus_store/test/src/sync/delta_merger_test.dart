import 'package:nexus_store/src/sync/delta_change.dart';
import 'package:nexus_store/src/sync/delta_merge_strategy.dart';
import 'package:nexus_store/src/sync/delta_merger.dart';
import 'package:nexus_store/src/sync/delta_sync_config.dart';
import 'package:nexus_store/src/sync/field_change.dart';
import 'package:test/test.dart';

void main() {
  group('DeltaMerger', () {
    late DeltaMerger merger;
    late DateTime timestamp;

    setUp(() {
      merger = DeltaMerger();
      timestamp = DateTime(2024, 1, 15, 10, 30);
    });

    group('applyDelta', () {
      test('should apply single field change', () {
        final original = {'name': 'John', 'email': 'john@example.com'};
        final delta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final result = merger.applyDelta(original, delta);

        expect(result['name'], equals('Jane'));
        expect(result['email'], equals('john@example.com'));
      });

      test('should apply multiple field changes', () {
        final original = {
          'name': 'John',
          'email': 'john@example.com',
          'age': 30,
        };
        final delta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
            FieldChange(
              fieldName: 'age',
              oldValue: 30,
              newValue: 31,
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final result = merger.applyDelta(original, delta);

        expect(result['name'], equals('Jane'));
        expect(result['age'], equals(31));
        expect(result['email'], equals('john@example.com'));
      });

      test('should add new fields', () {
        final original = {'name': 'John'};
        final delta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'email',
              oldValue: null,
              newValue: 'john@example.com',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final result = merger.applyDelta(original, delta);

        expect(result['name'], equals('John'));
        expect(result['email'], equals('john@example.com'));
      });

      test('should handle field removal', () {
        final original = {'name': 'John', 'nickname': 'Johnny'};
        final delta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'nickname',
              oldValue: 'Johnny',
              newValue: null,
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final result = merger.applyDelta(original, delta);

        expect(result['name'], equals('John'));
        expect(result.containsKey('nickname'), isTrue);
        expect(result['nickname'], isNull);
      });
    });

    group('merge with conflicts', () {
      test('should detect conflicts when same field changed', () {
        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: DateTime(2024, 1, 15, 10, 0),
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 10, 0),
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Janet',
              timestamp: DateTime(2024, 1, 15, 11, 0),
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 11, 0),
        );

        final conflicts = merger.detectConflicts(localDelta, remoteDelta);

        expect(conflicts, hasLength(1));
        expect(conflicts.first.fieldName, equals('name'));
        expect(conflicts.first.localValue, equals('Jane'));
        expect(conflicts.first.remoteValue, equals('Janet'));
      });

      test('should not detect conflicts for different fields', () {
        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'email',
              oldValue: 'john@example.com',
              newValue: 'jane@example.com',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final conflicts = merger.detectConflicts(localDelta, remoteDelta);

        expect(conflicts, isEmpty);
      });
    });

    group('merge strategies', () {
      test('lastWriteWins should use later timestamp', () async {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.lastWriteWins,
        );
        final mergerWithConfig = DeltaMerger(config: config);

        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: DateTime(2024, 1, 15, 10, 0),
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 10, 0),
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Janet',
              timestamp: DateTime(2024, 1, 15, 11, 0), // Later timestamp
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 11, 0),
        );

        final result = await mergerWithConfig.mergeDeltas(
          base: {'name': 'John'},
          local: localDelta,
          remote: remoteDelta,
        );

        // Remote wins because it has later timestamp
        expect(result.merged['name'], equals('Janet'));
      });

      test('lastWriteWins should use local when it has later timestamp',
          () async {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.lastWriteWins,
        );
        final mergerWithConfig = DeltaMerger(config: config);

        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: DateTime(2024, 1, 15, 12, 0), // Later timestamp
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 12, 0),
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Janet',
              timestamp: DateTime(2024, 1, 15, 11, 0),
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 11, 0),
        );

        final result = await mergerWithConfig.mergeDeltas(
          base: {'name': 'John'},
          local: localDelta,
          remote: remoteDelta,
        );

        // Local wins because it has later timestamp
        expect(result.merged['name'], equals('Jane'));
      });

      test('fieldLevel should merge non-conflicting fields', () async {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.fieldLevel,
        );
        final mergerWithConfig = DeltaMerger(config: config);

        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'email',
              oldValue: 'john@example.com',
              newValue: 'jane@example.com',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final result = await mergerWithConfig.mergeDeltas(
          base: {'name': 'John', 'email': 'john@example.com'},
          local: localDelta,
          remote: remoteDelta,
        );

        // Both changes should be applied
        expect(result.merged['name'], equals('Jane'));
        expect(result.merged['email'], equals('jane@example.com'));
        expect(result.hasConflicts, isFalse);
      });

      test('custom strategy should use callback', () async {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.custom,
          onMergeConflict: (field, local, remote) async {
            // Always prefer local for name, remote for others
            if (field == 'name') return local;
            return remote;
          },
        );
        final mergerWithConfig = DeltaMerger(config: config);

        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
            FieldChange(
              fieldName: 'age',
              oldValue: 30,
              newValue: 31,
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Janet',
              timestamp: timestamp,
            ),
            FieldChange(
              fieldName: 'age',
              oldValue: 30,
              newValue: 32,
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final result = await mergerWithConfig.mergeDeltas(
          base: {'name': 'John', 'age': 30},
          local: localDelta,
          remote: remoteDelta,
        );

        expect(result.merged['name'], equals('Jane')); // Local wins
        expect(result.merged['age'], equals(32)); // Remote wins
      });

      test('custom strategy falls back to lastWriteWins when callback is null',
          () async {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.custom,
          // onMergeConflict is null
        );
        final mergerWithConfig = DeltaMerger(config: config);

        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: DateTime(2024, 1, 15, 10, 0),
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 10, 0),
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Janet',
              timestamp: DateTime(2024, 1, 15, 11, 0), // Later timestamp
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 11, 0),
        );

        final result = await mergerWithConfig.mergeDeltas(
          base: {'name': 'John'},
          local: localDelta,
          remote: remoteDelta,
        );

        // Falls back to lastWriteWins - remote has later timestamp
        expect(result.merged['name'], equals('Janet'));
      });

      test('custom callback exception propagates', () async {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.custom,
          onMergeConflict: (field, local, remote) async {
            throw Exception('Custom merge failed');
          },
        );
        final mergerWithConfig = DeltaMerger(config: config);

        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Janet',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        expect(
          () => mergerWithConfig.mergeDeltas(
            base: {'name': 'John'},
            local: localDelta,
            remote: remoteDelta,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Custom merge failed'),
          )),
        );
      });

      test('resolves multiple simultaneous conflicts', () async {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.lastWriteWins,
        );
        final mergerWithConfig = DeltaMerger(config: config);

        // Local changes 3 fields at 10:00
        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'LocalName',
              timestamp: DateTime(2024, 1, 15, 10, 0),
            ),
            FieldChange(
              fieldName: 'email',
              oldValue: 'old@example.com',
              newValue: 'local@example.com',
              timestamp: DateTime(2024, 1, 15, 12, 0), // Later than remote
            ),
            FieldChange(
              fieldName: 'age',
              oldValue: 30,
              newValue: 31,
              timestamp: DateTime(2024, 1, 15, 10, 0),
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 10, 0),
        );

        // Remote changes same 3 fields at 11:00 (except email at 10:30)
        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'RemoteName',
              timestamp: DateTime(2024, 1, 15, 11, 0), // Later than local
            ),
            FieldChange(
              fieldName: 'email',
              oldValue: 'old@example.com',
              newValue: 'remote@example.com',
              timestamp: DateTime(2024, 1, 15, 10, 30), // Earlier than local
            ),
            FieldChange(
              fieldName: 'age',
              oldValue: 30,
              newValue: 35,
              timestamp: DateTime(2024, 1, 15, 11, 0), // Later than local
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 11, 0),
        );

        final result = await mergerWithConfig.mergeDeltas(
          base: {'name': 'John', 'email': 'old@example.com', 'age': 30},
          local: localDelta,
          remote: remoteDelta,
        );

        // All 3 fields have conflicts
        expect(result.conflictCount, equals(3));
        expect(result.hasConflicts, isTrue);

        // Each resolved by lastWriteWins based on individual timestamps
        expect(result.merged['name'], equals('RemoteName')); // Remote later
        expect(
            result.merged['email'], equals('local@example.com')); // Local later
        expect(result.merged['age'], equals(35)); // Remote later

        // Verify resolved conflicts map
        expect(result.resolvedConflicts['name'], equals('RemoteName'));
        expect(result.resolvedConflicts['email'], equals('local@example.com'));
        expect(result.resolvedConflicts['age'], equals(35));
      });
    });

    group('MergeResult', () {
      test('should include merged data', () async {
        final result = await merger.mergeDeltas(
          base: {'name': 'John'},
          local: DeltaChange<String>(
            entityId: 'user-1',
            changes: [
              FieldChange(
                fieldName: 'name',
                oldValue: 'John',
                newValue: 'Jane',
                timestamp: timestamp,
              ),
            ],
            timestamp: timestamp,
          ),
          remote: DeltaChange<String>(
            entityId: 'user-1',
            changes: [],
            timestamp: timestamp,
          ),
        );

        expect(result.merged['name'], equals('Jane'));
      });

      test('should report conflicts', () async {
        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Janet',
              timestamp: timestamp,
            ),
          ],
          timestamp: timestamp,
        );

        final result = await merger.mergeDeltas(
          base: {'name': 'John'},
          local: localDelta,
          remote: remoteDelta,
        );

        expect(result.hasConflicts, isTrue);
        expect(result.conflicts, hasLength(1));
        expect(result.conflicts.first.fieldName, equals('name'));
      });
    });

    group('FieldConflict isLocalNewer (line 32)', () {
      test('isLocalNewer returns true when local timestamp is after remote',
          () {
        final localTime = DateTime(2024, 1, 15, 12, 0);
        final remoteTime = DateTime(2024, 1, 15, 10, 0);

        final conflict = FieldConflict(
          fieldName: 'name',
          localValue: 'Local',
          remoteValue: 'Remote',
          localTimestamp: localTime,
          remoteTimestamp: remoteTime,
        );

        expect(conflict.isLocalNewer, isTrue);
        expect(conflict.isRemoteNewer, isFalse);
      });

      test('isLocalNewer returns false when remote timestamp is after local',
          () {
        final localTime = DateTime(2024, 1, 15, 10, 0);
        final remoteTime = DateTime(2024, 1, 15, 12, 0);

        final conflict = FieldConflict(
          fieldName: 'name',
          localValue: 'Local',
          remoteValue: 'Remote',
          localTimestamp: localTime,
          remoteTimestamp: remoteTime,
        );

        expect(conflict.isLocalNewer, isFalse);
        expect(conflict.isRemoteNewer, isTrue);
      });
    });

    group('fieldLevel strategy with remote newer (lines 194-196)', () {
      test('uses remoteValue when remote is newer in fieldLevel strategy',
          () async {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.fieldLevel,
        );
        final mergerWithConfig = DeltaMerger(config: config);

        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'Jane',
              timestamp: DateTime(2024, 1, 15, 10, 0),
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 10, 0),
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'RemoteJane',
              timestamp: DateTime(2024, 1, 15, 12, 0), // Remote is newer
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 12, 0),
        );

        final result = await mergerWithConfig.mergeDeltas(
          base: {'name': 'John'},
          local: localDelta,
          remote: remoteDelta,
        );

        // Remote should win because it's newer
        expect(result.merged['name'], equals('RemoteJane'));
      });

      test(
          'uses localValue when local is newer in fieldLevel strategy (line 196)',
          () async {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.fieldLevel,
        );
        final mergerWithConfig = DeltaMerger(config: config);

        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'LocalJane',
              timestamp: DateTime(2024, 1, 15, 12, 0), // Local is newer
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 12, 0),
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'RemoteJane',
              timestamp: DateTime(2024, 1, 15, 10, 0), // Remote is older
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 10, 0),
        );

        final result = await mergerWithConfig.mergeDeltas(
          base: {'name': 'John'},
          local: localDelta,
          remote: remoteDelta,
        );

        // Local should win because it's newer (line 196: conflict.localValue)
        expect(result.merged['name'], equals('LocalJane'));
      });
    });

    group('custom strategy fallback with local newer (line 210)', () {
      test('uses localValue when local is newer and callback is null',
          () async {
        final config = DeltaSyncConfig(
          mergeStrategy: DeltaMergeStrategy.custom,
          // onMergeConflict is null - will fall back to lastWriteWins
        );
        final mergerWithConfig = DeltaMerger(config: config);

        final localDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'LocalJane',
              timestamp: DateTime(2024, 1, 15, 12, 0), // Local is newer
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 12, 0),
        );

        final remoteDelta = DeltaChange<String>(
          entityId: 'user-1',
          changes: [
            FieldChange(
              fieldName: 'name',
              oldValue: 'John',
              newValue: 'RemoteJane',
              timestamp: DateTime(2024, 1, 15, 10, 0), // Remote is older
            ),
          ],
          timestamp: DateTime(2024, 1, 15, 10, 0),
        );

        final result = await mergerWithConfig.mergeDeltas(
          base: {'name': 'John'},
          local: localDelta,
          remote: remoteDelta,
        );

        // Local should win because it's newer (line 210: localValue)
        expect(result.merged['name'], equals('LocalJane'));
      });
    });

    group('edge cases', () {
      test('should handle empty deltas', () async {
        final result = await merger.mergeDeltas(
          base: {'name': 'John'},
          local: DeltaChange<String>(
            entityId: 'user-1',
            changes: [],
            timestamp: timestamp,
          ),
          remote: DeltaChange<String>(
            entityId: 'user-1',
            changes: [],
            timestamp: timestamp,
          ),
        );

        expect(result.merged['name'], equals('John'));
        expect(result.hasConflicts, isFalse);
      });

      test('should handle only local changes', () async {
        final result = await merger.mergeDeltas(
          base: {'name': 'John'},
          local: DeltaChange<String>(
            entityId: 'user-1',
            changes: [
              FieldChange(
                fieldName: 'name',
                oldValue: 'John',
                newValue: 'Jane',
                timestamp: timestamp,
              ),
            ],
            timestamp: timestamp,
          ),
          remote: DeltaChange<String>(
            entityId: 'user-1',
            changes: [],
            timestamp: timestamp,
          ),
        );

        expect(result.merged['name'], equals('Jane'));
        expect(result.hasConflicts, isFalse);
      });

      test('should handle only remote changes', () async {
        final result = await merger.mergeDeltas(
          base: {'name': 'John'},
          local: DeltaChange<String>(
            entityId: 'user-1',
            changes: [],
            timestamp: timestamp,
          ),
          remote: DeltaChange<String>(
            entityId: 'user-1',
            changes: [
              FieldChange(
                fieldName: 'name',
                oldValue: 'John',
                newValue: 'Jane',
                timestamp: timestamp,
              ),
            ],
            timestamp: timestamp,
          ),
        );

        expect(result.merged['name'], equals('Jane'));
        expect(result.hasConflicts, isFalse);
      });
    });
  });
}
