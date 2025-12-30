import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../core/nexus_store.dart';

/// A computed store that derives its value from one or more source [NexusStore]s.
///
/// Whenever any source store's data changes, the compute function is re-evaluated
/// and the new result is emitted to subscribers.
///
/// Uses [BehaviorSubject] internally, so subscribers receive the current value
/// immediately upon subscription.
///
/// ## Example
///
/// ```dart
/// // Combine user and order stores into a dashboard state
/// final dashboardStore = ComputedStore.from2(
///   userStore,
///   orderStore,
///   (users, orders) => DashboardState(
///     userCount: users.length,
///     orderCount: orders.length,
///     revenue: orders.fold(0, (sum, o) => sum + o.total),
///   ),
/// );
///
/// // Watch computed state
/// dashboardStore.stream.listen((dashboard) {
///   print('Users: ${dashboard.userCount}, Orders: ${dashboard.orderCount}');
/// });
///
/// // Clean up
/// await dashboardStore.dispose();
/// ```
class ComputedStore<T> {
  ComputedStore._({
    required BehaviorSubject<T> subject,
    required List<StreamSubscription<dynamic>> subscriptions,
  })  : _subject = subject,
        _subscriptions = subscriptions;

  final BehaviorSubject<T> _subject;
  final List<StreamSubscription<dynamic>> _subscriptions;

  /// Creates a [ComputedStore] from two source stores.
  ///
  /// The [compute] function receives the current data from both stores
  /// and should return the computed value.
  static ComputedStore<R> from2<A, B, R>(
    NexusStore<A, dynamic> store1,
    NexusStore<B, dynamic> store2,
    R Function(List<A>, List<B>) compute,
  ) {
    final subject = BehaviorSubject<R>();
    final subscriptions = <StreamSubscription<dynamic>>[];

    final combinedStream = Rx.combineLatest2(
      store1.watchAll(),
      store2.watchAll(),
      (List<A> a, List<B> b) => compute(a, b),
    ).distinct();

    subscriptions.add(combinedStream.listen(subject.add));

    return ComputedStore._(
      subject: subject,
      subscriptions: subscriptions,
    );
  }

  /// Creates a [ComputedStore] from three source stores.
  ///
  /// The [compute] function receives the current data from all three stores
  /// and should return the computed value.
  static ComputedStore<R> from3<A, B, C, R>(
    NexusStore<A, dynamic> store1,
    NexusStore<B, dynamic> store2,
    NexusStore<C, dynamic> store3,
    R Function(List<A>, List<B>, List<C>) compute,
  ) {
    final subject = BehaviorSubject<R>();
    final subscriptions = <StreamSubscription<dynamic>>[];

    final combinedStream = Rx.combineLatest3(
      store1.watchAll(),
      store2.watchAll(),
      store3.watchAll(),
      (List<A> a, List<B> b, List<C> c) => compute(a, b, c),
    ).distinct();

    subscriptions.add(combinedStream.listen(subject.add));

    return ComputedStore._(
      subject: subject,
      subscriptions: subscriptions,
    );
  }

  /// Creates a [ComputedStore] from a list of source stores.
  ///
  /// The [compute] function receives a list of data lists (one per store)
  /// and should return the computed value.
  ///
  /// Use this when you need to combine more than 3 stores or when the
  /// number of stores is dynamic.
  static ComputedStore<R> fromList<R>(
    List<NexusStore<dynamic, dynamic>> stores,
    R Function(List<List<dynamic>>) compute,
  ) {
    final subject = BehaviorSubject<R>();
    final subscriptions = <StreamSubscription<dynamic>>[];

    if (stores.isEmpty) {
      // For empty list, emit computed value immediately
      subject.add(compute([]));
    } else {
      final streams = stores.map((s) => s.watchAll()).toList();

      final combinedStream = Rx.combineLatestList(streams)
          .map((allData) => compute(allData))
          .distinct();

      subscriptions.add(combinedStream.listen(subject.add));
    }

    return ComputedStore._(
      subject: subject,
      subscriptions: subscriptions,
    );
  }

  /// The current computed value.
  ///
  /// May throw [StateError] if accessed before any value has been computed.
  T get value => _subject.value;

  /// Stream of computed values.
  ///
  /// Emits the current value immediately upon subscription (BehaviorSubject).
  Stream<T> get stream => _subject.stream;

  /// Returns `true` if this computed store has been disposed.
  bool get isClosed => _subject.isClosed;

  /// Disposes this computed store.
  ///
  /// Cancels all source subscriptions and closes the stream.
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _subject.close();
  }
}
