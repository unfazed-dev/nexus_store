import 'package:nexus_store_bloc_binding/src/state/nexus_store_state.dart';
import 'package:test/test.dart';

void main() {
  group('NexusStoreState', () {
    group('NexusStoreInitial', () {
      test('should have correct type', () {
        const state = NexusStoreInitial<String>();
        expect(state, isA<NexusStoreState<String>>());
      });

      test('dataOrNull should return null', () {
        const state = NexusStoreInitial<String>();
        expect(state.dataOrNull, isNull);
      });

      test('isLoading should return false', () {
        const state = NexusStoreInitial<String>();
        expect(state.isLoading, isFalse);
      });

      test('hasData should return false', () {
        const state = NexusStoreInitial<String>();
        expect(state.hasData, isFalse);
      });

      test('hasError should return false', () {
        const state = NexusStoreInitial<String>();
        expect(state.hasError, isFalse);
      });

      test('error should return null', () {
        const state = NexusStoreInitial<String>();
        expect(state.error, isNull);
      });

      test('stackTrace should return null', () {
        const state = NexusStoreInitial<String>();
        expect(state.stackTrace, isNull);
      });
    });

    group('NexusStoreLoading', () {
      test('should have correct type', () {
        const state = NexusStoreLoading<String>();
        expect(state, isA<NexusStoreState<String>>());
      });

      test('dataOrNull should return null without previous data', () {
        const state = NexusStoreLoading<String>();
        expect(state.dataOrNull, isNull);
      });

      test('dataOrNull should return previous data when provided', () {
        const state = NexusStoreLoading<String>(previousData: ['a', 'b']);
        expect(state.dataOrNull, equals(['a', 'b']));
      });

      test('isLoading should return true', () {
        const state = NexusStoreLoading<String>();
        expect(state.isLoading, isTrue);
      });

      test('hasData should return false without previous data', () {
        const state = NexusStoreLoading<String>();
        expect(state.hasData, isFalse);
      });

      test('hasData should return true with previous data', () {
        const state = NexusStoreLoading<String>(previousData: ['a']);
        expect(state.hasData, isTrue);
      });

      test('hasError should return false', () {
        const state = NexusStoreLoading<String>();
        expect(state.hasError, isFalse);
      });

      test('previousData should be accessible', () {
        const data = ['item1', 'item2'];
        const state = NexusStoreLoading<String>(previousData: data);
        expect(state.previousData, equals(data));
      });
    });

    group('NexusStoreLoaded', () {
      test('should have correct type', () {
        const state = NexusStoreLoaded<String>(data: ['a']);
        expect(state, isA<NexusStoreState<String>>());
      });

      test('dataOrNull should return data', () {
        const state = NexusStoreLoaded<String>(data: ['a', 'b']);
        expect(state.dataOrNull, equals(['a', 'b']));
      });

      test('data should return the data', () {
        const data = ['item1', 'item2'];
        const state = NexusStoreLoaded<String>(data: data);
        expect(state.data, equals(data));
      });

      test('isLoading should return false', () {
        const state = NexusStoreLoaded<String>(data: []);
        expect(state.isLoading, isFalse);
      });

      test('hasData should return true', () {
        const state = NexusStoreLoaded<String>(data: ['a']);
        expect(state.hasData, isTrue);
      });

      test('hasData should return true even for empty list', () {
        const state = NexusStoreLoaded<String>(data: []);
        expect(state.hasData, isTrue);
      });

      test('hasError should return false', () {
        const state = NexusStoreLoaded<String>(data: []);
        expect(state.hasError, isFalse);
      });
    });

    group('NexusStoreError', () {
      test('should have correct type', () {
        final state = NexusStoreError<String>(error: Exception('test'));
        expect(state, isA<NexusStoreState<String>>());
      });

      test('dataOrNull should return null without previous data', () {
        final state = NexusStoreError<String>(error: Exception('test'));
        expect(state.dataOrNull, isNull);
      });

      test('dataOrNull should return previous data when provided', () {
        final state = NexusStoreError<String>(
          error: Exception('test'),
          previousData: ['a', 'b'],
        );
        expect(state.dataOrNull, equals(['a', 'b']));
      });

      test('isLoading should return false', () {
        final state = NexusStoreError<String>(error: Exception('test'));
        expect(state.isLoading, isFalse);
      });

      test('hasData should return false without previous data', () {
        final state = NexusStoreError<String>(error: Exception('test'));
        expect(state.hasData, isFalse);
      });

      test('hasData should return true with previous data', () {
        final state = NexusStoreError<String>(
          error: Exception('test'),
          previousData: ['a'],
        );
        expect(state.hasData, isTrue);
      });

      test('hasError should return true', () {
        final state = NexusStoreError<String>(error: Exception('test'));
        expect(state.hasError, isTrue);
      });

      test('error should return the error', () {
        final error = Exception('test error');
        final state = NexusStoreError<String>(error: error);
        expect(state.error, equals(error));
      });

      test('stackTrace should return the stack trace when provided', () {
        final stackTrace = StackTrace.current;
        final state = NexusStoreError<String>(
          error: Exception('test'),
          stackTrace: stackTrace,
        );
        expect(state.stackTrace, equals(stackTrace));
      });

      test('previousData should be accessible', () {
        const data = ['item1', 'item2'];
        final state = NexusStoreError<String>(
          error: Exception('test'),
          previousData: data,
        );
        expect(state.previousData, equals(data));
      });
    });

    group('when', () {
      test('should call initial for NexusStoreInitial', () {
        const state = NexusStoreInitial<String>();
        final result = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          loaded: (_) => 'loaded',
          error: (_, __, ___) => 'error',
        );
        expect(result, equals('initial'));
      });

      test('should call loading for NexusStoreLoading', () {
        const state = NexusStoreLoading<String>(previousData: ['a']);
        List<String>? receivedPreviousData;
        state.when(
          initial: () {},
          loading: (prev) => receivedPreviousData = prev,
          loaded: (_) {},
          error: (_, __, ___) {},
        );
        expect(receivedPreviousData, equals(['a']));
      });

      test('should call loaded for NexusStoreLoaded', () {
        const state = NexusStoreLoaded<String>(data: ['a', 'b']);
        List<String>? receivedData;
        state.when(
          initial: () {},
          loading: (_) {},
          loaded: (data) => receivedData = data,
          error: (_, __, ___) {},
        );
        expect(receivedData, equals(['a', 'b']));
      });

      test('should call error for NexusStoreError', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final state = NexusStoreError<String>(
          error: error,
          stackTrace: stackTrace,
          previousData: ['a'],
        );
        Object? receivedError;
        StackTrace? receivedStackTrace;
        List<String>? receivedPreviousData;
        state.when(
          initial: () {},
          loading: (_) {},
          loaded: (_) {},
          error: (e, st, prev) {
            receivedError = e;
            receivedStackTrace = st;
            receivedPreviousData = prev;
          },
        );
        expect(receivedError, equals(error));
        expect(receivedStackTrace, equals(stackTrace));
        expect(receivedPreviousData, equals(['a']));
      });
    });

    group('maybeWhen', () {
      test('should call initial handler when provided', () {
        const state = NexusStoreInitial<String>();
        final result = state.maybeWhen(
          initial: () => 'initial',
          orElse: () => 'orElse',
        );
        expect(result, equals('initial'));
      });

      test('should call orElse for initial when handler not provided', () {
        const state = NexusStoreInitial<String>();
        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );
        expect(result, equals('orElse'));
      });

      test('should call loading handler when provided', () {
        const state = NexusStoreLoading<String>(previousData: ['a']);
        List<String>? receivedPreviousData;
        final result = state.maybeWhen(
          loading: (prev) {
            receivedPreviousData = prev;
            return 'loading';
          },
          orElse: () => 'orElse',
        );
        expect(result, equals('loading'));
        expect(receivedPreviousData, equals(['a']));
      });

      test('should call orElse for loading when handler not provided', () {
        const state = NexusStoreLoading<String>();
        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );
        expect(result, equals('orElse'));
      });

      test('should call loaded handler when provided', () {
        const state = NexusStoreLoaded<String>(data: ['a', 'b']);
        List<String>? receivedData;
        final result = state.maybeWhen(
          loaded: (data) {
            receivedData = data;
            return 'loaded';
          },
          orElse: () => 'orElse',
        );
        expect(result, equals('loaded'));
        expect(receivedData, equals(['a', 'b']));
      });

      test('should call orElse for loaded when handler not provided', () {
        const state = NexusStoreLoaded<String>(data: ['a']);
        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );
        expect(result, equals('orElse'));
      });

      test('should call error handler when provided', () {
        final error = Exception('test');
        final state = NexusStoreError<String>(error: error);
        Object? receivedError;
        final result = state.maybeWhen(
          error: (e, st, prev) {
            receivedError = e;
            return 'error';
          },
          orElse: () => 'orElse',
        );
        expect(result, equals('error'));
        expect(receivedError, equals(error));
      });

      test('should call orElse for error when handler not provided', () {
        final state = NexusStoreError<String>(error: Exception('test'));
        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );
        expect(result, equals('orElse'));
      });
    });

    group('equality', () {
      test('NexusStoreInitial instances should be equal', () {
        const state1 = NexusStoreInitial<String>();
        const state2 = NexusStoreInitial<String>();
        expect(state1, equals(state2));
      });

      test('NexusStoreLoading instances with same data should be equal', () {
        const state1 = NexusStoreLoading<String>(previousData: ['a', 'b']);
        const state2 = NexusStoreLoading<String>(previousData: ['a', 'b']);
        expect(state1, equals(state2));
      });

      test(
          'NexusStoreLoading instances with different data should not be equal',
          () {
        const state1 = NexusStoreLoading<String>(previousData: ['a']);
        const state2 = NexusStoreLoading<String>(previousData: ['b']);
        expect(state1, isNot(equals(state2)));
      });

      test('NexusStoreLoaded instances with same data should be equal', () {
        const state1 = NexusStoreLoaded<String>(data: ['a', 'b']);
        const state2 = NexusStoreLoaded<String>(data: ['a', 'b']);
        expect(state1, equals(state2));
      });

      test('NexusStoreLoaded instances with different data should not be equal',
          () {
        const state1 = NexusStoreLoaded<String>(data: ['a']);
        const state2 = NexusStoreLoaded<String>(data: ['b']);
        expect(state1, isNot(equals(state2)));
      });

      test('NexusStoreError instances with same error should be equal', () {
        final error = Exception('test');
        final state1 = NexusStoreError<String>(error: error);
        final state2 = NexusStoreError<String>(error: error);
        expect(state1, equals(state2));
      });

      test(
          'NexusStoreError instances with different errors should not be equal',
          () {
        final state1 = NexusStoreError<String>(error: Exception('test1'));
        final state2 = NexusStoreError<String>(error: Exception('test2'));
        expect(state1, isNot(equals(state2)));
      });

      test('different state types should not be equal', () {
        const initial = NexusStoreInitial<String>();
        const loading = NexusStoreLoading<String>();
        const loaded = NexusStoreLoaded<String>(data: []);
        final error = NexusStoreError<String>(error: Exception('test'));

        expect(initial, isNot(equals(loading)));
        expect(initial, isNot(equals(loaded)));
        expect(initial, isNot(equals(error)));
        expect(loading, isNot(equals(loaded)));
        expect(loading, isNot(equals(error)));
        expect(loaded, isNot(equals(error)));
      });
    });

    group('hashCode', () {
      test('NexusStoreInitial instances should have same hashCode', () {
        const state1 = NexusStoreInitial<String>();
        const state2 = NexusStoreInitial<String>();
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test(
          'NexusStoreLoaded instances with same data should have same hashCode',
          () {
        const state1 = NexusStoreLoaded<String>(data: ['a', 'b']);
        const state2 = NexusStoreLoaded<String>(data: ['a', 'b']);
        expect(state1.hashCode, equals(state2.hashCode));
      });
    });

    group('toString', () {
      test('NexusStoreInitial should have readable toString', () {
        const state = NexusStoreInitial<String>();
        expect(state.toString(), contains('NexusStoreInitial'));
      });

      test('NexusStoreLoading should have readable toString', () {
        const state = NexusStoreLoading<String>(previousData: ['a']);
        expect(state.toString(), contains('NexusStoreLoading'));
      });

      test('NexusStoreLoaded should have readable toString', () {
        const state = NexusStoreLoaded<String>(data: ['a', 'b']);
        expect(state.toString(), contains('NexusStoreLoaded'));
      });

      test('NexusStoreError should have readable toString', () {
        final state = NexusStoreError<String>(error: Exception('test'));
        expect(state.toString(), contains('NexusStoreError'));
      });
    });
  });
}
