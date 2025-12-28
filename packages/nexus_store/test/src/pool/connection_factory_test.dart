import 'package:test/test.dart';

import '../../fixtures/fake_connection.dart';
import '../../fixtures/fake_connection_factory.dart';

void main() {
  group('ConnectionFactory', () {
    group('FakeConnectionFactory', () {
      late FakeConnectionFactory factory;

      setUp(() {
        factory = FakeConnectionFactory();
        FakeConnection.resetCounter();
      });

      group('create', () {
        test('should create a new connection', () async {
          final connection = await factory.create();

          expect(connection, isNotNull);
          expect(connection.isOpen, isTrue);
          expect(factory.createCount, equals(1));
        });

        test('should create unique connections', () async {
          final conn1 = await factory.create();
          final conn2 = await factory.create();

          expect(conn1.id, isNot(equals(conn2.id)));
          expect(factory.createCount, equals(2));
        });

        test('should track created connections', () async {
          final conn1 = await factory.create();
          final conn2 = await factory.create();

          expect(factory.createdConnections, hasLength(2));
          expect(factory.createdConnections, contains(conn1));
          expect(factory.createdConnections, contains(conn2));
        });

        test('should throw when shouldFailOnCreate is true', () async {
          factory.shouldFailOnCreate = true;

          expect(
            () => factory.create(),
            throwsException,
          );
        });

        test('should throw custom exception when provided', () async {
          final customException = Exception('Custom error');
          factory.shouldFailOnCreate = true;
          factory.exceptionToThrow = customException;

          expect(
            () => factory.create(),
            throwsA(equals(customException)),
          );
        });

        test('should delay when createDelay is set', () async {
          factory.createDelay = const Duration(milliseconds: 50);
          final stopwatch = Stopwatch()..start();

          await factory.create();

          stopwatch.stop();
          expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(50));
        });
      });

      group('destroy', () {
        test('should close the connection', () async {
          final connection = await factory.create();
          expect(connection.isOpen, isTrue);

          await factory.destroy(connection);

          expect(connection.isOpen, isFalse);
          expect(factory.destroyCount, equals(1));
        });

        test('should track destroyed connections', () async {
          final connection = await factory.create();
          await factory.destroy(connection);

          expect(factory.destroyedConnections, hasLength(1));
          expect(factory.destroyedConnections, contains(connection));
        });

        test('should throw when shouldFailOnDestroy is true', () async {
          final connection = await factory.create();
          factory.shouldFailOnDestroy = true;

          expect(
            () => factory.destroy(connection),
            throwsException,
          );
        });
      });

      group('validate', () {
        test('should return true for open connection', () async {
          final connection = await factory.create();

          final isValid = await factory.validate(connection);

          expect(isValid, isTrue);
          expect(factory.validateCount, equals(1));
        });

        test('should return false for closed connection', () async {
          final connection = await factory.create();
          connection.close();

          final isValid = await factory.validate(connection);

          expect(isValid, isFalse);
        });

        test('should return false when shouldFailOnValidate is true', () async {
          final connection = await factory.create();
          factory.shouldFailOnValidate = true;

          final isValid = await factory.validate(connection);

          expect(isValid, isFalse);
        });

        test('should delay when validateDelay is set', () async {
          final connection = await factory.create();
          factory.validateDelay = const Duration(milliseconds: 50);
          final stopwatch = Stopwatch()..start();

          await factory.validate(connection);

          stopwatch.stop();
          expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(50));
        });
      });

      group('reset', () {
        test('should reset all counters', () async {
          await factory.create();
          await factory.create();
          final conn = await factory.create();
          await factory.validate(conn);
          await factory.destroy(conn);

          factory.reset();

          expect(factory.createCount, equals(0));
          expect(factory.destroyCount, equals(0));
          expect(factory.validateCount, equals(0));
        });

        test('should reset all flags', () {
          factory.shouldFailOnCreate = true;
          factory.shouldFailOnValidate = true;
          factory.shouldFailOnDestroy = true;
          factory.createDelay = const Duration(seconds: 1);
          factory.validateDelay = const Duration(seconds: 1);
          factory.exceptionToThrow = Exception('test');

          factory.reset();

          expect(factory.shouldFailOnCreate, isFalse);
          expect(factory.shouldFailOnValidate, isFalse);
          expect(factory.shouldFailOnDestroy, isFalse);
          expect(factory.createDelay, isNull);
          expect(factory.validateDelay, isNull);
          expect(factory.exceptionToThrow, isNull);
        });

        test('should clear connection lists', () async {
          final conn = await factory.create();
          await factory.destroy(conn);

          factory.reset();

          expect(factory.createdConnections, isEmpty);
          expect(factory.destroyedConnections, isEmpty);
        });
      });
    });

    group('FakeConnection', () {
      setUp(() {
        FakeConnection.resetCounter();
      });

      test('should generate unique IDs', () {
        final conn1 = FakeConnection();
        final conn2 = FakeConnection();

        expect(conn1.id, isNot(equals(conn2.id)));
      });

      test('should allow custom ID', () {
        final conn = FakeConnection('my-custom-id');

        expect(conn.id, equals('my-custom-id'));
      });

      test('should be open by default', () {
        final conn = FakeConnection();

        expect(conn.isOpen, isTrue);
      });

      test('should track operations', () {
        final conn = FakeConnection();

        conn.performOperation();
        conn.performOperation();

        expect(conn.operationCount, equals(2));
      });

      test('should throw on operation when closed', () {
        final conn = FakeConnection();
        conn.close();

        expect(
          () => conn.performOperation(),
          throwsStateError,
        );
      });

      test('should have meaningful toString', () {
        final conn = FakeConnection('test-id');

        expect(conn.toString(), contains('test-id'));
        expect(conn.toString(), contains('isOpen'));
      });
    });
  });
}
