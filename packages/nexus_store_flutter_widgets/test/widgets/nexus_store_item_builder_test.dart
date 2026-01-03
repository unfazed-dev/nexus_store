import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter_widgets/nexus_store_flutter_widgets.dart';

class MockNexusStore<T, ID> extends Mock implements NexusStore<T, ID> {}

class TestModel {
  const TestModel({required this.id, required this.name});

  final String id;
  final String name;

  @override
  String toString() => 'TestModel($id, $name)';
}

void main() {
  group('NexusStoreItemBuilder', () {
    late MockNexusStore<TestModel, String> mockStore;
    late StreamController<TestModel?> streamController;

    setUp(() {
      mockStore = MockNexusStore<TestModel, String>();
      streamController = StreamController<TestModel?>.broadcast();

      when(() => mockStore.watch(any()))
          .thenAnswer((_) => streamController.stream);
    });

    tearDown(() {
      streamController.close();
    });

    group('loading state', () {
      testWidgets('shows loading indicator initially', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: NexusStoreItemBuilder<TestModel, String>(
              store: mockStore,
              id: 'test-id',
              builder: (context, item) => Text(item?.name ?? 'Not found'),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows custom loading widget', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: NexusStoreItemBuilder<TestModel, String>(
              store: mockStore,
              id: 'test-id',
              builder: (context, item) => Text(item?.name ?? 'Not found'),
              loading: const Text('Custom Loading'),
            ),
          ),
        );

        expect(find.text('Custom Loading'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('data state', () {
      testWidgets('displays item data when stream emits', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: NexusStoreItemBuilder<TestModel, String>(
              store: mockStore,
              id: 'test-id',
              builder: (context, item) => Text(item?.name ?? 'Not found'),
            ),
          ),
        );

        streamController.add(const TestModel(id: 'test-id', name: 'Alice'));
        await tester.pump();

        expect(find.text('Alice'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('displays null item (not found case)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: NexusStoreItemBuilder<TestModel, String>(
              store: mockStore,
              id: 'missing-id',
              builder: (context, item) => Text(item?.name ?? 'Not found'),
            ),
          ),
        );

        streamController.add(null);
        await tester.pump();

        expect(find.text('Not found'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('updates when stream emits new data', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: NexusStoreItemBuilder<TestModel, String>(
              store: mockStore,
              id: 'test-id',
              builder: (context, item) => Text(item?.name ?? 'Not found'),
            ),
          ),
        );

        streamController.add(const TestModel(id: 'test-id', name: 'Alice'));
        await tester.pump();
        expect(find.text('Alice'), findsOneWidget);

        streamController
            .add(const TestModel(id: 'test-id', name: 'Alice Updated'));
        await tester.pump();
        expect(find.text('Alice Updated'), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error when stream errors', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: NexusStoreItemBuilder<TestModel, String>(
              store: mockStore,
              id: 'test-id',
              builder: (context, item) => Text(item?.name ?? 'Not found'),
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
            home: NexusStoreItemBuilder<TestModel, String>(
              store: mockStore,
              id: 'test-id',
              builder: (context, item) => Text(item?.name ?? 'Not found'),
              error: (context, error) => Text('Custom Error: $error'),
            ),
          ),
        );

        streamController.addError(Exception('Test error'));
        await tester.pump();

        expect(find.textContaining('Custom Error:'), findsOneWidget);
      });

      testWidgets('error widget uses theme color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(error: Colors.red),
            ),
            home: NexusStoreItemBuilder<TestModel, String>(
              store: mockStore,
              id: 'test-id',
              builder: (context, item) => Text(item?.name ?? 'Not found'),
            ),
          ),
        );

        streamController.addError(Exception('Test error'));
        await tester.pump();

        final textWidget = tester.widget<Text>(find.textContaining('Error:'));
        expect(textWidget.style?.color, Colors.red);
      });
    });

    group('subscription lifecycle', () {
      testWidgets('disposes subscription on widget dispose', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: NexusStoreItemBuilder<TestModel, String>(
              store: mockStore,
              id: 'test-id',
              builder: (context, item) => Text(item?.name ?? 'Not found'),
            ),
          ),
        );

        expect(streamController.hasListener, isTrue);

        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        expect(streamController.hasListener, isFalse);
      });

      testWidgets('resubscribes when store changes', (tester) async {
        final mockStore2 = MockNexusStore<TestModel, String>();
        final streamController2 = StreamController<TestModel?>.broadcast();

        when(() => mockStore2.watch(any()))
            .thenAnswer((_) => streamController2.stream);

        var currentStore = mockStore;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  NexusStoreItemBuilder<TestModel, String>(
                    store: currentStore,
                    id: 'test-id',
                    builder: (context, item) => Text(item?.name ?? 'Not found'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => currentStore = mockStore2),
                    child: const Text('Switch Store'),
                  ),
                ],
              ),
            ),
          ),
        );

        streamController.add(const TestModel(id: 'test-id', name: 'Alice'));
        await tester.pump();
        expect(find.text('Alice'), findsOneWidget);

        await tester.tap(find.text('Switch Store'));
        await tester.pump();

        streamController2.add(const TestModel(id: 'test-id', name: 'Bob'));
        await tester.pump();
        expect(find.text('Bob'), findsOneWidget);

        await streamController2.close();
      });

      testWidgets('resubscribes when id changes', (tester) async {
        var currentId = 'id-1';

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  NexusStoreItemBuilder<TestModel, String>(
                    store: mockStore,
                    id: currentId,
                    builder: (context, item) => Text(item?.name ?? 'Not found'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => currentId = 'id-2'),
                    child: const Text('Switch ID'),
                  ),
                ],
              ),
            ),
          ),
        );

        streamController.add(const TestModel(id: 'id-1', name: 'Item 1'));
        await tester.pump();
        expect(find.text('Item 1'), findsOneWidget);

        // Verify watch was called with first id
        verify(() => mockStore.watch('id-1')).called(1);

        await tester.tap(find.text('Switch ID'));
        await tester.pump();

        // Shows loading again while resubscribing
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Verify watch was called with new id
        verify(() => mockStore.watch('id-2')).called(1);

        streamController.add(const TestModel(id: 'id-2', name: 'Item 2'));
        await tester.pump();
        expect(find.text('Item 2'), findsOneWidget);
      });

      testWidgets('passes correct id to watch', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: NexusStoreItemBuilder<TestModel, String>(
              store: mockStore,
              id: 'specific-id-123',
              builder: (context, item) => Text(item?.name ?? 'Not found'),
            ),
          ),
        );

        verify(() => mockStore.watch('specific-id-123')).called(1);
      });
    });
  });
}
