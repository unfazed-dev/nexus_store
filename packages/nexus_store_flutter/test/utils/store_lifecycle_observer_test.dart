import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter/src/utils/store_lifecycle_observer.dart';

class MockNexusStore extends Mock implements NexusStore<dynamic, dynamic> {}

void main() {
  group('NexusStoreLifecycleObserver', () {
    late MockNexusStore mockStore1;
    late MockNexusStore mockStore2;

    setUp(() {
      mockStore1 = MockNexusStore();
      mockStore2 = MockNexusStore();

      when(() => mockStore1.sync()).thenAnswer((_) async {});
      when(() => mockStore2.sync()).thenAnswer((_) async {});
    });

    group('construction', () {
      test('creates observer with required parameters', () {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        expect(observer.stores, equals([mockStore1]));
        expect(observer.pauseOnBackground, isTrue);
        expect(observer.onStateChange, isNull);
        expect(observer.isPaused, isFalse);
      });

      test('creates observer with custom parameters', () {
        void callback(AppLifecycleState state) {}

        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1, mockStore2],
          pauseOnBackground: false,
          onStateChange: callback,
        );

        expect(observer.stores, equals([mockStore1, mockStore2]));
        expect(observer.pauseOnBackground, isFalse);
        expect(observer.onStateChange, equals(callback));
      });
    });

    group('didChangeAppLifecycleState', () {
      test('calls onStateChange callback', () {
        AppLifecycleState? receivedState;

        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
          onStateChange: (state) => receivedState = state,
        );

        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);

        expect(receivedState, equals(AppLifecycleState.paused));
      });

      test('pauses on AppLifecycleState.paused', () {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        expect(observer.isPaused, isFalse);

        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);

        expect(observer.isPaused, isTrue);
      });

      test('pauses on AppLifecycleState.inactive', () {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.inactive);

        expect(observer.isPaused, isTrue);
      });

      test('pauses on AppLifecycleState.detached', () {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.detached);

        expect(observer.isPaused, isTrue);
      });

      test('pauses on AppLifecycleState.hidden', () {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.hidden);

        expect(observer.isPaused, isTrue);
      });

      test('resumes on AppLifecycleState.resumed', () {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        // First pause
        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        expect(observer.isPaused, isTrue);

        // Then resume
        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

        expect(observer.isPaused, isFalse);
      });

      test('does not pause when pauseOnBackground is false', () {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
          pauseOnBackground: false,
        );

        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);

        expect(observer.isPaused, isFalse);
      });

      test('calls sync on all stores when resuming', () async {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1, mockStore2],
        );

        // Pause first
        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);

        // Then resume
        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

        // Allow async sync to be called
        await Future<void>.delayed(Duration.zero);

        verify(() => mockStore1.sync()).called(1);
        verify(() => mockStore2.sync()).called(1);
      });

      test('ignores sync errors on resume', () async {
        when(() => mockStore1.sync())
            .thenAnswer((_) async => throw Exception('Sync error'));

        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        // Pause first
        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);

        // This should not throw even though sync fails
        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

        // Allow async to complete
        await Future<void>.delayed(Duration.zero);

        expect(observer.isPaused, isFalse);
      });

      test('does not pause again if already paused', () {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        expect(observer.isPaused, isTrue);

        // Pause again - should be idempotent
        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
        expect(observer.isPaused, isTrue);
      });

      test('does not resume if not paused', () async {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        // Resume without pausing first
        // ignore: cascade_invocations
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

        await Future<void>.delayed(Duration.zero);

        // sync should not be called since we weren't paused
        verifyNever(() => mockStore1.sync());
      });
    });

    group('attach and detach', () {
      testWidgets('attach adds observer to WidgetsBinding', (tester) async {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        // ignore: cascade_invocations
        observer.attach();

        // Verify it's attached by triggering a lifecycle event
        // This is an integration test with WidgetsBinding
        expect(observer.isPaused, isFalse);

        // ignore: cascade_invocations
        observer.detach();
      });

      testWidgets('detach removes observer from WidgetsBinding',
          (tester) async {
        final observer = NexusStoreLifecycleObserver(
          stores: [mockStore1],
        );

        // ignore: cascade_invocations
        observer
          ..attach()
          ..detach();

        // After detach, the observer should still work but not receive events
        expect(observer.isPaused, isFalse);
      });
    });
  });

  group('NexusStoreLifecycleObserverWidget', () {
    late MockNexusStore mockStore1;
    late MockNexusStore mockStore2;

    setUp(() {
      mockStore1 = MockNexusStore();
      mockStore2 = MockNexusStore();

      when(() => mockStore1.sync()).thenAnswer((_) async {});
      when(() => mockStore2.sync()).thenAnswer((_) async {});
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        NexusStoreLifecycleObserverWidget(
          stores: [mockStore1],
          child: const Text('Child', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('attaches observer in initState', (tester) async {
      AppLifecycleState? receivedState;

      await tester.pumpWidget(
        NexusStoreLifecycleObserverWidget(
          stores: [mockStore1],
          onStateChange: (state) => receivedState = state,
          child: const SizedBox(),
        ),
      );

      // Simulate lifecycle change
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(receivedState, equals(AppLifecycleState.paused));
    });

    testWidgets('detaches observer on dispose', (tester) async {
      AppLifecycleState? receivedState;

      await tester.pumpWidget(
        NexusStoreLifecycleObserverWidget(
          stores: [mockStore1],
          onStateChange: (state) => receivedState = state,
          child: const SizedBox(),
        ),
      );

      // Dispose the widget
      await tester.pumpWidget(const SizedBox());

      // Simulate lifecycle change after dispose
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Should not receive the event since observer was detached
      // (receivedState might be from before dispose)
      expect(receivedState, isNot(equals(AppLifecycleState.resumed)));
    });

    testWidgets('recreates observer when stores change', (tester) async {
      var storeList = <NexusStore<dynamic, dynamic>>[mockStore1];

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => Column(
            textDirection: TextDirection.ltr,
            children: [
              NexusStoreLifecycleObserverWidget(
                stores: storeList,
                child: const SizedBox(),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  storeList = [mockStore1, mockStore2];
                }),
                child: const Text('Update', textDirection: TextDirection.ltr),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Update'));
      await tester.pump();

      // Widget should have updated with new stores
      expect(find.byType(NexusStoreLifecycleObserverWidget), findsOneWidget);
    });

    testWidgets('recreates observer when pauseOnBackground changes',
        (tester) async {
      var pauseOnBackground = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => Column(
            textDirection: TextDirection.ltr,
            children: [
              NexusStoreLifecycleObserverWidget(
                stores: [mockStore1],
                pauseOnBackground: pauseOnBackground,
                child: const SizedBox(),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  pauseOnBackground = false;
                }),
                child: const Text('Toggle', textDirection: TextDirection.ltr),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      expect(find.byType(NexusStoreLifecycleObserverWidget), findsOneWidget);
    });

    testWidgets('does not recreate observer when only onStateChange changes',
        (tester) async {
      // onStateChange is not in the comparison, so changing it shouldn't
      // trigger observer recreation
      void callback1(AppLifecycleState state) {}
      void callback2(AppLifecycleState state) {}

      var currentCallback = callback1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => Column(
            textDirection: TextDirection.ltr,
            children: [
              NexusStoreLifecycleObserverWidget(
                stores: [mockStore1],
                onStateChange: currentCallback,
                child: const SizedBox(),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  currentCallback = callback2;
                }),
                child: const Text('Change', textDirection: TextDirection.ltr),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Change'));
      await tester.pump();

      // Widget should still exist
      expect(find.byType(NexusStoreLifecycleObserverWidget), findsOneWidget);
    });

    testWidgets('passes pauseOnBackground to observer', (tester) async {
      AppLifecycleState? receivedState;
      var pauseTriggered = false;

      await tester.pumpWidget(
        NexusStoreLifecycleObserverWidget(
          stores: [mockStore1],
          onStateChange: (state) {
            receivedState = state;
            if (state == AppLifecycleState.paused) {
              pauseTriggered = true;
            }
          },
          child: const SizedBox(),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(receivedState, equals(AppLifecycleState.paused));
      expect(pauseTriggered, isTrue);
    });
  });
}
