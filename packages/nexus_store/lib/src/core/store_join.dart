import 'package:nexus_store/src/core/nexus_store.dart';
import 'package:nexus_store/src/query/query.dart';
import 'package:rxdart/rxdart.dart';

/// Reactive cross-store join utilities.
///
/// Combines [watchAll] streams from multiple [NexusStore] instances into a
/// single stream using Dart 3 record types for type-safe tuple returns.
///
/// ## Example
///
/// ```dart
/// // Combine two stores — re-emits when either changes
/// StoreJoin.combine2(
///   storeA: userStore,
///   storeB: orderStore,
/// ).listen((record) {
///   final (users, orders) = record;
///   print('Users: ${users.length}, Orders: ${orders.length}');
/// });
///
/// // Only emit when primary store changes, using latest secondary value
/// StoreJoin.withLatest2(
///   primary: userStore,
///   secondary: settingsStore,
/// ).listen((record) {
///   final (users, settings) = record;
///   // Only fires when userStore changes
/// });
/// ```
class StoreJoin {
  StoreJoin._();

  /// Combines two stores into a single stream of paired results.
  ///
  /// Emits whenever either store's data changes. Uses
  /// [Rx.combineLatest2] under the hood.
  static Stream<(List<A>, List<B>)> combine2<A, B>({
    required NexusStore<A, dynamic> storeA,
    required NexusStore<B, dynamic> storeB,
    Query<A>? queryA,
    Query<B>? queryB,
  }) {
    return Rx.combineLatest2(
      storeA.watchAll(query: queryA),
      storeB.watchAll(query: queryB),
      (List<A> a, List<B> b) => (a, b),
    );
  }

  /// Combines three stores into a single stream.
  ///
  /// Emits whenever any of the three stores' data changes.
  static Stream<(List<A>, List<B>, List<C>)> combine3<A, B, C>({
    required NexusStore<A, dynamic> storeA,
    required NexusStore<B, dynamic> storeB,
    required NexusStore<C, dynamic> storeC,
    Query<A>? queryA,
    Query<B>? queryB,
    Query<C>? queryC,
  }) {
    return Rx.combineLatest3(
      storeA.watchAll(query: queryA),
      storeB.watchAll(query: queryB),
      storeC.watchAll(query: queryC),
      (List<A> a, List<B> b, List<C> c) => (a, b, c),
    );
  }

  /// Combines four stores into a single stream.
  ///
  /// Emits whenever any of the four stores' data changes.
  static Stream<(List<A>, List<B>, List<C>, List<D>)> combine4<A, B, C, D>({
    required NexusStore<A, dynamic> storeA,
    required NexusStore<B, dynamic> storeB,
    required NexusStore<C, dynamic> storeC,
    required NexusStore<D, dynamic> storeD,
    Query<A>? queryA,
    Query<B>? queryB,
    Query<C>? queryC,
    Query<D>? queryD,
  }) {
    return Rx.combineLatest4(
      storeA.watchAll(query: queryA),
      storeB.watchAll(query: queryB),
      storeC.watchAll(query: queryC),
      storeD.watchAll(query: queryD),
      (List<A> a, List<B> b, List<C> c, List<D> d) => (a, b, c, d),
    );
  }

  /// Emits only when the [primary] store changes; [secondary] provides its
  /// latest value at that point.
  ///
  /// Unlike [combine2], changes to the secondary store alone do NOT trigger
  /// a new emission.
  static Stream<(List<A>, List<B>)> withLatest2<A, B>({
    required NexusStore<A, dynamic> primary,
    required NexusStore<B, dynamic> secondary,
    Query<A>? primaryQuery,
    Query<B>? secondaryQuery,
  }) {
    return primary
        .watchAll(query: primaryQuery)
        .withLatestFrom<List<B>, (List<A>, List<B>)>(
          secondary.watchAll(query: secondaryQuery),
          (List<A> a, List<B> b) => (a, b),
        );
  }
}
