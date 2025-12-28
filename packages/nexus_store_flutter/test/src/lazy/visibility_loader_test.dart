import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter/src/lazy/visibility_loader.dart';

void main() {
  group('VisibilityLoader', () {
    testWidgets('shows placeholder before loading', (tester) async {
      final completer = Completer<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: VisibilityLoader<String>(
            loader: () => completer.future,
            placeholder: const Text('Loading...'),
            builder: (context, data) => Text('Data: $data'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Data: test'), findsNothing);
    });

    testWidgets('shows content after loading completes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VisibilityLoader<String>(
            loader: () async => 'Hello World',
            placeholder: const Text('Loading...'),
            builder: (context, data) => Text('Data: $data'),
          ),
        ),
      );

      // Initially shows placeholder
      expect(find.text('Loading...'), findsOneWidget);

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Shows loaded content
      expect(find.text('Data: Hello World'), findsOneWidget);
      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets('triggers loader immediately when triggerOnBuild is true',
        (tester) async {
      var loadCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: VisibilityLoader<String>(
            loader: () async {
              loadCount++;
              return 'Loaded';
            },
            placeholder: const Text('Loading...'),
            builder: (context, data) => Text(data),
          ),
        ),
      );

      expect(loadCount, equals(1));
      await tester.pumpAndSettle();
      expect(find.text('Loaded'), findsOneWidget);
    });

    testWidgets('shows error widget when loading fails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VisibilityLoader<String>(
            loader: () async => throw Exception('Load failed'),
            placeholder: const Text('Loading...'),
            builder: (context, data) => Text('Data: $data'),
            errorBuilder: (context, error, retry) => Text('Error: $error'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets('provides retry callback in error builder', (tester) async {
      var loadCount = 0;
      var shouldFail = true;

      await tester.pumpWidget(
        MaterialApp(
          home: VisibilityLoader<String>(
            loader: () async {
              loadCount++;
              if (shouldFail) {
                shouldFail = false;
                throw Exception('First load failed');
              }
              return 'Success on retry';
            },
            placeholder: const Text('Loading...'),
            builder: (context, data) => Text('Data: $data'),
            errorBuilder: (context, error, retry) => TextButton(
              onPressed: retry,
              child: const Text('Retry'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(loadCount, equals(1));
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(loadCount, equals(2));
      expect(find.text('Data: Success on retry'), findsOneWidget);
    });

    testWidgets('cancels loading on dispose', (tester) async {
      final completer = Completer<String>();
      var cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VisibilityLoader<String>(
            loader: () => completer.future.whenComplete(() {
                if (!completer.isCompleted) {
                  cancelled = true;
                }
              }),
            placeholder: const Text('Loading...'),
            builder: (context, data) => Text('Data: $data'),
          ),
        ),
      );

      // Dispose the widget before loading completes
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      // Complete after dispose - should not cause any issues
      completer.complete('Data');
      await tester.pump();
    });

    testWidgets('respects loadOnce parameter', (tester) async {
      var loadCount = 0;

      final widget = MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              VisibilityLoader<String>(
                loader: () async {
                  loadCount++;
                  return 'Loaded $loadCount';
                },
                placeholder: const Text('Loading...'),
                builder: (context, data) => Text(data),
                loadOnce: true,
              ),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Rebuild'),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(loadCount, equals(1));
      expect(find.text('Loaded 1'), findsOneWidget);

      // Trigger rebuild
      await tester.tap(find.text('Rebuild'));
      await tester.pumpAndSettle();

      // Should not reload
      expect(loadCount, equals(1));
      expect(find.text('Loaded 1'), findsOneWidget);
    });

    testWidgets('can be controlled via controller', (tester) async {
      var loadCount = 0;
      final controller = VisibilityLoaderController();

      await tester.pumpWidget(
        MaterialApp(
          home: VisibilityLoader<String>(
            controller: controller,
            loader: () async {
              loadCount++;
              return 'Loaded $loadCount';
            },
            placeholder: const Text('Loading...'),
            builder: (context, data) => Text(data),
            triggerOnBuild: false,
          ),
        ),
      );

      expect(loadCount, equals(0));
      expect(find.text('Loading...'), findsOneWidget);

      // Manually trigger load
      controller.load();
      await tester.pumpAndSettle();

      expect(loadCount, equals(1));
      expect(find.text('Loaded 1'), findsOneWidget);

      // Force reload
      controller.reload();
      await tester.pumpAndSettle();

      expect(loadCount, equals(2));
      expect(find.text('Loaded 2'), findsOneWidget);
    });

    testWidgets('can reset state via controller', (tester) async {
      var loadCount = 0;
      final controller = VisibilityLoaderController();

      await tester.pumpWidget(
        MaterialApp(
          home: VisibilityLoader<String>(
            controller: controller,
            loader: () async {
              loadCount++;
              return 'Loaded';
            },
            placeholder: const Text('Loading...'),
            builder: (context, data) => Text(data),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Loaded'), findsOneWidget);

      // Reset to show placeholder
      controller.reset();
      await tester.pump();

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('shows loading builder while loading', (tester) async {
      final completer = Completer<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: VisibilityLoader<String>(
            loader: () => completer.future,
            placeholder: const Text('Placeholder'),
            loadingBuilder: (context) => const Text('Custom Loading...'),
            builder: (context, data) => Text('Data: $data'),
          ),
        ),
      );

      // Shows placeholder initially (before load triggered)
      // After load starts, shows loading builder
      await tester.pump();
      expect(find.text('Custom Loading...'), findsOneWidget);
    });
  });

  group('VisibilityLoaderController', () {
    test('notifies listeners on load', () {
      final controller = VisibilityLoaderController();
      var notified = false;

      controller.addListener(() => notified = true);
      controller.load();

      expect(notified, isTrue);
    });

    test('notifies listeners on reload', () {
      final controller = VisibilityLoaderController();
      var notifyCount = 0;

      controller.addListener(() => notifyCount++);
      controller.load();
      controller.reload();

      expect(notifyCount, equals(2));
    });

    test('notifies listeners on reset', () {
      final controller = VisibilityLoaderController();
      var notifyCount = 0;

      controller.addListener(() => notifyCount++);
      controller.reset();

      expect(notifyCount, equals(1));
    });

    test('disposes cleanly', () {
      final controller = VisibilityLoaderController();
      controller.dispose();

      // Should not throw
      expect(controller.load, throwsFlutterError);
    });
  });
}
