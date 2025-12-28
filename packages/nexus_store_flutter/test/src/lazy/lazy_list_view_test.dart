import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter/src/lazy/lazy_list_view.dart';

void main() {
  group('LazyListView', () {
    testWidgets('renders items with builders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String, void>(
              items: const ['A', 'B', 'C'],
              itemBuilder: (context, item, index, {lazyData}) => ListTile(
                title: Text('Item $item'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);
      expect(find.text('Item C'), findsOneWidget);
    });

    testWidgets('shows placeholder for lazy items until loaded',
        (tester) async {
      final completers = List.generate(3, (_) => Completer<String>());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String, String>(
              items: const ['A', 'B', 'C'],
              lazyFieldLoader: (item, index) => completers[index].future,
              itemBuilder: (context, item, index, {lazyData}) =>
                  ListTile(
                title: Text('Item $item'),
                subtitle: lazyData != null ? Text(lazyData) : null,
              ),
              lazyPlaceholder: (context, item, index) => ListTile(
                title: Text('Item $item'),
                subtitle: const Text('Loading...'),
              ),
            ),
          ),
        ),
      );

      // Initially shows placeholders for lazy content
      expect(find.text('Loading...'), findsNWidgets(3));

      // Complete first item
      completers[0].complete('Lazy A');
      await tester.pumpAndSettle();

      expect(find.text('Lazy A'), findsOneWidget);
      expect(find.text('Loading...'), findsNWidgets(2));
    });

    testWidgets('supports separatorBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String, void>(
              items: const ['A', 'B', 'C'],
              itemBuilder: (context, item, index, {lazyData}) =>
                  Text('Item $item'),
              separatorBuilder: (context, index) => const Divider(),
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsNWidgets(2)); // 3 items = 2 separators
    });

    testWidgets('supports custom scroll controller', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String, void>(
              items: List.generate(50, (i) => 'Item $i'),
              controller: controller,
              itemBuilder: (context, item, index, {lazyData}) => SizedBox(
                height: 50,
                child: Text(item),
              ),
            ),
          ),
        ),
      );

      expect(controller.hasClients, isTrue);

      // Scroll to bottom
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();

      expect(find.text('Item 49'), findsOneWidget);
    });

    testWidgets('supports horizontal scrolling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 100,
              child: LazyListView<String, void>(
                items: const ['A', 'B', 'C'],
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, item, index, {lazyData}) => SizedBox(
                  width: 100,
                  child: Center(child: Text('Item $item')),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item A'), findsOneWidget);
    });

    testWidgets('supports physics parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String, void>(
              items: const ['A', 'B', 'C'],
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, item, index, {lazyData}) =>
                  Text('Item $item'),
            ),
          ),
        ),
      );

      // Should render without error
      expect(find.text('Item A'), findsOneWidget);
    });

    testWidgets('supports padding parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String, void>(
              items: const ['A'],
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, item, index, {lazyData}) =>
                  Text('Item $item'),
            ),
          ),
        ),
      );

      expect(find.text('Item A'), findsOneWidget);
    });

    testWidgets('handles empty list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String, void>(
              items: const [],
              itemBuilder: (context, item, index, {lazyData}) =>
                  Text('Item $item'),
              emptyBuilder: (context) => const Text('No items'),
            ),
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('handles error in lazy loader', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String, String>(
              items: const ['A'],
              lazyFieldLoader: (item, index) async {
                throw Exception('Load failed');
              },
              itemBuilder: (context, item, index, {lazyData}) =>
                  ListTile(
                title: Text('Item $item'),
                subtitle: lazyData != null ? Text(lazyData) : null,
              ),
              lazyPlaceholder: (context, item, index) => const ListTile(
                title: Text('Loading...'),
              ),
              lazyErrorBuilder: (context, item, index, error, retry) =>
                  ListTile(
                title: Text('Error: $error'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: retry,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets('calls onItemVisible callback', (tester) async {
      final visibleItems = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<String, void>(
              items: const ['A', 'B', 'C'],
              itemBuilder: (context, item, index, {lazyData}) => SizedBox(
                height: 100,
                child: Text('Item $item'),
              ),
              onItemVisible: (item, index) {
                visibleItems.add(index);
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // All visible items should have triggered the callback
      expect(visibleItems, contains(0));
      expect(visibleItems, contains(1));
      expect(visibleItems, contains(2));
    });

    testWidgets('supports shrinkWrap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LazyListView<String, void>(
                  items: const ['A', 'B'],
                  shrinkWrap: true,
                  itemBuilder: (context, item, index, {lazyData}) =>
                      Text('Item $item'),
                ),
                const Text('After list'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('After list'), findsOneWidget);
    });
  });

  group('LazyListView.builder', () {
    testWidgets('creates items on demand', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyListView<int, void>.builder(
              itemCount: 100,
              itemBuilder: (context, index) {
                buildCount++;
                return SizedBox(
                  height: 50,
                  child: Text('Item $index'),
                );
              },
            ),
          ),
        ),
      );

      // Not all 100 items should be built - only visible ones
      expect(buildCount, lessThan(100));
      expect(find.text('Item 0'), findsOneWidget);
    });
  });
}
