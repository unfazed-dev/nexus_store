import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter/nexus_store_flutter.dart';

void main() {
  group('StoreResultBuilder', () {
    testWidgets('renders idle state with default widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreResultBuilder<String>(
            result: const StoreResult.idle(),
            builder: (context, data) => Text(data),
          ),
        ),
      );

      // Default idle widget is SizedBox.shrink
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text(''), findsNothing);
    });

    testWidgets('renders idle state with custom widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreResultBuilder<String>(
            result: const StoreResult.idle(),
            builder: (context, data) => Text(data),
            idle: (context) => const Text('Idle'),
          ),
        ),
      );

      expect(find.text('Idle'), findsOneWidget);
    });

    testWidgets('renders pending state with default widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreResultBuilder<String>(
            result: const StoreResult.pending(),
            builder: (context, data) => Text(data),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders pending state with custom widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreResultBuilder<String>(
            result: const StoreResult.pending(),
            builder: (context, data) => Text(data),
            pending: (context, prev) => const Text('Loading...'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('renders pending state with stale data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreResultBuilder<String>(
            result: const StoreResult.pending('stale'),
            builder: (context, data) => Text('Data: $data'),
          ),
        ),
      );

      // Default behavior shows stale data with loading indicator
      expect(find.text('Data: stale'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders success state with data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreResultBuilder<String>(
            result: const StoreResult.success('Hello World'),
            builder: (context, data) => Text(data),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders error state with default widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreResultBuilder<String>(
            result: StoreResult.error(Exception('Test error')),
            builder: (context, data) => Text(data),
          ),
        ),
      );

      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets('renders error state with custom widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreResultBuilder<String>(
            result: StoreResult.error(Exception('Test error')),
            builder: (context, data) => Text(data),
            error: (context, error, prev) => Text('Custom: $error'),
          ),
        ),
      );

      expect(find.textContaining('Custom:'), findsOneWidget);
    });

    testWidgets('renders error state with stale data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreResultBuilder<String>(
            result: StoreResult.error(Exception('error'), 'stale'),
            builder: (context, data) => Text('Data: $data'),
          ),
        ),
      );

      // Default behavior shows stale data with error indicator
      expect(find.text('Data: stale'), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('rebuilds when result changes', (tester) async {
      var result = const StoreResult<String>.pending();

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                StoreResultBuilder<String>(
                  result: result,
                  builder: (context, data) => Text(data),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      result = const StoreResult.success('Loaded');
                    });
                  },
                  child: const Text('Load'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Load'));
      await tester.pump();

      expect(find.text('Loaded'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('StoreResultWidgetExtensions', () {
    testWidgets('buildWidget creates StoreResultBuilder', (tester) async {
      const result = StoreResult<String>.success('Test');

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => result.buildWidget(
              context: context,
              builder: (ctx, data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });
  });
}
