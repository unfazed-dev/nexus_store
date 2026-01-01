import 'package:nexus_store_bloc_binding/src/state/nexus_item_state.dart';
import 'package:test/test.dart';

void main() {
  group('NexusItemState', () {
    group('NexusItemInitial', () {
      test('should have correct type', () {
        const state = NexusItemInitial<String>();
        expect(state, isA<NexusItemState<String>>());
      });

      test('dataOrNull should return null', () {
        const state = NexusItemInitial<String>();
        expect(state.dataOrNull, isNull);
      });

      test('isLoading should return false', () {
        const state = NexusItemInitial<String>();
        expect(state.isLoading, isFalse);
      });

      test('hasData should return false', () {
        const state = NexusItemInitial<String>();
        expect(state.hasData, isFalse);
      });

      test('hasError should return false', () {
        const state = NexusItemInitial<String>();
        expect(state.hasError, isFalse);
      });

      test('error should return null', () {
        const state = NexusItemInitial<String>();
        expect(state.error, isNull);
      });

      test('stackTrace should return null', () {
        const state = NexusItemInitial<String>();
        expect(state.stackTrace, isNull);
      });

      test('isNotFound should return false', () {
        const state = NexusItemInitial<String>();
        expect(state.isNotFound, isFalse);
      });
    });

    group('NexusItemLoading', () {
      test('should have correct type', () {
        const state = NexusItemLoading<String>();
        expect(state, isA<NexusItemState<String>>());
      });

      test('dataOrNull should return null without previous data', () {
        const state = NexusItemLoading<String>();
        expect(state.dataOrNull, isNull);
      });

      test('dataOrNull should return previous data when provided', () {
        const state = NexusItemLoading<String>(previousData: 'test');
        expect(state.dataOrNull, equals('test'));
      });

      test('isLoading should return true', () {
        const state = NexusItemLoading<String>();
        expect(state.isLoading, isTrue);
      });

      test('hasData should return false without previous data', () {
        const state = NexusItemLoading<String>();
        expect(state.hasData, isFalse);
      });

      test('hasData should return true with previous data', () {
        const state = NexusItemLoading<String>(previousData: 'test');
        expect(state.hasData, isTrue);
      });

      test('hasError should return false', () {
        const state = NexusItemLoading<String>();
        expect(state.hasError, isFalse);
      });

      test('previousData should be accessible', () {
        const state = NexusItemLoading<String>(previousData: 'previous');
        expect(state.previousData, equals('previous'));
      });

      test('isNotFound should return false', () {
        const state = NexusItemLoading<String>();
        expect(state.isNotFound, isFalse);
      });
    });

    group('NexusItemLoaded', () {
      test('should have correct type', () {
        const state = NexusItemLoaded<String>(data: 'test');
        expect(state, isA<NexusItemState<String>>());
      });

      test('dataOrNull should return data', () {
        const state = NexusItemLoaded<String>(data: 'hello');
        expect(state.dataOrNull, equals('hello'));
      });

      test('data should return the data', () {
        const state = NexusItemLoaded<String>(data: 'hello');
        expect(state.data, equals('hello'));
      });

      test('isLoading should return false', () {
        const state = NexusItemLoaded<String>(data: 'test');
        expect(state.isLoading, isFalse);
      });

      test('hasData should return true', () {
        const state = NexusItemLoaded<String>(data: 'test');
        expect(state.hasData, isTrue);
      });

      test('hasError should return false', () {
        const state = NexusItemLoaded<String>(data: 'test');
        expect(state.hasError, isFalse);
      });

      test('isNotFound should return false', () {
        const state = NexusItemLoaded<String>(data: 'test');
        expect(state.isNotFound, isFalse);
      });
    });

    group('NexusItemNotFound', () {
      test('should have correct type', () {
        const state = NexusItemNotFound<String>();
        expect(state, isA<NexusItemState<String>>());
      });

      test('dataOrNull should return null', () {
        const state = NexusItemNotFound<String>();
        expect(state.dataOrNull, isNull);
      });

      test('isLoading should return false', () {
        const state = NexusItemNotFound<String>();
        expect(state.isLoading, isFalse);
      });

      test('hasData should return false', () {
        const state = NexusItemNotFound<String>();
        expect(state.hasData, isFalse);
      });

      test('hasError should return false', () {
        const state = NexusItemNotFound<String>();
        expect(state.hasError, isFalse);
      });

      test('isNotFound should return true', () {
        const state = NexusItemNotFound<String>();
        expect(state.isNotFound, isTrue);
      });
    });

    group('NexusItemError', () {
      test('should have correct type', () {
        final state = NexusItemError<String>(error: Exception('test'));
        expect(state, isA<NexusItemState<String>>());
      });

      test('dataOrNull should return null without previous data', () {
        final state = NexusItemError<String>(error: Exception('test'));
        expect(state.dataOrNull, isNull);
      });

      test('dataOrNull should return previous data when provided', () {
        final state = NexusItemError<String>(
          error: Exception('test'),
          previousData: 'previous',
        );
        expect(state.dataOrNull, equals('previous'));
      });

      test('isLoading should return false', () {
        final state = NexusItemError<String>(error: Exception('test'));
        expect(state.isLoading, isFalse);
      });

      test('hasData should return false without previous data', () {
        final state = NexusItemError<String>(error: Exception('test'));
        expect(state.hasData, isFalse);
      });

      test('hasData should return true with previous data', () {
        final state = NexusItemError<String>(
          error: Exception('test'),
          previousData: 'data',
        );
        expect(state.hasData, isTrue);
      });

      test('hasError should return true', () {
        final state = NexusItemError<String>(error: Exception('test'));
        expect(state.hasError, isTrue);
      });

      test('error should return the error', () {
        final error = Exception('test error');
        final state = NexusItemError<String>(error: error);
        expect(state.error, equals(error));
      });

      test('stackTrace should return the stack trace when provided', () {
        final stackTrace = StackTrace.current;
        final state = NexusItemError<String>(
          error: Exception('test'),
          stackTrace: stackTrace,
        );
        expect(state.stackTrace, equals(stackTrace));
      });

      test('stackTrace should return null when not provided', () {
        final state = NexusItemError<String>(error: Exception('test'));
        expect(state.stackTrace, isNull);
      });

      test('previousData should be accessible', () {
        final state = NexusItemError<String>(
          error: Exception('test'),
          previousData: 'prev',
        );
        expect(state.previousData, equals('prev'));
      });

      test('isNotFound should return false', () {
        final state = NexusItemError<String>(error: Exception('test'));
        expect(state.isNotFound, isFalse);
      });
    });

    group('when', () {
      test('should call initial for NexusItemInitial', () {
        const state = NexusItemInitial<String>();
        final result = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          loaded: (_) => 'loaded',
          notFound: () => 'notFound',
          error: (_, __, ___) => 'error',
        );
        expect(result, equals('initial'));
      });

      test('should call loading for NexusItemLoading', () {
        const state = NexusItemLoading<String>(previousData: 'prev');
        String? receivedPreviousData;
        state.when(
          initial: () {},
          loading: (prev) => receivedPreviousData = prev,
          loaded: (_) {},
          notFound: () {},
          error: (_, __, ___) {},
        );
        expect(receivedPreviousData, equals('prev'));
      });

      test('should call loaded for NexusItemLoaded', () {
        const state = NexusItemLoaded<String>(data: 'hello');
        String? receivedData;
        state.when(
          initial: () {},
          loading: (_) {},
          loaded: (data) => receivedData = data,
          notFound: () {},
          error: (_, __, ___) {},
        );
        expect(receivedData, equals('hello'));
      });

      test('should call notFound for NexusItemNotFound', () {
        const state = NexusItemNotFound<String>();
        final result = state.when(
          initial: () => 'initial',
          loading: (_) => 'loading',
          loaded: (_) => 'loaded',
          notFound: () => 'notFound',
          error: (_, __, ___) => 'error',
        );
        expect(result, equals('notFound'));
      });

      test('should call error for NexusItemError', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final state = NexusItemError<String>(
          error: error,
          stackTrace: stackTrace,
          previousData: 'prev',
        );
        Object? receivedError;
        StackTrace? receivedStackTrace;
        String? receivedPreviousData;
        state.when(
          initial: () {},
          loading: (_) {},
          loaded: (_) {},
          notFound: () {},
          error: (e, st, prev) {
            receivedError = e;
            receivedStackTrace = st;
            receivedPreviousData = prev;
          },
        );
        expect(receivedError, equals(error));
        expect(receivedStackTrace, equals(stackTrace));
        expect(receivedPreviousData, equals('prev'));
      });
    });

    group('maybeWhen', () {
      test('should call initial handler when provided', () {
        const state = NexusItemInitial<String>();
        final result = state.maybeWhen(
          initial: () => 'initial',
          orElse: () => 'orElse',
        );
        expect(result, equals('initial'));
      });

      test('should call orElse for initial when handler not provided', () {
        const state = NexusItemInitial<String>();
        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );
        expect(result, equals('orElse'));
      });

      test('should call loading handler when provided', () {
        const state = NexusItemLoading<String>(previousData: 'prev');
        String? receivedPreviousData;
        final result = state.maybeWhen(
          loading: (prev) {
            receivedPreviousData = prev;
            return 'loading';
          },
          orElse: () => 'orElse',
        );
        expect(result, equals('loading'));
        expect(receivedPreviousData, equals('prev'));
      });

      test('should call orElse for loading when handler not provided', () {
        const state = NexusItemLoading<String>();
        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );
        expect(result, equals('orElse'));
      });

      test('should call loaded handler when provided', () {
        const state = NexusItemLoaded<String>(data: 'hello');
        String? receivedData;
        final result = state.maybeWhen(
          loaded: (data) {
            receivedData = data;
            return 'loaded';
          },
          orElse: () => 'orElse',
        );
        expect(result, equals('loaded'));
        expect(receivedData, equals('hello'));
      });

      test('should call orElse for loaded when handler not provided', () {
        const state = NexusItemLoaded<String>(data: 'hello');
        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );
        expect(result, equals('orElse'));
      });

      test('should call notFound handler when provided', () {
        const state = NexusItemNotFound<String>();
        final result = state.maybeWhen(
          notFound: () => 'notFound',
          orElse: () => 'orElse',
        );
        expect(result, equals('notFound'));
      });

      test('should call orElse for notFound when handler not provided', () {
        const state = NexusItemNotFound<String>();
        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );
        expect(result, equals('orElse'));
      });

      test('should call error handler when provided', () {
        final error = Exception('test');
        final state = NexusItemError<String>(error: error);
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
        final state = NexusItemError<String>(error: Exception('test'));
        final result = state.maybeWhen(
          orElse: () => 'orElse',
        );
        expect(result, equals('orElse'));
      });
    });

    group('equality', () {
      test('NexusItemInitial instances should be equal', () {
        const state1 = NexusItemInitial<String>();
        const state2 = NexusItemInitial<String>();
        expect(state1, equals(state2));
      });

      test('NexusItemInitial non-identical instances should be equal', () {
        // Create non-const instances to cover the non-identical path
        // ignore: prefer_const_constructors
        final state1 = NexusItemInitial<String>();
        // ignore: prefer_const_constructors
        final state2 = NexusItemInitial<String>();
        expect(state1, equals(state2));
        expect(identical(state1, state2), isFalse);
      });

      test('NexusItemLoading instances with same data should be equal', () {
        const state1 = NexusItemLoading<String>(previousData: 'prev');
        const state2 = NexusItemLoading<String>(previousData: 'prev');
        expect(state1, equals(state2));
      });

      test('NexusItemLoading non-identical instances should be equal', () {
        // Create non-const instances to cover the non-identical path
        // ignore: prefer_const_constructors
        final state1 = NexusItemLoading<String>(previousData: 'prev');
        // ignore: prefer_const_constructors
        final state2 = NexusItemLoading<String>(previousData: 'prev');
        expect(state1, equals(state2));
        expect(identical(state1, state2), isFalse);
      });

      test('NexusItemLoading instances with different data should not be equal',
          () {
        const state1 = NexusItemLoading<String>(previousData: 'a');
        const state2 = NexusItemLoading<String>(previousData: 'b');
        expect(state1, isNot(equals(state2)));
      });

      test('NexusItemLoading with null vs value should not be equal', () {
        const state1 = NexusItemLoading<String>(previousData: null);
        const state2 = NexusItemLoading<String>(previousData: 'a');
        expect(state1, isNot(equals(state2)));
      });

      test('NexusItemLoaded instances with same data should be equal', () {
        const state1 = NexusItemLoaded<String>(data: 'hello');
        const state2 = NexusItemLoaded<String>(data: 'hello');
        expect(state1, equals(state2));
      });

      test('NexusItemLoaded non-identical instances should be equal', () {
        // Create non-const instances to cover the non-identical path
        // ignore: prefer_const_constructors
        final state1 = NexusItemLoaded<String>(data: 'hello');
        // ignore: prefer_const_constructors
        final state2 = NexusItemLoaded<String>(data: 'hello');
        expect(state1, equals(state2));
        expect(identical(state1, state2), isFalse);
      });

      test('NexusItemLoaded instances with different data should not be equal',
          () {
        const state1 = NexusItemLoaded<String>(data: 'a');
        const state2 = NexusItemLoaded<String>(data: 'b');
        expect(state1, isNot(equals(state2)));
      });

      test('NexusItemNotFound instances should be equal', () {
        const state1 = NexusItemNotFound<String>();
        const state2 = NexusItemNotFound<String>();
        expect(state1, equals(state2));
      });

      test('NexusItemNotFound non-identical instances should be equal', () {
        // Create non-const instances to cover the non-identical path
        // ignore: prefer_const_constructors
        final state1 = NexusItemNotFound<String>();
        // ignore: prefer_const_constructors
        final state2 = NexusItemNotFound<String>();
        expect(state1, equals(state2));
        expect(identical(state1, state2), isFalse);
      });

      test('NexusItemError instances with same error should be equal', () {
        final error = Exception('test');
        final state1 = NexusItemError<String>(error: error);
        final state2 = NexusItemError<String>(error: error);
        expect(state1, equals(state2));
      });

      test('NexusItemError instances with different errors should not be equal',
          () {
        final state1 = NexusItemError<String>(error: Exception('test1'));
        final state2 = NexusItemError<String>(error: Exception('test2'));
        expect(state1, isNot(equals(state2)));
      });

      test(
          'NexusItemError with same error but different stackTrace should not be equal',
          () {
        final error = Exception('test');
        final stackTrace1 = StackTrace.current;
        final state1 =
            NexusItemError<String>(error: error, stackTrace: stackTrace1);
        final state2 = NexusItemError<String>(error: error, stackTrace: null);
        expect(state1, isNot(equals(state2)));
      });

      test(
          'NexusItemError with same error but different previousData should not be equal',
          () {
        final error = Exception('test');
        final state1 = NexusItemError<String>(error: error, previousData: 'a');
        final state2 = NexusItemError<String>(error: error, previousData: 'b');
        expect(state1, isNot(equals(state2)));
      });

      test(
          'NexusItemError with same error and null vs value previousData should not be equal',
          () {
        final error = Exception('test');
        final state1 =
            NexusItemError<String>(error: error, previousData: null);
        final state2 = NexusItemError<String>(error: error, previousData: 'a');
        expect(state1, isNot(equals(state2)));
      });

      test('different state types should not be equal', () {
        const initial = NexusItemInitial<String>();
        const loading = NexusItemLoading<String>();
        const loaded = NexusItemLoaded<String>(data: 'test');
        const notFound = NexusItemNotFound<String>();
        final error = NexusItemError<String>(error: Exception('test'));

        expect(initial, isNot(equals(loading)));
        expect(initial, isNot(equals(loaded)));
        expect(initial, isNot(equals(notFound)));
        expect(initial, isNot(equals(error)));
        expect(loading, isNot(equals(loaded)));
        expect(loading, isNot(equals(notFound)));
        expect(loading, isNot(equals(error)));
        expect(loaded, isNot(equals(notFound)));
        expect(loaded, isNot(equals(error)));
        expect(notFound, isNot(equals(error)));
      });
    });

    group('hashCode', () {
      test('NexusItemInitial instances should have same hashCode', () {
        const state1 = NexusItemInitial<String>();
        const state2 = NexusItemInitial<String>();
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test(
          'NexusItemLoading instances with same data should have same hashCode',
          () {
        const state1 = NexusItemLoading<String>(previousData: 'prev');
        const state2 = NexusItemLoading<String>(previousData: 'prev');
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test(
          'NexusItemLoading with null vs value should have different hashCode',
          () {
        const state1 = NexusItemLoading<String>(previousData: null);
        const state2 = NexusItemLoading<String>(previousData: 'a');
        expect(state1.hashCode, isNot(equals(state2.hashCode)));
      });

      test('NexusItemLoaded instances with same data should have same hashCode',
          () {
        const state1 = NexusItemLoaded<String>(data: 'hello');
        const state2 = NexusItemLoaded<String>(data: 'hello');
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('NexusItemNotFound instances should have same hashCode', () {
        const state1 = NexusItemNotFound<String>();
        const state2 = NexusItemNotFound<String>();
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('NexusItemError with same parameters should have same hashCode',
          () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;
        final state1 = NexusItemError<String>(
          error: error,
          stackTrace: stackTrace,
          previousData: 'prev',
        );
        final state2 = NexusItemError<String>(
          error: error,
          stackTrace: stackTrace,
          previousData: 'prev',
        );
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test(
          'NexusItemError with different stackTrace should have different hashCode',
          () {
        final error = Exception('test');
        final stackTrace1 = StackTrace.current;
        final state1 =
            NexusItemError<String>(error: error, stackTrace: stackTrace1);
        final state2 = NexusItemError<String>(error: error, stackTrace: null);
        expect(state1.hashCode, isNot(equals(state2.hashCode)));
      });

      test(
          'NexusItemError with different previousData should have different hashCode',
          () {
        final error = Exception('test');
        final state1 = NexusItemError<String>(error: error, previousData: 'a');
        final state2 = NexusItemError<String>(error: error, previousData: 'b');
        expect(state1.hashCode, isNot(equals(state2.hashCode)));
      });
    });

    group('toString', () {
      test('NexusItemInitial should have readable toString', () {
        const state = NexusItemInitial<String>();
        expect(state.toString(), contains('NexusItemInitial'));
      });

      test('NexusItemLoading should have readable toString', () {
        const state = NexusItemLoading<String>(previousData: 'prev');
        expect(state.toString(), contains('NexusItemLoading'));
      });

      test('NexusItemLoading toString includes previousData value', () {
        const state = NexusItemLoading<String>(previousData: 'test_value');
        final str = state.toString();
        expect(str, contains('previousData'));
        expect(str, contains('test_value'));
      });

      test('NexusItemLoading toString shows null previousData', () {
        const state = NexusItemLoading<String>();
        expect(state.toString(), contains('previousData: null'));
      });

      test('NexusItemLoaded should have readable toString', () {
        const state = NexusItemLoaded<String>(data: 'hello');
        expect(state.toString(), contains('NexusItemLoaded'));
      });

      test('NexusItemLoaded toString includes data value', () {
        const state = NexusItemLoaded<String>(data: 'my_data');
        final str = state.toString();
        expect(str, contains('data'));
        expect(str, contains('my_data'));
      });

      test('NexusItemNotFound should have readable toString', () {
        const state = NexusItemNotFound<String>();
        expect(state.toString(), contains('NexusItemNotFound'));
      });

      test('NexusItemError should have readable toString', () {
        final state = NexusItemError<String>(error: Exception('test'));
        expect(state.toString(), contains('NexusItemError'));
      });

      test('NexusItemError toString includes all field values', () {
        final stackTrace = StackTrace.current;
        final state = NexusItemError<String>(
          error: Exception('test error'),
          stackTrace: stackTrace,
          previousData: 'previous_item',
        );
        final str = state.toString();
        expect(str, contains('error'));
        expect(str, contains('test error'));
        expect(str, contains('stackTrace'));
        expect(str, contains('previousData'));
        expect(str, contains('previous_item'));
      });

      test('NexusItemError toString shows null fields', () {
        final state = NexusItemError<String>(error: Exception('test'));
        final str = state.toString();
        expect(str, contains('stackTrace: null'));
        expect(str, contains('previousData: null'));
      });
    });
  });
}
