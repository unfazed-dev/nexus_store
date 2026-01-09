import 'dart:io';

import 'package:nexus_store_powersync_adapter/src/sync_rules/ps_bucket.dart';
import 'package:nexus_store_powersync_adapter/src/sync_rules/ps_query.dart';
import 'package:nexus_store_powersync_adapter/src/sync_rules/ps_sync_rules.dart';
import 'package:test/test.dart';

void main() {
  group('PSSyncRules', () {
    group('constructor', () {
      test('creates with empty bucket list', () {
        const syncRules = PSSyncRules([]);

        expect(syncRules.buckets, isEmpty);
      });

      test('creates with multiple buckets', () {
        final buckets = [
          const PSBucket.global(
            name: 'public',
            queries: [PSQuery.select(table: 'settings')],
          ),
          const PSBucket.userScoped(
            name: 'private',
            queries: [PSQuery.select(table: 'users')],
          ),
        ];
        final syncRules = PSSyncRules(buckets);

        expect(syncRules.buckets.length, equals(2));
      });
    });

    group('toYamlMap', () {
      test('generates map with bucket_definitions key', () {
        const syncRules = PSSyncRules([
          PSBucket.global(
            name: 'public',
            queries: [PSQuery.select(table: 'settings')],
          ),
        ]);

        final map = syncRules.toYamlMap();

        expect(map.containsKey('bucket_definitions'), isTrue);
      });

      test('includes all buckets in bucket_definitions', () {
        const syncRules = PSSyncRules([
          PSBucket.global(
            name: 'public',
            queries: [PSQuery.select(table: 'settings')],
          ),
          PSBucket.userScoped(
            name: 'user_data',
            queries: [PSQuery.select(table: 'users')],
          ),
        ]);

        final map = syncRules.toYamlMap();
        final bucketDefs = map['bucket_definitions'] as List<dynamic>;

        expect(bucketDefs.length, equals(2));
      });

      test('each bucket has correct structure', () {
        const syncRules = PSSyncRules([
          PSBucket.global(
            name: 'public',
            queries: [PSQuery.select(table: 'settings')],
          ),
        ]);

        final map = syncRules.toYamlMap();
        final bucketDefs = map['bucket_definitions'] as List<dynamic>;
        final firstBucket = bucketDefs.first as Map<String, dynamic>;

        expect(firstBucket['name'], equals('public'));
        expect(firstBucket['data'], isA<List<dynamic>>());
      });
    });

    group('toYaml', () {
      test('generates valid YAML string', () {
        const syncRules = PSSyncRules([
          PSBucket.global(
            name: 'public',
            queries: [PSQuery.select(table: 'settings')],
          ),
        ]);

        final yaml = syncRules.toYaml();

        expect(yaml, contains('bucket_definitions:'));
        expect(yaml, contains('name: public'));
        expect(yaml, contains('SELECT * FROM settings'));
      });

      test('includes parameters for userScoped buckets', () {
        const syncRules = PSSyncRules([
          PSBucket.userScoped(
            name: 'user_data',
            queries: [
              PSQuery.select(table: 'users', filter: 'id = bucket.user_id'),
            ],
          ),
        ]);

        final yaml = syncRules.toYaml();

        expect(yaml, contains('parameters:'));
        expect(yaml, contains('request.user_id()'));
      });

      test('includes custom parameters for parameterized buckets', () {
        const syncRules = PSSyncRules([
          PSBucket.parameterized(
            name: 'team_data',
            parameters: 'SELECT team_id FROM team_members',
            queries: [PSQuery.select(table: 'teams')],
          ),
        ]);

        final yaml = syncRules.toYaml();

        expect(yaml, contains('SELECT team_id FROM team_members'));
      });

      test('handles multiple buckets', () {
        const syncRules = PSSyncRules([
          PSBucket.global(
            name: 'public',
            queries: [PSQuery.select(table: 'settings')],
          ),
          PSBucket.userScoped(
            name: 'user_data',
            queries: [PSQuery.select(table: 'users')],
          ),
          PSBucket.parameterized(
            name: 'team_data',
            parameters: 'SELECT team_id FROM team_members',
            queries: [PSQuery.select(table: 'teams')],
          ),
        ]);

        final yaml = syncRules.toYaml();

        expect(yaml, contains('name: public'));
        expect(yaml, contains('name: user_data'));
        expect(yaml, contains('name: team_data'));
      });
    });

    group('saveToFile', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('sync_rules_test_');
      });

      tearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('writes YAML to file', () async {
        const syncRules = PSSyncRules([
          PSBucket.global(
            name: 'public',
            queries: [PSQuery.select(table: 'settings')],
          ),
        ]);

        final filePath = '${tempDir.path}/sync-rules.yaml';
        await syncRules.saveToFile(filePath);

        final file = File(filePath);
        expect(file.existsSync(), isTrue);

        final content = await file.readAsString();
        expect(content, contains('bucket_definitions:'));
        expect(content, contains('name: public'));
      });

      test('overwrites existing file', () async {
        final filePath = '${tempDir.path}/sync-rules.yaml';

        // Write initial file
        await File(filePath).writeAsString('old content');

        // Save new rules
        const syncRules = PSSyncRules([
          PSBucket.global(
            name: 'new_bucket',
            queries: [PSQuery.select(table: 'new_table')],
          ),
        ]);
        await syncRules.saveToFile(filePath);

        final content = await File(filePath).readAsString();
        expect(content, contains('name: new_bucket'));
        expect(content, isNot(contains('old content')));
      });
    });

    group('equality', () {
      test('two sync rules with same buckets are equal', () {
        const rules1 = PSSyncRules([
          PSBucket.global(
            name: 'test',
            queries: [PSQuery.select(table: 'users')],
          ),
        ]);
        const rules2 = PSSyncRules([
          PSBucket.global(
            name: 'test',
            queries: [PSQuery.select(table: 'users')],
          ),
        ]);

        expect(rules1, equals(rules2));
        expect(rules1.hashCode, equals(rules2.hashCode));
      });

      test('sync rules with different buckets are not equal', () {
        const rules1 = PSSyncRules([
          PSBucket.global(
            name: 'test1',
            queries: [PSQuery.select(table: 'users')],
          ),
        ]);
        const rules2 = PSSyncRules([
          PSBucket.global(
            name: 'test2',
            queries: [PSQuery.select(table: 'users')],
          ),
        ]);

        expect(rules1, isNot(equals(rules2)));
      });
    });
  });
}
