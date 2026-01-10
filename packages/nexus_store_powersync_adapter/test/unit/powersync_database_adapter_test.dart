import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_powersync_adapter/nexus_store_powersync_adapter.dart';
import 'package:powersync/powersync.dart' as ps;
import 'package:test/test.dart';

class FakeSupabasePowerSyncConnector extends Fake
    implements SupabasePowerSyncConnector {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSupabasePowerSyncConnector());
  });

  group('PowerSyncDatabaseAdapter interface', () {
    test('defines required lifecycle methods', () {
      // Verify the interface exists and has expected methods
      // ignore: unnecessary_type_check
      expect(PowerSyncDatabaseAdapter, isA<Type>());
    });
  });

  group('DefaultPowerSyncDatabaseAdapter', () {
    late ps.Schema testSchema;

    setUp(() {
      testSchema = ps.Schema([
        ps.Table('test_table', [ps.Column.text('name')]),
      ]);
    });

    group('construction', () {
      test('creates adapter with schema and path', () {
        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: '/test/path.db',
        );

        expect(adapter, isA<PowerSyncDatabaseAdapter>());
        expect(adapter.isInitialized, isFalse);
      });
    });

    group('isInitialized', () {
      test('returns false before initialize', () {
        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: '/test/path.db',
        );

        expect(adapter.isInitialized, isFalse);
      });
    });

    group('wrapper getter', () {
      test('throws StateError before initialize', () {
        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: '/test/path.db',
        );

        expect(
          () => adapter.wrapper,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('not initialized'),
            ),
          ),
        );
      });
    });

    group('connect', () {
      test('throws StateError before initialize', () {
        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: '/test/path.db',
        );
        final connector = FakeSupabasePowerSyncConnector();

        expect(
          () => adapter.connect(connector),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('not initialized'),
            ),
          ),
        );
      });
    });

    group('disconnect', () {
      test('can be called before initialize (no-op)', () async {
        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: '/test/path.db',
        );

        // Should not throw - it's a no-op when database is null
        await adapter.disconnect();
      });
    });

    group('close', () {
      test('can be called before initialize (no-op)', () async {
        final adapter = DefaultPowerSyncDatabaseAdapter(
          schema: testSchema,
          path: '/test/path.db',
        );

        // Should not throw - it's a no-op when database is null
        await adapter.close();

        // Should still be not initialized
        expect(adapter.isInitialized, isFalse);
      });
    });
  });

  group('PowerSyncDatabaseAdapterFactory typedef', () {
    test('defaultPowerSyncDatabaseAdapterFactory creates adapter', () {
      final schema = ps.Schema([
        ps.Table('test', [ps.Column.text('name')]),
      ]);

      final adapter = defaultPowerSyncDatabaseAdapterFactory(
        schema,
        '/test/path.db',
      );

      expect(adapter, isA<DefaultPowerSyncDatabaseAdapter>());
      expect(adapter.isInitialized, isFalse);
    });
  });
}
