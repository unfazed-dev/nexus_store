import 'package:nexus_store_powersync_adapter/src/sync_rules/ps_bucket.dart';
import 'package:nexus_store_powersync_adapter/src/sync_rules/ps_query.dart';
import 'package:test/test.dart';

void main() {
  group('PSBucketType', () {
    test('has global type', () {
      expect(PSBucketType.global, isNotNull);
    });

    test('has userScoped type', () {
      expect(PSBucketType.userScoped, isNotNull);
    });

    test('has parameterized type', () {
      expect(PSBucketType.parameterized, isNotNull);
    });
  });

  group('PSBucket', () {
    group('global factory', () {
      test('creates bucket with global type', () {
        const bucket = PSBucket.global(
          name: 'public_data',
          queries: [PSQuery.select(table: 'settings')],
        );

        expect(bucket.type, equals(PSBucketType.global));
      });

      test('stores name correctly', () {
        const bucket = PSBucket.global(
          name: 'public_data',
          queries: [PSQuery.select(table: 'settings')],
        );

        expect(bucket.name, equals('public_data'));
      });

      test('stores queries correctly', () {
        final queries = [
          const PSQuery.select(table: 'settings'),
          const PSQuery.select(table: 'config'),
        ];
        final bucket = PSBucket.global(name: 'public_data', queries: queries);

        expect(bucket.queries, equals(queries));
      });

      test('has null parameters', () {
        const bucket = PSBucket.global(
          name: 'public_data',
          queries: [PSQuery.select(table: 'settings')],
        );

        expect(bucket.parameters, isNull);
      });
    });

    group('userScoped factory', () {
      test('creates bucket with userScoped type', () {
        const bucket = PSBucket.userScoped(
          name: 'user_data',
          queries: [
            PSQuery.select(table: 'users', filter: 'id = bucket.user_id'),
          ],
        );

        expect(bucket.type, equals(PSBucketType.userScoped));
      });

      test('stores name correctly', () {
        const bucket = PSBucket.userScoped(
          name: 'my_user_bucket',
          queries: [PSQuery.select(table: 'users')],
        );

        expect(bucket.name, equals('my_user_bucket'));
      });

      test('has null parameters', () {
        const bucket = PSBucket.userScoped(
          name: 'user_data',
          queries: [PSQuery.select(table: 'users')],
        );

        expect(bucket.parameters, isNull);
      });
    });

    group('parameterized factory', () {
      test('creates bucket with parameterized type', () {
        const paramSql = 'SELECT team_id FROM team_members '
            'WHERE user_id = token_parameters.user_id';
        const bucket = PSBucket.parameterized(
          name: 'team_data',
          parameters: paramSql,
          queries: [
            PSQuery.select(table: 'teams', filter: 'id = bucket.team_id'),
          ],
        );

        expect(bucket.type, equals(PSBucketType.parameterized));
      });

      test('stores parameters correctly', () {
        const parametersQuery = 'SELECT team_id FROM team_members '
            'WHERE user_id = token_parameters.user_id';
        const bucket = PSBucket.parameterized(
          name: 'team_data',
          parameters: parametersQuery,
          queries: [PSQuery.select(table: 'teams')],
        );

        expect(bucket.parameters, equals(parametersQuery));
      });

      test('stores name correctly', () {
        const bucket = PSBucket.parameterized(
          name: 'org_data',
          parameters: 'SELECT org_id FROM org_members',
          queries: [PSQuery.select(table: 'orgs')],
        );

        expect(bucket.name, equals('org_data'));
      });
    });

    group('toYamlMap', () {
      test('generates correct map for global bucket', () {
        const bucket = PSBucket.global(
          name: 'public_data',
          queries: [PSQuery.select(table: 'settings')],
        );

        final map = bucket.toYamlMap();

        expect(map['name'], equals('public_data'));
        expect(map['data'], isA<List<String>>());
        expect((map['data'] as List).first, equals('SELECT * FROM settings'));
      });

      test('generates correct map for userScoped bucket', () {
        const bucket = PSBucket.userScoped(
          name: 'user_data',
          queries: [
            PSQuery.select(table: 'users', filter: 'id = bucket.user_id'),
          ],
        );

        final map = bucket.toYamlMap();

        expect(map['name'], equals('user_data'));
        expect(
          map['parameters'],
          equals('SELECT request.user_id() as user_id'),
        );
        expect(map['data'], isA<List<String>>());
      });

      test('generates correct map for parameterized bucket', () {
        const parametersQuery = 'SELECT team_id FROM team_members '
            'WHERE user_id = token_parameters.user_id';
        const bucket = PSBucket.parameterized(
          name: 'team_data',
          parameters: parametersQuery,
          queries: [
            PSQuery.select(table: 'teams', filter: 'id = bucket.team_id'),
          ],
        );

        final map = bucket.toYamlMap();

        expect(map['name'], equals('team_data'));
        expect(map['parameters'], equals(parametersQuery));
        expect(map['data'], isA<List<String>>());
      });

      test('includes multiple queries in data array', () {
        const bucket = PSBucket.global(
          name: 'public_data',
          queries: [
            PSQuery.select(table: 'settings'),
            PSQuery.select(table: 'config', columns: ['key', 'value']),
          ],
        );

        final map = bucket.toYamlMap();
        final data = map['data'] as List;

        expect(data.length, equals(2));
        expect(data[0], equals('SELECT * FROM settings'));
        expect(data[1], equals('SELECT key, value FROM config'));
      });
    });

    group('equality', () {
      test('two buckets with same values are equal', () {
        const bucket1 = PSBucket.global(
          name: 'test',
          queries: [PSQuery.select(table: 'users')],
        );
        const bucket2 = PSBucket.global(
          name: 'test',
          queries: [PSQuery.select(table: 'users')],
        );

        expect(bucket1, equals(bucket2));
        expect(bucket1.hashCode, equals(bucket2.hashCode));
      });

      test('buckets with different types are not equal', () {
        const bucket1 = PSBucket.global(
          name: 'test',
          queries: [PSQuery.select(table: 'users')],
        );
        const bucket2 = PSBucket.userScoped(
          name: 'test',
          queries: [PSQuery.select(table: 'users')],
        );

        expect(bucket1, isNot(equals(bucket2)));
      });
    });
  });
}
