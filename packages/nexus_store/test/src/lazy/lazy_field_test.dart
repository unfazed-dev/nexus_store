import 'dart:async';

import 'package:nexus_store/src/lazy/lazy_field.dart';
import 'package:nexus_store/src/lazy/lazy_field_state.dart';
import 'package:test/test.dart';

void main() {
  group('LazyField', () {
    group('creation', () {
      test('starts in notLoaded state', () {
        final field = LazyField<String>(
          loader: () async => 'value',
        );

        expect(field.state, equals(LazyFieldState.notLoaded));
        expect(field.isLoaded, isFalse);
        expect(field.isLoading, isFalse);
      });

      test('stores placeholder value', () {
        final field = LazyField<String>(
          placeholder: 'placeholder',
          loader: () async => 'value',
        );

        expect(field.placeholder, equals('placeholder'));
      });

      test('value returns placeholder when not loaded', () {
        final field = LazyField<String>(
          placeholder: 'placeholder',
          loader: () async => 'actual',
        );

        expect(field.value, equals('placeholder'));
      });

      test('value returns null when no placeholder and not loaded', () {
        final field = LazyField<String>(
          loader: () async => 'actual',
        );

        expect(field.value, isNull);
      });

      test('can be created with initial loaded value', () {
        final field = LazyField<String>.loaded('initial value');

        expect(field.state, equals(LazyFieldState.loaded));
        expect(field.isLoaded, isTrue);
        expect(field.value, equals('initial value'));
      });
    });

    group('requireValue', () {
      test('throws StateError when not loaded', () {
        final field = LazyField<String>(
          loader: () async => 'value',
        );

        expect(() => field.requireValue, throwsStateError);
      });

      test('returns value when loaded', () async {
        final field = LazyField<String>(
          loader: () async => 'loaded value',
        );

        await field.load();

        expect(field.requireValue, equals('loaded value'));
      });
    });

    group('load', () {
      test('calls loader function', () async {
        var loadCalled = false;
        final field = LazyField<String>(
          loader: () async {
            loadCalled = true;
            return 'value';
          },
        );

        await field.load();

        expect(loadCalled, isTrue);
      });

      test('transitions to loading state during load', () async {
        final completer = Completer<String>();
        final field = LazyField<String>(
          loader: () => completer.future,
        );

        final loadFuture = field.load();

        expect(field.state, equals(LazyFieldState.loading));
        expect(field.isLoading, isTrue);

        completer.complete('value');
        await loadFuture;

        expect(field.state, equals(LazyFieldState.loaded));
        expect(field.isLoading, isFalse);
      });

      test('returns loaded value', () async {
        final field = LazyField<String>(
          loader: () async => 'loaded value',
        );

        final result = await field.load();

        expect(result, equals('loaded value'));
      });

      test('updates value after load', () async {
        final field = LazyField<String>(
          placeholder: 'placeholder',
          loader: () async => 'actual value',
        );

        expect(field.value, equals('placeholder'));

        await field.load();

        expect(field.value, equals('actual value'));
        expect(field.isLoaded, isTrue);
      });

      test('returns cached value on subsequent loads', () async {
        var loadCount = 0;
        final field = LazyField<String>(
          loader: () async {
            loadCount++;
            return 'value';
          },
        );

        await field.load();
        await field.load();
        await field.load();

        expect(loadCount, equals(1));
      });

      test('returns same future for concurrent load calls', () async {
        final completer = Completer<String>();
        var loadCount = 0;
        final field = LazyField<String>(
          loader: () {
            loadCount++;
            return completer.future;
          },
        );

        final future1 = field.load();
        final future2 = field.load();
        final future3 = field.load();

        expect(identical(future1, future2), isTrue);
        expect(identical(future2, future3), isTrue);

        completer.complete('value');
        await Future.wait([future1, future2, future3]);

        expect(loadCount, equals(1));
      });
    });

    group('error handling', () {
      test('transitions to error state on failure', () async {
        final field = LazyField<String>(
          loader: () async => throw Exception('Load failed'),
        );

        try {
          await field.load();
        } catch (_) {}

        expect(field.state, equals(LazyFieldState.error));
        expect(field.isLoaded, isFalse);
      });

      test('stores error message on failure', () async {
        final field = LazyField<String>(
          loader: () async => throw Exception('Load failed'),
        );

        try {
          await field.load();
        } catch (_) {}

        expect(field.errorMessage, contains('Load failed'));
      });

      test('rethrows exception from load', () async {
        final field = LazyField<String>(
          loader: () async => throw Exception('Load failed'),
        );

        expect(
          () => field.load(),
          throwsA(isA<Exception>()),
        );
      });

      test('can retry after error', () async {
        var attemptCount = 0;
        final field = LazyField<String>(
          loader: () async {
            attemptCount++;
            if (attemptCount == 1) {
              throw Exception('First attempt failed');
            }
            return 'success';
          },
        );

        try {
          await field.load();
        } catch (_) {}

        expect(field.state, equals(LazyFieldState.error));

        field.reset();
        final result = await field.load();

        expect(result, equals('success'));
        expect(field.state, equals(LazyFieldState.loaded));
      });
    });

    group('reset', () {
      test('resets loaded field to notLoaded state', () async {
        final field = LazyField<String>(
          loader: () async => 'value',
        );

        await field.load();
        expect(field.isLoaded, isTrue);

        field.reset();

        expect(field.state, equals(LazyFieldState.notLoaded));
        expect(field.isLoaded, isFalse);
      });

      test('clears loaded value', () async {
        final field = LazyField<String>(
          placeholder: 'placeholder',
          loader: () async => 'loaded value',
        );

        await field.load();
        expect(field.value, equals('loaded value'));

        field.reset();

        expect(field.value, equals('placeholder'));
      });

      test('clears error message', () async {
        final field = LazyField<String>(
          loader: () async => throw Exception('Error'),
        );

        try {
          await field.load();
        } catch (_) {}

        expect(field.errorMessage, isNotNull);

        field.reset();

        expect(field.errorMessage, isNull);
      });

      test('allows reloading after reset', () async {
        var loadCount = 0;
        final field = LazyField<String>(
          loader: () async {
            loadCount++;
            return 'value $loadCount';
          },
        );

        final first = await field.load();
        expect(first, equals('value 1'));

        field.reset();

        final second = await field.load();
        expect(second, equals('value 2'));
        expect(loadCount, equals(2));
      });
    });

    group('hasError', () {
      test('returns false when not in error state', () {
        final field = LazyField<String>(
          loader: () async => 'value',
        );

        expect(field.hasError, isFalse);
      });

      test('returns true when in error state', () async {
        final field = LazyField<String>(
          loader: () async => throw Exception('Error'),
        );

        try {
          await field.load();
        } catch (_) {}

        expect(field.hasError, isTrue);
      });
    });
  });
}
