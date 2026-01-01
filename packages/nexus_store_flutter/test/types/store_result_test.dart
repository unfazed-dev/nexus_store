import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter/nexus_store_flutter.dart';

void main() {
  group('StoreResult', () {
    group('StoreResultIdle', () {
      test('creates idle result', () {
        const result = StoreResult<String>.idle();

        expect(result, isA<StoreResultIdle<String>>());
        expect(result.hasData, isFalse);
        expect(result.data, isNull);
        expect(result.isLoading, isFalse);
        expect(result.hasError, isFalse);
        expect(result.error, isNull);
      });

      test('when() calls idle callback', () {
        const result = StoreResult<String>.idle();

        final value = result.when(
          idle: () => 'idle',
          pending: (_) => 'pending',
          success: (_) => 'success',
          error: (_, __) => 'error',
        );

        expect(value, 'idle');
      });

      test('maybeWhen() calls idle callback when provided', () {
        const result = StoreResult<String>.idle();

        final value = result.maybeWhen(
          idle: () => 'idle',
          orElse: () => 'orElse',
        );

        expect(value, 'idle');
      });

      test('maybeWhen() calls orElse when idle not provided', () {
        const result = StoreResult<String>.idle();

        final value = result.maybeWhen(
          success: (_) => 'success',
          orElse: () => 'orElse',
        );

        expect(value, 'orElse');
      });

      test('map() returns idle result', () {
        const result = StoreResult<int>.idle();

        final mapped = result.map((data) => data.toString());

        expect(mapped, isA<StoreResultIdle<String>>());
      });

      test('copyWith() with data returns success', () {
        const result = StoreResult<String>.idle();

        final copied = result.copyWith(data: 'hello');

        expect(copied, isA<StoreResultSuccess<String>>());
        expect(copied.data, 'hello');
      });

      test('copyWith() with error returns error', () {
        const result = StoreResult<String>.idle();

        final copied = result.copyWith(error: Exception('test'));

        expect(copied, isA<StoreResultError<String>>());
        expect(copied.error, isA<Exception>());
      });

      test('equality works', () {
        const result1 = StoreResult<String>.idle();
        const result2 = StoreResult<String>.idle();
        const result3 = StoreResult<int>.idle();

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
        expect(result1, isNot(equals(result3)));
      });

      test('toString returns readable format', () {
        const result = StoreResult<String>.idle();

        expect(result.toString(), 'StoreResult<String>.idle()');
      });
    });

    group('StoreResultPending', () {
      test('creates pending result without previous data', () {
        const result = StoreResult<String>.pending();

        expect(result, isA<StoreResultPending<String>>());
        expect(result.hasData, isFalse);
        expect(result.data, isNull);
        expect(result.isLoading, isTrue);
        expect(result.hasError, isFalse);
      });

      test('creates pending result with previous data', () {
        const result = StoreResult<String>.pending('previous');

        expect(result.hasData, isTrue);
        expect(result.data, 'previous');
        expect(result.isLoading, isTrue);
      });

      test('when() calls pending callback with previous data', () {
        const result = StoreResult<String>.pending('previous');

        final value = result.when(
          idle: () => 'idle',
          pending: (prev) => 'pending:$prev',
          success: (_) => 'success',
          error: (_, __) => 'error',
        );

        expect(value, 'pending:previous');
      });

      test('map() transforms previous data', () {
        const result = StoreResult<int>.pending(42);

        final mapped = result.map((data) => data.toString());

        expect(mapped, isA<StoreResultPending<String>>());
        expect(mapped.data, '42');
      });

      test('map() with null previous data returns pending with null', () {
        const result = StoreResult<int>.pending();

        final mapped = result.map((data) => data.toString());

        expect(mapped, isA<StoreResultPending<String>>());
        expect(mapped.data, isNull);
      });

      test('copyWith() preserves previous data', () {
        const result = StoreResult<String>.pending('old');

        final copied = result.copyWith();

        expect(copied.data, 'old');
      });

      test('equality works with previous data', () {
        const result1 = StoreResult<String>.pending('data');
        const result2 = StoreResult<String>.pending('data');
        const result3 = StoreResult<String>.pending('other');
        const result4 = StoreResult<String>.pending();

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
        expect(result1, isNot(equals(result4)));
      });

      test('hashCode is consistent for equal results', () {
        const result1 = StoreResult<String>.pending('data');
        const result2 = StoreResult<String>.pending('data');

        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('maybeWhen() calls orElse when pending not provided', () {
        const result = StoreResult<String>.pending('data');

        final value = result.maybeWhen(
          success: (_) => 'success',
          orElse: () => 'orElse',
        );

        expect(value, 'orElse');
      });

      test('copyWith() with error returns error preserving data', () {
        const result = StoreResult<String>.pending('previous');

        final copied = result.copyWith(error: Exception('test'));

        expect(copied, isA<StoreResultError<String>>());
        expect(copied.data, 'previous');
        expect(copied.hasError, isTrue);
      });

      test('copyWith() with both data and error returns error with new data',
          () {
        const result = StoreResult<String>.pending('previous');

        final copied = result.copyWith(data: 'new', error: Exception('test'));

        expect(copied, isA<StoreResultError<String>>());
        expect(copied.data, 'new');
      });

      test('toString returns readable format', () {
        const result = StoreResult<String>.pending('data');

        expect(result.toString(), 'StoreResult<String>.pending(data)');
      });

      test('toString returns readable format without data', () {
        const result = StoreResult<String>.pending();

        expect(result.toString(), 'StoreResult<String>.pending(null)');
      });
    });

    group('StoreResultSuccess', () {
      test('creates success result with data', () {
        const result = StoreResult<String>.success('hello');

        expect(result, isA<StoreResultSuccess<String>>());
        expect(result.hasData, isTrue);
        expect(result.data, 'hello');
        expect(result.isLoading, isFalse);
        expect(result.hasError, isFalse);
      });

      test('when() calls success callback with data', () {
        const result = StoreResult<String>.success('hello');

        final value = result.when(
          idle: () => 'idle',
          pending: (_) => 'pending',
          success: (data) => 'success:$data',
          error: (_, __) => 'error',
        );

        expect(value, 'success:hello');
      });

      test('map() transforms data', () {
        const result = StoreResult<int>.success(42);

        final mapped = result.map((data) => data.toString());

        expect(mapped, isA<StoreResultSuccess<String>>());
        expect(mapped.data, '42');
      });

      test('copyWith() with new data replaces data', () {
        const result = StoreResult<String>.success('old');

        final copied = result.copyWith(data: 'new');

        expect(copied.data, 'new');
      });

      test('copyWith() with error returns error with data', () {
        const result = StoreResult<String>.success('data');

        final copied = result.copyWith(error: Exception('test'));

        expect(copied, isA<StoreResultError<String>>());
        expect(copied.data, 'data');
      });

      test('equality works', () {
        const result1 = StoreResult<String>.success('hello');
        const result2 = StoreResult<String>.success('hello');
        const result3 = StoreResult<String>.success('world');

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
        expect(result1, isNot(equals(result3)));
      });

      test('maybeWhen() calls orElse when success not provided', () {
        const result = StoreResult<String>.success('hello');

        final value = result.maybeWhen(
          pending: (_) => 'pending',
          orElse: () => 'orElse',
        );

        expect(value, 'orElse');
      });

      test('copyWith() with both data and error returns error with new data',
          () {
        const result = StoreResult<String>.success('old');

        final copied = result.copyWith(data: 'new', error: Exception('test'));

        expect(copied, isA<StoreResultError<String>>());
        expect(copied.data, 'new');
      });

      test('toString returns readable format', () {
        const result = StoreResult<String>.success('hello');

        expect(result.toString(), 'StoreResult<String>.success(hello)');
      });
    });

    group('StoreResultError', () {
      test('creates error result without previous data', () {
        final error = Exception('test error');
        final result = StoreResult<String>.error(error);

        expect(result, isA<StoreResultError<String>>());
        expect(result.hasData, isFalse);
        expect(result.data, isNull);
        expect(result.isLoading, isFalse);
        expect(result.hasError, isTrue);
        expect(result.error, error);
      });

      test('creates error result with previous data', () {
        final error = Exception('test error');
        final result = StoreResult<String>.error(error, 'previous');

        expect(result.hasData, isTrue);
        expect(result.data, 'previous');
        expect(result.hasError, isTrue);
        expect(result.error, error);
      });

      test('when() calls error callback', () {
        final error = Exception('test');
        final result = StoreResult<String>.error(error, 'prev');

        final value = result.when(
          idle: () => 'idle',
          pending: (_) => 'pending',
          success: (_) => 'success',
          error: (err, prev) => 'error:$err:$prev',
        );

        expect(value, contains('error:'));
        expect(value, contains('prev'));
      });

      test('map() transforms previous data', () {
        final result = StoreResult<int>.error(Exception('test'), 42);

        final mapped = result.map((data) => data.toString());

        expect(mapped, isA<StoreResultError<String>>());
        expect(mapped.data, '42');
      });

      test('equality works', () {
        final error = Exception('test');
        final result1 = StoreResult<String>.error(error, 'prev');
        final result2 = StoreResult<String>.error(error, 'prev');
        final result3 = StoreResult<String>.error(error, 'other');

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('hashCode is consistent for equal results', () {
        final error = Exception('test');
        final result1 = StoreResult<String>.error(error, 'prev');
        final result2 = StoreResult<String>.error(error, 'prev');

        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('maybeWhen() calls orElse when error not provided', () {
        final result = StoreResult<String>.error(Exception('test'));

        final value = result.maybeWhen(
          success: (_) => 'success',
          orElse: () => 'orElse',
        );

        expect(value, 'orElse');
      });

      test('map() with null previous data returns error with null', () {
        final result = StoreResult<int>.error(Exception('test'));

        final mapped = result.map((data) => data.toString());

        expect(mapped, isA<StoreResultError<String>>());
        expect(mapped.data, isNull);
      });

      test('copyWith() updates error', () {
        final result = StoreResult<String>.error(Exception('old'), 'data');

        final copied = result.copyWith(error: Exception('new'));

        expect(copied, isA<StoreResultError<String>>());
        expect(copied.error.toString(), contains('new'));
        expect(copied.data, 'data');
      });

      test('copyWith() updates data', () {
        final result = StoreResult<String>.error(Exception('test'), 'old');

        final copied = result.copyWith(data: 'new');

        expect(copied, isA<StoreResultError<String>>());
        expect(copied.data, 'new');
      });

      test('toString returns readable format', () {
        final error = Exception('test');
        final result = StoreResult<String>.error(error, 'data');

        expect(result.toString(), contains('StoreResult<String>.error'));
        expect(result.toString(), contains('data'));
      });

      test('toString returns readable format without data', () {
        final error = Exception('test');
        final result = StoreResult<String>.error(error);

        expect(result.toString(), contains('StoreResult<String>.error'));
        expect(result.toString(), contains('null'));
      });
    });

    group('StoreResultExtensions', () {
      test('dataOr returns data when available', () {
        const result = StoreResult<String>.success('hello');

        expect(result.dataOr('default'), 'hello');
      });

      test('dataOr returns default when no data', () {
        const result = StoreResult<String>.idle();

        expect(result.dataOr('default'), 'default');
      });

      test('requireData returns data when successful', () {
        const result = StoreResult<String>.success('hello');

        expect(result.requireData(), 'hello');
      });

      test('requireData throws error when error state', () {
        final result = StoreResult<String>.error(Exception('test'));

        expect(result.requireData, throwsException);
      });

      test('requireData throws StateError when idle', () {
        const result = StoreResult<String>.idle();

        expect(() => result.requireData(), throwsStateError);
      });

      test('requireData rethrows Error directly when error is Error', () {
        final result = StoreResult<String>.error(ArgumentError('test'));

        expect(result.requireData, throwsArgumentError);
      });

      test('requireData wraps in Exception when error is plain Object', () {
        const result = StoreResult<String>.error('plain string error');

        expect(
          result.requireData,
          throwsA(isA<Exception>()),
        );
      });

      test('requireData throws StateError when pending without data', () {
        const result = StoreResult<String>.pending();

        expect(() => result.requireData(), throwsStateError);
      });

      test('toNullable returns data when successful', () {
        const result = StoreResult<String>.success('hello');

        expect(result.toNullable(), 'hello');
      });

      test('toNullable returns null when not successful', () {
        const result = StoreResult<String>.pending();

        expect(result.toNullable(), isNull);
      });

      test('isIdle returns true for idle state', () {
        const result = StoreResult<String>.idle();

        expect(result.isIdle, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('isSuccess returns true for success state', () {
        const result = StoreResult<String>.success('hello');

        expect(result.isSuccess, isTrue);
        expect(result.isIdle, isFalse);
      });

      test('isRefreshing returns true when pending with data', () {
        const result = StoreResult<String>.pending('previous');

        expect(result.isRefreshing, isTrue);
      });

      test('isRefreshing returns false when pending without data', () {
        const result = StoreResult<String>.pending();

        expect(result.isRefreshing, isFalse);
      });
    });
  });
}
