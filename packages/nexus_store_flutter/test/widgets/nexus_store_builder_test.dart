import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter/nexus_store_flutter.dart';

class MockNexusStore<T, ID> extends Mock implements NexusStore<T, ID> {}

class TestModel {
  const TestModel({required this.id, required this.name});

  final String id;
  final String name;

  @override
  String toString() => 'TestModel($id, $name)';
}

void main() {
  group('NexusStoreBuilder', () {
    late MockNexusStore<TestModel, String> mockStore;
    late StreamController<List<TestModel>> streamController;

    setUp(() {
      mockStore = MockNexusStore<TestModel, String>();
      streamController = StreamController<List<TestModel>>.broadcast();

      when(() => mockStore.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => streamController.stream);
    });

    tearDown(() {
      streamController.close();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreBuilder<TestModel, String>(
            store: mockStore,
            builder: (context, items) => Text('Count: ${items.length}'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows custom loading widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreBuilder<TestModel, String>(
            store: mockStore,
            builder: (context, items) => Text('Count: ${items.length}'),
            loading: const Text('Custom Loading'),
          ),
        ),
      );

      expect(find.text('Custom Loading'), findsOneWidget);
    });

    testWidgets('renders items when stream emits', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreBuilder<TestModel, String>(
            store: mockStore,
            builder: (context, items) => Column(
              children: items.map((i) => Text(i.name)).toList(),
            ),
          ),
        ),
      );

      streamController.add([
        const TestModel(id: '1', name: 'Alice'),
        const TestModel(id: '2', name: 'Bob'),
      ]);

      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error when stream errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreBuilder<TestModel, String>(
            store: mockStore,
            builder: (context, items) => Text('Count: ${items.length}'),
          ),
        ),
      );

      streamController.addError(Exception('Test error'));
      await tester.pump();

      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets('shows custom error widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreBuilder<TestModel, String>(
            store: mockStore,
            builder: (context, items) => Text('Count: ${items.length}'),
            error: (context, error) => Text('Custom: $error'),
          ),
        ),
      );

      streamController.addError(Exception('Test error'));
      await tester.pump();

      expect(find.textContaining('Custom:'), findsOneWidget);
    });

    testWidgets('updates when stream emits new data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreBuilder<TestModel, String>(
            store: mockStore,
            builder: (context, items) => Text('Count: ${items.length}'),
          ),
        ),
      );

      streamController.add([const TestModel(id: '1', name: 'Alice')]);
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      streamController.add([
        const TestModel(id: '1', name: 'Alice'),
        const TestModel(id: '2', name: 'Bob'),
      ]);
      await tester.pump();
      expect(find.text('Count: 2'), findsOneWidget);
    });

    testWidgets('disposes subscription on widget dispose', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreBuilder<TestModel, String>(
            store: mockStore,
            builder: (context, items) => Text('Count: ${items.length}'),
          ),
        ),
      );

      expect(streamController.hasListener, isTrue);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(streamController.hasListener, isFalse);
    });

    testWidgets('resubscribes when store changes', (tester) async {
      final mockStore2 = MockNexusStore<TestModel, String>();
      final streamController2 = StreamController<List<TestModel>>.broadcast();

      when(() => mockStore2.watchAll(query: any(named: 'query')))
          .thenAnswer((_) => streamController2.stream);

      var currentStore = mockStore;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                NexusStoreBuilder<TestModel, String>(
                  store: currentStore,
                  builder: (context, items) => Text('Count: ${items.length}'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => currentStore = mockStore2),
                  child: const Text('Switch'),
                ),
              ],
            ),
          ),
        ),
      );

      streamController.add([const TestModel(id: '1', name: 'Alice')]);
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      await tester.tap(find.text('Switch'));
      await tester.pump();

      streamController2.add([
        const TestModel(id: '1', name: 'Alice'),
        const TestModel(id: '2', name: 'Bob'),
        const TestModel(id: '3', name: 'Charlie'),
      ]);
      await tester.pump();
      expect(find.text('Count: 3'), findsOneWidget);

      await streamController2.close();
    });

    testWidgets('passes query to watchAll', (tester) async {
      final query = const Query<TestModel>().limitTo(10);

      await tester.pumpWidget(
        MaterialApp(
          home: NexusStoreBuilder<TestModel, String>(
            store: mockStore,
            query: query,
            builder: (context, items) => Text('Count: ${items.length}'),
          ),
        ),
      );

      verify(() => mockStore.watchAll(query: query)).called(1);
    });
  });
}
