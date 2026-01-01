import 'package:nexus_store/src/pagination/cursor.dart';
import 'package:nexus_store/src/pagination/page_info.dart';
import 'package:nexus_store/src/pagination/pagination_state.dart';
import 'package:test/test.dart';

void main() {
  group('PaginationState', () {
    group('initial', () {
      test('creates initial state', () {
        final state = PaginationState<String>.initial();

        expect(state, isA<PaginationInitial<String>>());
        expect(state.items, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.isLoadingMore, isFalse);
        expect(state.hasMore, isTrue);
        expect(state.error, isNull);
      });

      test('initial state has no items', () {
        final state = PaginationState<String>.initial();

        expect(state.items, isEmpty);
        expect(state.itemCount, equals(0));
      });
    });

    group('loading', () {
      test('creates loading state', () {
        final state = PaginationState<String>.loading();

        expect(state, isA<PaginationLoading<String>>());
        expect(state.isLoading, isTrue);
        expect(state.isLoadingMore, isFalse);
      });

      test('loading state can preserve previous items', () {
        final state = PaginationState<String>.loading(
          previousItems: ['a', 'b', 'c'],
        );

        expect(state.items, equals(['a', 'b', 'c']));
        expect(state.isLoading, isTrue);
      });

      test('loading state without previous items has empty list', () {
        final state = PaginationState<String>.loading();

        expect(state.items, isEmpty);
      });
    });

    group('loadingMore', () {
      test('creates loading more state', () {
        final state = PaginationState<String>.loadingMore(
          items: ['a', 'b'],
          pageInfo: const PageInfo(
            hasNextPage: true,
            hasPreviousPage: false,
          ),
        );

        expect(state, isA<PaginationLoadingMore<String>>());
        expect(state.isLoading, isFalse);
        expect(state.isLoadingMore, isTrue);
        expect(state.items, equals(['a', 'b']));
      });

      test('loadingMore preserves page info', () {
        final pageInfo = PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
          endCursor: Cursor.fromValues({'id': '123'}),
        );
        final state = PaginationState<String>.loadingMore(
          items: ['a'],
          pageInfo: pageInfo,
        );

        expect(state.hasMore, isTrue);
      });
    });

    group('data', () {
      test('creates data state', () {
        final state = PaginationState<String>.data(
          items: ['a', 'b', 'c'],
          pageInfo: const PageInfo(
            hasNextPage: true,
            hasPreviousPage: false,
          ),
        );

        expect(state, isA<PaginationData<String>>());
        expect(state.items, equals(['a', 'b', 'c']));
        expect(state.isLoading, isFalse);
        expect(state.isLoadingMore, isFalse);
      });

      test('data state with hasMore true', () {
        final state = PaginationState<String>.data(
          items: ['a', 'b'],
          pageInfo: const PageInfo(
            hasNextPage: true,
            hasPreviousPage: false,
          ),
        );

        expect(state.hasMore, isTrue);
      });

      test('data state with hasMore false', () {
        final state = PaginationState<String>.data(
          items: ['a', 'b'],
          pageInfo: const PageInfo(
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        );

        expect(state.hasMore, isFalse);
      });

      test('data state with empty items', () {
        final state = PaginationState<String>.data(
          items: [],
          pageInfo: const PageInfo(
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        );

        expect(state.isEmpty, isTrue);
        expect(state.isNotEmpty, isFalse);
      });

      test('data state preserves pageInfo', () {
        final cursor = Cursor.fromValues({'id': 'test'});
        final pageInfo = PageInfo(
          hasNextPage: true,
          hasPreviousPage: true,
          startCursor: cursor,
          endCursor: cursor,
          totalCount: 100,
        );
        final state = PaginationState<String>.data(
          items: ['a'],
          pageInfo: pageInfo,
        );

        expect(state.pageInfo, equals(pageInfo));
      });
    });

    group('error', () {
      test('creates error state', () {
        final error = Exception('Something went wrong');
        final state = PaginationState<String>.error(error);

        expect(state, isA<PaginationError<String>>());
        expect(state.error, equals(error));
        expect(state.isLoading, isFalse);
        expect(state.isLoadingMore, isFalse);
      });

      test('error state can preserve previous items', () {
        final error = Exception('Network error');
        final state = PaginationState<String>.error(
          error,
          previousItems: ['a', 'b', 'c'],
        );

        expect(state.items, equals(['a', 'b', 'c']));
        expect(state.error, equals(error));
      });

      test('error state without previous items has empty list', () {
        final state = PaginationState<String>.error(Exception('Error'));

        expect(state.items, isEmpty);
      });

      test('error state preserves page info when provided', () {
        final pageInfo = const PageInfo(
          hasNextPage: true,
          hasPreviousPage: false,
        );
        final state = PaginationState<String>.error(
          Exception('Error'),
          previousItems: ['a'],
          pageInfo: pageInfo,
        );

        expect(state.hasMore, isTrue);
      });
    });

    group('getter coverage', () {
      test('PaginationInitial.pageInfo returns null', () {
        final state = PaginationState<String>.initial();
        expect(state.pageInfo, isNull);
      });

      test('PaginationLoading.hasMore returns true', () {
        final state = PaginationState<String>.loading();
        expect(state.hasMore, isTrue);
      });

      test('PaginationLoading.pageInfo returns null', () {
        final state = PaginationState<String>.loading();
        expect(state.pageInfo, isNull);
      });

      test('PaginationLoadingMore.error returns null', () {
        final state = PaginationState<String>.loadingMore(
          items: ['a'],
          pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
        );
        expect(state.error, isNull);
      });

      test('PaginationData.error returns null', () {
        final state = PaginationState<String>.data(
          items: ['a'],
          pageInfo: const PageInfo.empty(),
        );
        expect(state.error, isNull);
      });

      test('PaginationError.hasMore with null pageInfo returns false', () {
        final state = PaginationState<String>.error(Exception('error'));
        expect(state.hasMore, isFalse);
      });

      test('PaginationError.hasMore with pageInfo uses hasNextPage', () {
        final state = PaginationState<String>.error(
          Exception('error'),
          pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
        );
        expect(state.hasMore, isTrue);
      });
    });

    group('common properties', () {
      test('itemCount returns correct count', () {
        final state = PaginationState<String>.data(
          items: ['a', 'b', 'c', 'd'],
          pageInfo: const PageInfo.empty(),
        );

        expect(state.itemCount, equals(4));
      });

      test('isEmpty is true for empty items', () {
        final state = PaginationState<String>.data(
          items: [],
          pageInfo: const PageInfo.empty(),
        );

        expect(state.isEmpty, isTrue);
      });

      test('isNotEmpty is true for non-empty items', () {
        final state = PaginationState<String>.data(
          items: ['a'],
          pageInfo: const PageInfo.empty(),
        );

        expect(state.isNotEmpty, isTrue);
      });

      test('hasError is true for error state', () {
        final state = PaginationState<String>.error(Exception('Error'));

        expect(state.hasError, isTrue);
      });

      test('hasError is false for non-error states', () {
        expect(
          PaginationState<String>.initial().hasError,
          isFalse,
        );
        expect(
          PaginationState<String>.loading().hasError,
          isFalse,
        );
        expect(
          PaginationState<String>.data(
            items: [],
            pageInfo: const PageInfo.empty(),
          ).hasError,
          isFalse,
        );
      });
    });

    group('pattern matching', () {
      test('when method covers all cases', () {
        String describe(PaginationState<String> state) {
          return state.when(
            initial: () => 'initial',
            loading: (items) => 'loading with ${items.length} items',
            loadingMore: (items, pageInfo) => 'loading more',
            data: (items, pageInfo) => 'data with ${items.length} items',
            error: (error, items, pageInfo) => 'error: $error',
          );
        }

        expect(
          describe(PaginationState<String>.initial()),
          equals('initial'),
        );
        expect(
          describe(PaginationState<String>.loading()),
          equals('loading with 0 items'),
        );
        expect(
          describe(PaginationState<String>.loadingMore(
            items: ['a'],
            pageInfo: const PageInfo.empty(),
          )),
          equals('loading more'),
        );
        expect(
          describe(PaginationState<String>.data(
            items: ['a', 'b'],
            pageInfo: const PageInfo.empty(),
          )),
          equals('data with 2 items'),
        );
        expect(
          describe(PaginationState<String>.error(Exception('oops'))),
          contains('error'),
        );
      });

      test('maybeWhen with orElse', () {
        final state = PaginationState<String>.data(
          items: ['a'],
          pageInfo: const PageInfo.empty(),
        );

        final result = state.maybeWhen(
          data: (items, pageInfo) => 'has data',
          orElse: () => 'other',
        );

        expect(result, equals('has data'));
      });

      test('maybeWhen falls through to orElse for loading', () {
        final state = PaginationState<String>.loading();

        final result = state.maybeWhen(
          data: (items, pageInfo) => 'has data',
          orElse: () => 'other',
        );

        expect(result, equals('other'));
      });

      test('maybeWhen falls through to orElse for initial', () {
        final state = PaginationState<String>.initial();

        final result = state.maybeWhen(
          data: (items, pageInfo) => 'has data',
          loading: (items) => 'loading',
          orElse: () => 'orElse called',
        );

        expect(result, equals('orElse called'));
      });

      test('maybeWhen falls through to orElse for loadingMore', () {
        final state = PaginationState<String>.loadingMore(
          items: ['a', 'b'],
          pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        final result = state.maybeWhen(
          data: (items, pageInfo) => 'has data',
          initial: () => 'initial',
          orElse: () => 'orElse called',
        );

        expect(result, equals('orElse called'));
      });

      test('maybeWhen falls through to orElse for error', () {
        final state = PaginationState<String>.error(
          Exception('test error'),
          previousItems: ['a'],
        );

        final result = state.maybeWhen(
          data: (items, pageInfo) => 'has data',
          loading: (items) => 'loading',
          orElse: () => 'orElse called',
        );

        expect(result, equals('orElse called'));
      });

      test('maybeWhen uses handler when initial is provided', () {
        final state = PaginationState<String>.initial();

        final result = state.maybeWhen(
          initial: () => 'initial state',
          orElse: () => 'other',
        );

        expect(result, equals('initial state'));
      });

      test('maybeWhen uses handler when loadingMore is provided', () {
        final state = PaginationState<String>.loadingMore(
          items: ['a'],
          pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
        );

        final result = state.maybeWhen(
          loadingMore: (items, pageInfo) => 'loading more items',
          orElse: () => 'other',
        );

        expect(result, equals('loading more items'));
      });

      test('maybeWhen uses handler when error is provided', () {
        final state = PaginationState<String>.error(Exception('oops'));

        final result = state.maybeWhen(
          error: (err, items, pageInfo) => 'error occurred',
          orElse: () => 'other',
        );

        expect(result, equals('error occurred'));
      });
    });

    group('copyWith', () {
      test('data state copyWith updates items', () {
        final state = PaginationState<String>.data(
          items: ['a', 'b'],
          pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
        ) as PaginationData<String>;

        final updated = state.copyWith(items: ['a', 'b', 'c']);

        expect(updated.items, equals(['a', 'b', 'c']));
        expect(updated.hasMore, isTrue);
      });

      test('data state copyWith updates pageInfo', () {
        final state = PaginationState<String>.data(
          items: ['a', 'b'],
          pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
        ) as PaginationData<String>;

        final newPageInfo = const PageInfo(
          hasNextPage: false,
          hasPreviousPage: true,
        );
        final updated = state.copyWith(pageInfo: newPageInfo);

        expect(updated.pageInfo.hasNextPage, isFalse);
        expect(updated.pageInfo.hasPreviousPage, isTrue);
        expect(updated.items, equals(['a', 'b']));
      });

      test('data state copyWith with no changes returns equivalent state', () {
        final state = PaginationState<String>.data(
          items: ['a', 'b'],
          pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
        ) as PaginationData<String>;

        final updated = state.copyWith();

        expect(updated.items, equals(state.items));
        expect(updated.pageInfo, equals(state.pageInfo));
      });

      test('error state copyWith updates error', () {
        final state = PaginationState<String>.error(
          Exception('old error'),
          previousItems: ['a'],
        ) as PaginationError<String>;

        final updated = state.copyWith(
          error: Exception('new error'),
        );

        expect(updated.error.toString(), contains('new error'));
        expect(updated.items, equals(['a']));
      });

      test('error state copyWith updates previousItems', () {
        final state = PaginationState<String>.error(
          Exception('error'),
          previousItems: ['a'],
        ) as PaginationError<String>;

        final updated = state.copyWith(previousItems: ['x', 'y', 'z']);

        expect(updated.items, equals(['x', 'y', 'z']));
        expect(updated.error.toString(), contains('error'));
      });

      test('error state copyWith updates pageInfo', () {
        final state = PaginationState<String>.error(
          Exception('error'),
          previousItems: ['a'],
          pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
        ) as PaginationError<String>;

        final newPageInfo = const PageInfo(
          hasNextPage: false,
          hasPreviousPage: true,
        );
        final updated = state.copyWith(pageInfo: newPageInfo);

        expect(updated.pageInfo!.hasNextPage, isFalse);
        expect(updated.pageInfo!.hasPreviousPage, isTrue);
      });

      test('error state copyWith with no changes returns equivalent state', () {
        final state = PaginationState<String>.error(
          Exception('error'),
          previousItems: ['a'],
          pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
        ) as PaginationError<String>;

        final updated = state.copyWith();

        expect(updated.items, equals(state.items));
        expect(updated.pageInfo, equals(state.pageInfo));
        expect(updated.error.toString(), equals(state.error.toString()));
      });
    });

    group('toString', () {
      test('initial state has readable string', () {
        final state = PaginationState<String>.initial();
        expect(state.toString(), contains('PaginationInitial'));
      });

      test('loading state has readable string', () {
        final state = PaginationState<String>.loading();
        expect(state.toString(), contains('PaginationLoading'));
      });

      test('data state has readable string', () {
        final state = PaginationState<String>.data(
          items: ['a', 'b'],
          pageInfo: const PageInfo.empty(),
        );
        expect(state.toString(), contains('PaginationData'));
        expect(state.toString(), contains('2 items'));
      });

      test('error state has readable string', () {
        final state = PaginationState<String>.error(Exception('test error'));
        expect(state.toString(), contains('PaginationError'));
      });

      test('loadingMore state includes item count and hasMore', () {
        final state = PaginationState<String>.loadingMore(
          items: ['a', 'b', 'c'],
          pageInfo: const PageInfo(hasNextPage: true, hasPreviousPage: false),
        );
        expect(state.toString(), contains('PaginationLoadingMore'));
        expect(state.toString(), contains('3 items'));
        expect(state.toString(), contains('hasMore: true'));
      });

      test('loading state includes previous items count', () {
        final state = PaginationState<String>.loading(
          previousItems: ['x', 'y'],
        );
        expect(state.toString(), contains('PaginationLoading'));
        expect(state.toString(), contains('2 previous items'));
      });

      test('error state includes error and previous items count', () {
        final state = PaginationState<String>.error(
          Exception('network error'),
          previousItems: ['a'],
        );
        expect(state.toString(), contains('PaginationError'));
        expect(state.toString(), contains('1 previous items'));
      });
    });
  });
}
