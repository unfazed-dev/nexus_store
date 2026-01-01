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

      test('equality compares non-identical instances', () {
        // Create non-const instances to fully test the == operator
        // ignore: prefer_const_constructors
        final state1 = NexusSignalInitial<TestUser>();
        // ignore: prefer_const_constructors
        final state2 = NexusSignalInitial<TestUser>();

        // These are not identical but should be equal
        expect(identical(state1, state2), isFalse);
        expect(state1, equals(state2));
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

      test('maybeWhen() returns orElse when loading not provided', () {
        const state = NexusSignalLoading<TestUser>();

        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );

        expect(result, equals('orElse'));
      });

      test('toString returns correct value', () {
        const state = NexusSignalLoading<TestUser>(previousData: testUsers);

        expect(
          state.toString(),
          equals('NexusSignalLoading<TestUser>(previousData: $testUsers)'),
        );
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

      test('maybeWhen() returns orElse when data not provided', () {
        const state = NexusSignalData<TestUser>(data: testUsers);

        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );

        expect(result, equals('orElse'));
      });

      test('toString returns correct value', () {
        const state = NexusSignalData<TestUser>(data: testUsers);

        expect(
          state.toString(),
          equals('NexusSignalData<TestUser>(data: $testUsers)'),
        );
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

      test('maybeWhen() returns orElse when error not provided', () {
        final error = Exception('test error');
        final state = NexusSignalError<TestUser>(error: error);

        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );

        expect(result, equals('orElse'));
      });

      test('toString returns correct value', () {
        final error = Exception('test error');
        final stackTrace = StackTrace.current;
        final state = NexusSignalError<TestUser>(
          error: error,
          stackTrace: stackTrace,
          previousData: testUsers,
        );

        final str = state.toString();
        expect(str, contains('NexusSignalError'));
        expect(str, contains('error:'));
        expect(str, contains('stackTrace:'));
        expect(str, contains('previousData:'));
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

      test('maybeWhen() returns initial handler if provided', () {
        const state = NexusItemSignalInitial<TestUser>();

        final result = state.maybeWhen(
          initial: () => 'initial',
          orElse: () => 'orElse',
        );

        expect(result, equals('initial'));
      });

      test('toString returns correct value', () {
        const state = NexusItemSignalInitial<TestUser>();

        expect(state.toString(), equals('NexusItemSignalInitial<TestUser>()'));
      });

      test('equality works correctly', () {
        const state1 = NexusItemSignalInitial<TestUser>();
        const state2 = NexusItemSignalInitial<TestUser>();

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('equality compares non-identical instances', () {
        // ignore: prefer_const_constructors
        final state1 = NexusItemSignalInitial<TestUser>();
        // ignore: prefer_const_constructors
        final state2 = NexusItemSignalInitial<TestUser>();

        expect(identical(state1, state2), isFalse);
        expect(state1, equals(state2));
      });
    });

    group('NexusItemSignalLoading', () {
      test('has correct properties without previous data', () {
        const state = NexusItemSignalLoading<TestUser>();

        expect(state.dataOrNull, isNull);
        expect(state.isLoading, isTrue);
        expect(state.hasData, isFalse);
        expect(state.hasError, isFalse);
        expect(state.isNotFound, isFalse);
        expect(state.error, isNull);
        expect(state.stackTrace, isNull);
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

      test('maybeWhen() returns loading handler if provided', () {
        const state = NexusItemSignalLoading<TestUser>();

        final result = state.maybeWhen(
          loading: (prev) => 'loading',
          orElse: () => 'orElse',
        );

        expect(result, equals('loading'));
      });

      test('maybeWhen() returns orElse when loading not provided', () {
        const state = NexusItemSignalLoading<TestUser>();

        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );

        expect(result, equals('orElse'));
      });

      test('toString returns correct value', () {
        const state = NexusItemSignalLoading<TestUser>(previousData: testUser1);

        expect(
          state.toString(),
          equals('NexusItemSignalLoading<TestUser>(previousData: $testUser1)'),
        );
      });

      test('equality works correctly', () {
        const state1 = NexusItemSignalLoading<TestUser>(previousData: testUser1);
        const state2 = NexusItemSignalLoading<TestUser>(previousData: testUser1);
        const state3 = NexusItemSignalLoading<TestUser>();

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
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
        expect(state.error, isNull);
        expect(state.stackTrace, isNull);
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

      test('maybeWhen() returns data handler if provided', () {
        const state = NexusItemSignalData<TestUser>(data: testUser1);

        final result = state.maybeWhen(
          data: (data) => 'data: ${data.name}',
          orElse: () => 'orElse',
        );

        expect(result, equals('data: Alice'));
      });

      test('maybeWhen() returns orElse when data not provided', () {
        const state = NexusItemSignalData<TestUser>(data: testUser1);

        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );

        expect(result, equals('orElse'));
      });

      test('toString returns correct value', () {
        const state = NexusItemSignalData<TestUser>(data: testUser1);

        expect(
          state.toString(),
          equals('NexusItemSignalData<TestUser>(data: $testUser1)'),
        );
      });

      test('equality works correctly', () {
        const state1 = NexusItemSignalData<TestUser>(data: testUser1);
        const state2 = NexusItemSignalData<TestUser>(data: testUser1);
        const state3 = NexusItemSignalData<TestUser>(data: testUser2);

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
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
        expect(state.error, isNull);
        expect(state.stackTrace, isNull);
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

      test('maybeWhen() returns notFound handler if provided', () {
        const state = NexusItemSignalNotFound<TestUser>();

        final result = state.maybeWhen(
          notFound: () => 'notFound',
          orElse: () => 'orElse',
        );

        expect(result, equals('notFound'));
      });

      test('maybeWhen() returns orElse when notFound not provided', () {
        const state = NexusItemSignalNotFound<TestUser>();

        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );

        expect(result, equals('orElse'));
      });

      test('toString returns correct value', () {
        const state = NexusItemSignalNotFound<TestUser>();

        expect(
          state.toString(),
          equals('NexusItemSignalNotFound<TestUser>()'),
        );
      });

      test('equality works correctly', () {
        const state1 = NexusItemSignalNotFound<TestUser>();
        const state2 = NexusItemSignalNotFound<TestUser>();

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('equality compares non-identical instances', () {
        // ignore: prefer_const_constructors
        final state1 = NexusItemSignalNotFound<TestUser>();
        // ignore: prefer_const_constructors
        final state2 = NexusItemSignalNotFound<TestUser>();

        expect(identical(state1, state2), isFalse);
        expect(state1, equals(state2));
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

      test('maybeWhen() returns error handler if provided', () {
        final error = Exception('test error');
        final state = NexusItemSignalError<TestUser>(error: error);

        final result = state.maybeWhen(
          error: (e, st, prev) => 'error',
          orElse: () => 'orElse',
        );

        expect(result, equals('error'));
      });

      test('maybeWhen() returns orElse when error not provided', () {
        final error = Exception('test error');
        final state = NexusItemSignalError<TestUser>(error: error);

        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );

        expect(result, equals('orElse'));
      });

      test('toString returns correct value', () {
        final error = Exception('test error');
        final stackTrace = StackTrace.current;
        final state = NexusItemSignalError<TestUser>(
          error: error,
          stackTrace: stackTrace,
          previousData: testUser1,
        );

        final str = state.toString();
        expect(str, contains('NexusItemSignalError'));
        expect(str, contains('error:'));
        expect(str, contains('stackTrace:'));
        expect(str, contains('previousData:'));
      });

      test('equality works correctly', () {
        final error = Exception('test error');
        final stackTrace = StackTrace.current;
        final state1 = NexusItemSignalError<TestUser>(
          error: error,
          stackTrace: stackTrace,
        );
        final state2 = NexusItemSignalError<TestUser>(
          error: error,
          stackTrace: stackTrace,
        );
        final state3 = NexusItemSignalError<TestUser>(
          error: Exception('different error'),
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
      });

      test('hasData returns true when previousData is set', () {
        final error = Exception('test error');
        final stateWithPrevData = NexusItemSignalError<TestUser>(
          error: error,
          previousData: testUser1,
        );
        final stateWithoutPrevData = NexusItemSignalError<TestUser>(
          error: error,
        );

        expect(stateWithPrevData.hasData, isTrue);
        expect(stateWithoutPrevData.hasData, isFalse);
      });
    });
  });
}
