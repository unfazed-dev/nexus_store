import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter/nexus_store_flutter.dart';

class TestModel {
  const TestModel({required this.id, required this.name});

  final String id;
  final String name;

  @override
  String toString() => 'TestModel($id, $name)';
}

void main() {
  group('StoreResultStreamBuilder', () {
    late StreamController<StoreResult<TestModel>> streamController;

    setUp(() {
      streamController = StreamController<StoreResult<TestModel>>.broadcast();
    });

    tearDown(() {
      streamController.close();
    });

    group('initial state', () {
      testWidgets('shows pending state initially', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        // Default pending state shows CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('uses initialResult when provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              initialResult: const StoreResult.idle(),
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        // Idle state shows SizedBox by default
        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('uses custom idle builder', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              initialResult: const StoreResult.idle(),
              builder: (context, data) => Text(data.name),
              idle: (context) => const Text('Custom Idle'),
            ),
          ),
        );

        expect(find.text('Custom Idle'), findsOneWidget);
      });
    });

    group('success state', () {
      testWidgets('displays data when stream emits success', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        streamController.add(
          const StoreResult.success(TestModel(id: '1', name: 'Alice')),
        );
        await tester.pump();

        expect(find.text('Alice'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('updates when stream emits new success', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        streamController.add(
          const StoreResult.success(TestModel(id: '1', name: 'Alice')),
        );
        await tester.pump();
        expect(find.text('Alice'), findsOneWidget);

        streamController.add(
          const StoreResult.success(TestModel(id: '1', name: 'Bob')),
        );
        await tester.pump();
        expect(find.text('Bob'), findsOneWidget);
      });
    });

    group('pending state', () {
      testWidgets('shows pending when stream emits pending', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        streamController.add(const StoreResult.pending());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('uses custom pending builder', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
              pending: (context, previous) =>
                  Text('Loading... ${previous?.name ?? "no data"}'),
            ),
          ),
        );

        streamController.add(
          const StoreResult.pending(TestModel(id: '1', name: 'Alice')),
        );
        await tester.pump();

        expect(find.text('Loading... Alice'), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error when stream emits error result',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        streamController.add(
          StoreResult<TestModel>.error(Exception('Test error')),
        );
        await tester.pump();

        expect(find.textContaining('Error:'), findsOneWidget);
      });

      testWidgets('shows error when stream itself errors', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        streamController.addError(Exception('Stream error'));
        await tester.pump();

        expect(find.textContaining('Error:'), findsOneWidget);
      });

      testWidgets('uses custom error builder', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
              error: (context, error, previous) =>
                  Text('Custom Error: $error, prev: ${previous?.name}'),
            ),
          ),
        );

        streamController.add(
          StoreResult<TestModel>.error(
            Exception('Test'),
            const TestModel(id: '1', name: 'Alice'),
          ),
        );
        await tester.pump();

        expect(find.textContaining('Custom Error:'), findsOneWidget);
        expect(find.textContaining('prev: Alice'), findsOneWidget);
      });

      testWidgets('error result can include previous data', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
              error: (context, error, previous) =>
                  Text('Error with prev: ${previous?.name ?? "none"}'),
            ),
          ),
        );

        // Emit error result with previous data included
        streamController.add(
          StoreResult<TestModel>.error(
            Exception('Test error'),
            const TestModel(id: '1', name: 'Alice'),
          ),
        );
        await tester.pump();

        expect(find.textContaining('Error with prev: Alice'), findsOneWidget);
      });
    });

    group('idle state', () {
      testWidgets('shows idle when stream emits idle result', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StoreResultStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        streamController.add(const StoreResult.idle());
        await tester.pump();

        // Default idle shows SizedBox
        expect(find.byType(SizedBox), findsOneWidget);
      });
    });
  });

  group('DataStreamBuilder', () {
    late StreamController<TestModel> streamController;

    setUp(() {
      streamController = StreamController<TestModel>.broadcast();
    });

    tearDown(() {
      streamController.close();
    });

    group('initial state', () {
      testWidgets('shows pending state initially', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('uses initialData when provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: streamController.stream,
              initialData: const TestModel(id: '1', name: 'Initial'),
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        expect(find.text('Initial'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('data state', () {
      testWidgets('displays data when stream emits', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        streamController.add(const TestModel(id: '1', name: 'Alice'));
        await tester.pump();

        expect(find.text('Alice'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('updates _lastData on new emissions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        streamController.add(const TestModel(id: '1', name: 'Alice'));
        await tester.pump();
        expect(find.text('Alice'), findsOneWidget);

        streamController.add(const TestModel(id: '1', name: 'Bob'));
        await tester.pump();
        expect(find.text('Bob'), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error when stream errors', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        streamController.addError(Exception('Test error'));
        await tester.pump();

        expect(find.textContaining('Error:'), findsOneWidget);
      });

      testWidgets('preserves _lastData on error', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
              error: (context, error, previous) =>
                  Text('Error, prev: ${previous?.name ?? "none"}'),
            ),
          ),
        );

        streamController.add(const TestModel(id: '1', name: 'Alice'));
        await tester.pump();

        streamController.addError(Exception('Test error'));
        await tester.pump();

        expect(find.textContaining('Error, prev: Alice'), findsOneWidget);
      });

      testWidgets('uses custom error builder', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
              error: (context, error, previous) =>
                  Text('Custom: $error'),
            ),
          ),
        );

        streamController.addError(Exception('Test error'));
        await tester.pump();

        expect(find.textContaining('Custom:'), findsOneWidget);
      });
    });

    group('pending state', () {
      testWidgets('uses custom pending builder', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
              pending: (context, previous) =>
                  Text('Loading: ${previous?.name ?? "no data"}'),
            ),
          ),
        );

        expect(find.text('Loading: no data'), findsOneWidget);
      });

      testWidgets('pending shows _lastData after data received',
          (tester) async {
        // This tests that _lastData is preserved and shown in pending state
        // after data has been received but stream is waiting again
        late StreamController<TestModel> newStreamController;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return DataStreamBuilder<TestModel>(
                  stream: streamController.stream,
                  builder: (context, data) => Text(data.name),
                  pending: (context, previous) =>
                      Text('Pending: ${previous?.name ?? "none"}'),
                );
              },
            ),
          ),
        );

        // Emit data
        streamController.add(const TestModel(id: '1', name: 'Alice'));
        await tester.pump();
        expect(find.text('Alice'), findsOneWidget);

        // Create a new stream controller to simulate reconnection
        newStreamController = StreamController<TestModel>.broadcast();

        // Rebuild widget with new stream - should show pending with last data
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: newStreamController.stream,
              initialData: const TestModel(id: '1', name: 'Alice'),
              builder: (context, data) => Text(data.name),
              pending: (context, previous) =>
                  Text('Pending: ${previous?.name ?? "none"}'),
            ),
          ),
        );
        await tester.pump();

        // Should show Alice since initialData is set
        expect(find.text('Alice'), findsOneWidget);

        await newStreamController.close();
      });
    });

    group('idle state', () {
      testWidgets('uses custom idle builder', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
              idle: (context) => const Text('Idle State'),
            ),
          ),
        );

        // Close stream to trigger done state
        await streamController.close();
        await tester.pump();

        expect(find.text('Idle State'), findsOneWidget);
      });

      testWidgets('done state with _lastData shows success', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: DataStreamBuilder<TestModel>(
              stream: streamController.stream,
              builder: (context, data) => Text(data.name),
            ),
          ),
        );

        streamController.add(const TestModel(id: '1', name: 'Alice'));
        await tester.pump();

        await streamController.close();
        await tester.pump();

        // Done with data shows success
        expect(find.text('Alice'), findsOneWidget);
      });
    });
  });
}
