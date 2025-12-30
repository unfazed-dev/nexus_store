import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store_signals_binding/src/lifecycle/signal_scope.dart';

import 'fixtures/mock_store.dart';
import 'fixtures/test_entities.dart';

void main() {
  setUpAll(() {
    registerFallbackValues();
  });

  group('SignalScope', () {
    test('tracks created signals', () {
      final scope = SignalScope();

      final signal1 = scope.createSignal(0);
      final signal2 = scope.createSignal('test');

      expect(scope.signalCount, equals(2));
      expect(signal1.value, equals(0));
      expect(signal2.value, equals('test'));
    });

    test('disposeAll disposes all tracked signals', () {
      final scope = SignalScope();

      final signal1 = scope.createSignal(0);
      final signal2 = scope.createSignal('test');

      expect(signal1.disposed, isFalse);
      expect(signal2.disposed, isFalse);

      scope.disposeAll();

      expect(signal1.disposed, isTrue);
      expect(signal2.disposed, isTrue);
      expect(scope.signalCount, equals(0));
    });

    test('createComputed tracks computed signals', () {
      final scope = SignalScope();

      final source = scope.createSignal(testUsers);
      final count = scope.createComputed(() => source.value.length);

      expect(count.value, equals(3));
      expect(scope.signalCount, equals(2));
    });

    test('disposeAll disposes computed signals', () {
      final scope = SignalScope();

      final source = scope.createSignal(testUsers);
      final count = scope.createComputed(() => source.value.length);

      scope.disposeAll();

      expect(source.disposed, isTrue);
      expect(count.disposed, isTrue);
    });

    test('createFromStore tracks store signals', () {
      final mockStore = MockNexusStore<TestUser, String>();
      final controller = StreamController<List<TestUser>>.broadcast();
      when(() => mockStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => controller.stream);

      final scope = SignalScope();
      final storeSignal = scope.createFromStore(mockStore);

      expect(storeSignal.value, isEmpty);
      expect(scope.signalCount, equals(1));

      scope.disposeAll();
      controller.close();
    });

    test('double dispose is safe', () {
      final scope = SignalScope();
      scope.createSignal(0);

      scope.disposeAll();
      expect(() => scope.disposeAll(), returnsNormally);
    });

    test('isDisposed returns correct state', () {
      final scope = SignalScope();
      scope.createSignal(0);

      expect(scope.isDisposed, isFalse);

      scope.disposeAll();

      expect(scope.isDisposed, isTrue);
    });
  });
}
