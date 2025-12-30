import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_signals_binding/src/state/nexus_signal_state.dart';
import 'package:nexus_store_signals_binding/src/state/nexus_item_signal_state.dart';

import 'fixtures/test_entities.dart';

void main() {
  group('NexusSignalState', () {
    group('NexusSignalInitial', () {
      test('has correct properties', () {
        const state = NexusSignalInitial<TestUser>();

        expect(state.dataOrNull, isNull);
        expect(state.isLoading, isFalse);
        expect(state.hasData, isFalse);
        expect(state.hasError, isFalse);
        expect(state.error, isNull);
        expect(state.stackTrace, isNull);
      });

      test('when() returns initial handler result', () {
        const state = NexusSignalInitial<TestUser>();

        final result = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          data: (_) => 'data',
          error: (_, __, ___) => 'error',
        );

        expect(result, equals('initial'));
      });

      test('maybeWhen() returns initial handler if provided', () {
        const state = NexusSignalInitial<TestUser>();

        final result = state.maybeWhen(
          initial: () => 'initial',
          orElse: () => 'orElse',
        );

        expect(result, equals('initial'));
      });

      test('maybeWhen() returns orElse when initial not provided', () {
        const state = NexusSignalInitial<TestUser>();

        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );

        expect(result, equals('orElse'));
      });

      test('equality works correctly', () {
        const state1 = NexusSignalInitial<TestUser>();
        const state2 = NexusSignalInitial<TestUser>();

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('toString returns correct value', () {
        const state = NexusSignalInitial<TestUser>();

        expect(state.toString(), contains('NexusSignalInitial'));
      });
    });

    group('NexusSignalLoading', () {
      test('has correct properties without previous data', () {
        const state = NexusSignalLoading<TestUser>();

        expect(state.dataOrNull, isNull);
        expect(state.isLoading, isTrue);
        expect(state.hasData, isFalse);
        expect(state.hasError, isFalse);
        expect(state.error, isNull);
        expect(state.stackTrace, isNull);
        expect(state.previousData, isNull);
      });

      test('has correct properties with previous data', () {
        const state = NexusSignalLoading<TestUser>(previousData: testUsers);

        expect(state.dataOrNull, equals(testUsers));
        expect(state.isLoading, isTrue);
        expect(state.hasData, isTrue);
        expect(state.hasError, isFalse);
        expect(state.previousData, equals(testUsers));
      });

      test('when() returns loading handler result', () {
        const state = NexusSignalLoading<TestUser>(previousData: testUsers);

        final result = state.when(
          initial: () => 'initial',
          loading: (prev) => 'loading: ${prev?.length}',
          data: (_) => 'data',
          error: (_, __, ___) => 'error',
        );

        expect(result, equals('loading: 3'));
      });

      test('maybeWhen() returns loading handler if provided', () {
        const state = NexusSignalLoading<TestUser>();

        final result = state.maybeWhen(
          loading: (_) => 'loading',
          orElse: () => 'orElse',
        );

        expect(result, equals('loading'));
      });

      test('equality works correctly', () {
        const state1 = NexusSignalLoading<TestUser>(previousData: testUsers);
        const state2 = NexusSignalLoading<TestUser>(previousData: testUsers);
        const state3 = NexusSignalLoading<TestUser>();

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
      });
    });

    group('NexusSignalData', () {
      test('has correct properties', () {
        const state = NexusSignalData<TestUser>(data: testUsers);

        expect(state.dataOrNull, equals(testUsers));
        expect(state.isLoading, isFalse);
        expect(state.hasData, isTrue);
        expect(state.hasError, isFalse);
        expect(state.error, isNull);
        expect(state.stackTrace, isNull);
        expect(state.data, equals(testUsers));
      });

      test('when() returns data handler result', () {
        const state = NexusSignalData<TestUser>(data: testUsers);

        final result = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          data: (data) => 'data: ${data.length}',
          error: (_, __, ___) => 'error',
        );

        expect(result, equals('data: 3'));
      });

      test('maybeWhen() returns data handler if provided', () {
        const state = NexusSignalData<TestUser>(data: testUsers);

        final result = state.maybeWhen(
          data: (data) => 'data',
          orElse: () => 'orElse',
        );

        expect(result, equals('data'));
      });

      test('equality works correctly', () {
        const state1 = NexusSignalData<TestUser>(data: testUsers);
        const state2 = NexusSignalData<TestUser>(data: testUsers);
        const state3 = NexusSignalData<TestUser>(data: [testUser1]);

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
      });
    });

    group('NexusSignalError', () {
      test('has correct properties without previous data', () {
        final error = Exception('test error');
        final stackTrace = StackTrace.current;
        final state = NexusSignalError<TestUser>(
          error: error,
          stackTrace: stackTrace,
        );

        expect(state.dataOrNull, isNull);
        expect(state.isLoading, isFalse);
        expect(state.hasData, isFalse);
        expect(state.hasError, isTrue);
        expect(state.error, equals(error));
        expect(state.stackTrace, equals(stackTrace));
        expect(state.previousData, isNull);
      });

      test('has correct properties with previous data', () {
        final error = Exception('test error');
        final state = NexusSignalError<TestUser>(
          error: error,
          previousData: testUsers,
        );

        expect(state.dataOrNull, equals(testUsers));
        expect(state.hasData, isTrue);
        expect(state.hasError, isTrue);
        expect(state.previousData, equals(testUsers));
      });

      test('when() returns error handler result', () {
        final error = Exception('test error');
        final state = NexusSignalError<TestUser>(error: error);

        final result = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          data: (_) => 'data',
          error: (e, st, prev) => 'error: $e',
        );

        expect(result, contains('error:'));
      });

      test('maybeWhen() returns error handler if provided', () {
        final error = Exception('test error');
        final state = NexusSignalError<TestUser>(error: error);

        final result = state.maybeWhen(
          error: (_, __, ___) => 'error',
          orElse: () => 'orElse',
        );

        expect(result, equals('error'));
      });

      test('equality works correctly', () {
        final error = Exception('test error');
        final state1 = NexusSignalError<TestUser>(error: error);
        final state2 = NexusSignalError<TestUser>(error: error);

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });
    });
  });

  group('NexusItemSignalState', () {
    group('NexusItemSignalInitial', () {
      test('has correct properties', () {
        const state = NexusItemSignalInitial<TestUser>();

        expect(state.dataOrNull, isNull);
        expect(state.isLoading, isFalse);
        expect(state.hasData, isFalse);
        expect(state.hasError, isFalse);
        expect(state.isNotFound, isFalse);
        expect(state.error, isNull);
        expect(state.stackTrace, isNull);
      });

      test('when() returns initial handler result', () {
        const state = NexusItemSignalInitial<TestUser>();

        final result = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          data: (_) => 'data',
          notFound: () => 'notFound',
          error: (_, __, ___) => 'error',
        );

        expect(result, equals('initial'));
      });

      test('maybeWhen() returns orElse when initial not provided', () {
        const state = NexusItemSignalInitial<TestUser>();

        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );

        expect(result, equals('orElse'));
      });
    });

    group('NexusItemSignalLoading', () {
      test('has correct properties without previous data', () {
        const state = NexusItemSignalLoading<TestUser>();

        expect(state.dataOrNull, isNull);
        expect(state.isLoading, isTrue);
        expect(state.hasData, isFalse);
        expect(state.isNotFound, isFalse);
      });

      test('has correct properties with previous data', () {
        const state = NexusItemSignalLoading<TestUser>(previousData: testUser1);

        expect(state.dataOrNull, equals(testUser1));
        expect(state.isLoading, isTrue);
        expect(state.hasData, isTrue);
        expect(state.previousData, equals(testUser1));
      });

      test('when() returns loading handler result', () {
        const state = NexusItemSignalLoading<TestUser>(previousData: testUser1);

        final result = state.when(
          initial: () => 'initial',
          loading: (prev) => 'loading: ${prev?.name}',
          data: (_) => 'data',
          notFound: () => 'notFound',
          error: (_, __, ___) => 'error',
        );

        expect(result, equals('loading: Alice'));
      });
    });

    group('NexusItemSignalData', () {
      test('has correct properties', () {
        const state = NexusItemSignalData<TestUser>(data: testUser1);

        expect(state.dataOrNull, equals(testUser1));
        expect(state.isLoading, isFalse);
        expect(state.hasData, isTrue);
        expect(state.hasError, isFalse);
        expect(state.isNotFound, isFalse);
        expect(state.data, equals(testUser1));
      });

      test('when() returns data handler result', () {
        const state = NexusItemSignalData<TestUser>(data: testUser1);

        final result = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          data: (data) => 'data: ${data.name}',
          notFound: () => 'notFound',
          error: (_, __, ___) => 'error',
        );

        expect(result, equals('data: Alice'));
      });
    });

    group('NexusItemSignalNotFound', () {
      test('has correct properties', () {
        const state = NexusItemSignalNotFound<TestUser>();

        expect(state.dataOrNull, isNull);
        expect(state.isLoading, isFalse);
        expect(state.hasData, isFalse);
        expect(state.hasError, isFalse);
        expect(state.isNotFound, isTrue);
      });

      test('when() returns notFound handler result', () {
        const state = NexusItemSignalNotFound<TestUser>();

        final result = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          data: (_) => 'data',
          notFound: () => 'notFound',
          error: (_, __, ___) => 'error',
        );

        expect(result, equals('notFound'));
      });
    });

    group('NexusItemSignalError', () {
      test('has correct properties without previous data', () {
        final error = Exception('test error');
        final state = NexusItemSignalError<TestUser>(error: error);

        expect(state.dataOrNull, isNull);
        expect(state.isLoading, isFalse);
        expect(state.hasData, isFalse);
        expect(state.hasError, isTrue);
        expect(state.isNotFound, isFalse);
        expect(state.error, equals(error));
      });

      test('has correct properties with previous data', () {
        final error = Exception('test error');
        final state = NexusItemSignalError<TestUser>(
          error: error,
          previousData: testUser1,
        );

        expect(state.dataOrNull, equals(testUser1));
        expect(state.hasData, isTrue);
        expect(state.hasError, isTrue);
      });

      test('when() returns error handler result', () {
        final error = Exception('test error');
        final state = NexusItemSignalError<TestUser>(error: error);

        final result = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          data: (_) => 'data',
          notFound: () => 'notFound',
          error: (e, st, prev) => 'error: $e',
        );

        expect(result, contains('error:'));
      });
    });
  });
}
