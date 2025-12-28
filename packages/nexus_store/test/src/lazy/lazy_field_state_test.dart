import 'package:nexus_store/src/lazy/lazy_field_state.dart';
import 'package:test/test.dart';

void main() {
  group('LazyFieldState', () {
    test('has notLoaded state', () {
      expect(LazyFieldState.notLoaded, isNotNull);
      expect(LazyFieldState.notLoaded.name, equals('notLoaded'));
    });

    test('has loading state', () {
      expect(LazyFieldState.loading, isNotNull);
      expect(LazyFieldState.loading.name, equals('loading'));
    });

    test('has loaded state', () {
      expect(LazyFieldState.loaded, isNotNull);
      expect(LazyFieldState.loaded.name, equals('loaded'));
    });

    test('has error state', () {
      expect(LazyFieldState.error, isNotNull);
      expect(LazyFieldState.error.name, equals('error'));
    });

    test('values contains all states', () {
      expect(
        LazyFieldState.values,
        containsAll([
          LazyFieldState.notLoaded,
          LazyFieldState.loading,
          LazyFieldState.loaded,
          LazyFieldState.error,
        ]),
      );
      expect(LazyFieldState.values.length, equals(4));
    });
  });
}
