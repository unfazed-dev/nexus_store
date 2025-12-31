import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter/nexus_store_flutter.dart';

void main() {
  group('PaginationStateBuilder', () {
    testWidgets('renders initial state', (tester) async {
      final state = PaginationState<String>.initial();

      await tester.pumpWidget(
        MaterialApp(
          home: PaginationStateBuilder<String>(
            state: state,
            initial: () => const Text('Initial'),
            loading: (_) => const Text('Loading'),
            loadingMore: (_, __) => const Text('Loading More'),
            data: (_, __) => const Text('Data'),
            error: (_, __, ___) => const Text('Error'),
          ),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      final state = PaginationState<String>.loading();

      await tester.pumpWidget(
        MaterialApp(
          home: PaginationStateBuilder<String>(
            state: state,
            initial: () => const Text('Initial'),
            loading: (previousItems) =>
                Text('Loading ${previousItems?.length ?? 0}'),
            loadingMore: (_, __) => const Text('Loading More'),
            data: (_, __) => const Text('Data'),
            error: (_, __, ___) => const Text('Error'),
          ),
        ),
      );

      expect(find.text('Loading 0'), findsOneWidget);
    });

    testWidgets('renders loading state with previous items', (tester) async {
      final state = PaginationState<String>.loading(
        previousItems: const ['a', 'b', 'c'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PaginationStateBuilder<String>(
            state: state,
            initial: () => const Text('Initial'),
            loading: (previousItems) =>
                Text('Loading ${previousItems?.length ?? 0}'),
            loadingMore: (_, __) => const Text('Loading More'),
            data: (_, __) => const Text('Data'),
            error: (_, __, ___) => const Text('Error'),
          ),
        ),
      );

      expect(find.text('Loading 3'), findsOneWidget);
    });

    testWidgets('renders loadingMore state', (tester) async {
      final state = PaginationState<String>.loadingMore(
        items: const ['a', 'b'],
        pageInfo: const PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PaginationStateBuilder<String>(
            state: state,
            initial: () => const Text('Initial'),
            loading: (_) => const Text('Loading'),
            loadingMore: (items, pageInfo) =>
                Text('Loading More: ${items.length}'),
            data: (_, __) => const Text('Data'),
            error: (_, __, ___) => const Text('Error'),
          ),
        ),
      );

      expect(find.text('Loading More: 2'), findsOneWidget);
    });

    testWidgets('renders data state', (tester) async {
      final state = PaginationState<String>.data(
        items: const ['a', 'b', 'c'],
        pageInfo: const PageInfo(
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PaginationStateBuilder<String>(
            state: state,
            initial: () => const Text('Initial'),
            loading: (_) => const Text('Loading'),
            loadingMore: (_, __) => const Text('Loading More'),
            data: (items, pageInfo) => Text('Data: ${items.length}'),
            error: (_, __, ___) => const Text('Error'),
          ),
        ),
      );

      expect(find.text('Data: 3'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      final state = PaginationState<String>.error(
        Exception('Test error'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PaginationStateBuilder<String>(
            state: state,
            initial: () => const Text('Initial'),
            loading: (_) => const Text('Loading'),
            loadingMore: (_, __) => const Text('Loading More'),
            data: (_, __) => const Text('Data'),
            error: (error, previousItems, pageInfo) => Text('Error: $error'),
          ),
        ),
      );

      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets('error state preserves previous items', (tester) async {
      final state = PaginationState<String>.error(
        Exception('Test error'),
        previousItems: const ['a', 'b'],
        pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PaginationStateBuilder<String>(
            state: state,
            initial: () => const Text('Initial'),
            loading: (_) => const Text('Loading'),
            loadingMore: (_, __) => const Text('Loading More'),
            data: (_, __) => const Text('Data'),
            error: (error, previousItems, pageInfo) =>
                Text('Error with ${previousItems?.length ?? 0} items'),
          ),
        ),
      );

      expect(find.text('Error with 2 items'), findsOneWidget);
    });

    testWidgets('rebuilds when state changes', (tester) async {
      var state = PaginationState<String>.initial();

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                PaginationStateBuilder<String>(
                  state: state,
                  initial: () => const Text('Initial'),
                  loading: (_) => const Text('Loading'),
                  loadingMore: (_, __) => const Text('Loading More'),
                  data: (items, _) => Text('Data: ${items.length}'),
                  error: (_, __, ___) => const Text('Error'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      state = PaginationState<String>.data(
                        items: const ['x', 'y'],
                        pageInfo: const PageInfo(
                          hasNextPage: false,
                          hasPreviousPage: false,
                        ),
                      );
                    });
                  },
                  child: const Text('Change State'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);

      await tester.tap(find.text('Change State'));
      await tester.pump();

      expect(find.text('Data: 2'), findsOneWidget);
    });

    testWidgets('uses orElse for unhandled states', (tester) async {
      final state = PaginationState<String>.initial();

      await tester.pumpWidget(
        MaterialApp(
          home: PaginationStateBuilder<String>.maybeWhen(
            state: state,
            data: (items, _) => Text('Data: ${items.length}'),
            orElse: () => const Text('Fallback'),
          ),
        ),
      );

      expect(find.text('Fallback'), findsOneWidget);
    });

    testWidgets('maybeWhen renders matched state', (tester) async {
      final state = PaginationState<String>.data(
        items: const ['a'],
        pageInfo: const PageInfo(hasNextPage: false, hasPreviousPage: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PaginationStateBuilder<String>.maybeWhen(
            state: state,
            data: (items, _) => Text('Data: ${items.length}'),
            orElse: () => const Text('Fallback'),
          ),
        ),
      );

      expect(find.text('Data: 1'), findsOneWidget);
    });
  });
}
