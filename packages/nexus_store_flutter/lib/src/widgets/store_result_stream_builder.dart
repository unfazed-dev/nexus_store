/// A widget that builds UI from a stream using [StoreResult] states.
library;

import 'package:flutter/material.dart';
import 'package:nexus_store_flutter/src/types/store_result.dart';
import 'package:nexus_store_flutter/src/widgets/store_result_builder.dart';

/// A widget that subscribes to a stream and builds UI based on [StoreResult].
///
/// This widget wraps [StreamBuilder] internally and converts stream events
/// to [StoreResult] states for consistent handling of async data.
///
/// Example:
/// ```dart
/// StoreResultStreamBuilder<User>(
///   stream: userStream,
///   builder: (context, user) => Text(user.name),
///   pending: (context, previousUser) => CircularProgressIndicator(),
/// )
/// ```
///
/// The stream is expected to emit [StoreResult<T>] values. For raw data
/// streams, consider using [DataStreamBuilder] instead.
class StoreResultStreamBuilder<T> extends StatelessWidget {
  /// Creates a widget that builds UI from a [StoreResult] stream.
  ///
  /// The [stream] and [builder] parameters are required.
  const StoreResultStreamBuilder({
    required this.stream,
    required this.builder,
    this.initialResult,
    this.idle,
    this.pending,
    this.error,
    super.key,
  });

  /// The stream of store results to build UI from.
  final Stream<StoreResult<T>> stream;

  /// The initial result before the stream emits any values.
  ///
  /// Defaults to [StoreResult.pending] if not provided.
  final StoreResult<T>? initialResult;

  /// Builder for the success state.
  final Widget Function(BuildContext context, T data) builder;

  /// Builder for the idle state.
  final Widget Function(BuildContext context)? idle;

  /// Builder for the pending/loading state.
  final Widget Function(BuildContext context, T? previousData)? pending;

  /// Builder for the error state.
  final Widget Function(
    BuildContext context,
    Object error,
    T? previousData,
  )? error;

  @override
  Widget build(BuildContext context) => StreamBuilder<StoreResult<T>>(
        stream: stream,
        initialData: initialResult,
        builder: (context, snapshot) {
          final result = _resolveResult(snapshot);

          return StoreResultBuilder<T>(
            result: result,
            builder: builder,
            idle: idle,
            pending: pending,
            error: error,
          );
        },
      );

  StoreResult<T> _resolveResult(AsyncSnapshot<StoreResult<T>> snapshot) {
    // Handle stream errors
    if (snapshot.hasError) {
      final previousData = snapshot.data?.data;
      return StoreResult<T>.error(snapshot.error!, previousData);
    }

    // Handle stream data
    if (snapshot.hasData) {
      return snapshot.data!;
    }

    // Handle waiting state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return initialResult ?? const StoreResult.pending();
    }

    // coverage:ignore-start
    // Handle done state with no data
    if (snapshot.connectionState == ConnectionState.done) {
      return const StoreResult.idle();
    }

    // Default to pending
    return const StoreResult.pending();
    // coverage:ignore-end
  }
}

/// A widget that builds UI from a raw data stream using [StoreResult].
///
/// Unlike [StoreResultStreamBuilder], this widget accepts a stream of raw
/// data values (not [StoreResult]) and wraps them automatically.
///
/// Example:
/// ```dart
/// DataStreamBuilder<User>(
///   stream: store.watchAll(),
///   builder: (context, users) => ListView(
///     children: users.map((u) => Text(u.name)).toList(),
///   ),
/// )
/// ```
class DataStreamBuilder<T> extends StatefulWidget {
  /// Creates a widget that builds UI from a raw data stream.
  ///
  /// The [stream] and [builder] parameters are required.
  const DataStreamBuilder({
    required this.stream,
    required this.builder,
    this.initialData,
    this.idle,
    this.pending,
    this.error,
    super.key,
  });

  /// The stream of data to build UI from.
  final Stream<T> stream;

  /// Initial data to use before the stream emits.
  final T? initialData;

  /// Builder for the success state.
  final Widget Function(BuildContext context, T data) builder;

  /// Builder for the idle state.
  final Widget Function(BuildContext context)? idle;

  /// Builder for the pending/loading state.
  final Widget Function(BuildContext context, T? previousData)? pending;

  /// Builder for the error state.
  final Widget Function(
    BuildContext context,
    Object error,
    T? previousData,
  )? error;

  @override
  State<DataStreamBuilder<T>> createState() => _DataStreamBuilderState<T>();
}

class _DataStreamBuilderState<T> extends State<DataStreamBuilder<T>> {
  T? _lastData;

  @override
  void initState() {
    super.initState();
    _lastData = widget.initialData;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
        stream: widget.stream,
        initialData: widget.initialData,
        builder: (context, snapshot) {
          final result = _resolveResult(snapshot);

          return StoreResultBuilder<T>(
            result: result,
            builder: widget.builder,
            idle: widget.idle,
            pending: widget.pending,
            error: widget.error,
          );
        },
      );

  StoreResult<T> _resolveResult(AsyncSnapshot<T> snapshot) {
    // Handle stream errors
    if (snapshot.hasError) {
      return StoreResult<T>.error(snapshot.error!, _lastData);
    }

    // Handle stream data
    if (snapshot.hasData) {
      _lastData = snapshot.data;
      return StoreResult<T>.success(snapshot.data as T);
    }

    // coverage:ignore-start
    // Handle waiting state
    if (snapshot.connectionState == ConnectionState.waiting) {
      if (_lastData != null) {
        return StoreResult<T>.pending(_lastData);
      }
      return const StoreResult.pending();
    }

    // Handle done state with no data
    if (snapshot.connectionState == ConnectionState.done) {
      if (_lastData != null) {
        return StoreResult<T>.success(_lastData as T);
      }
      return const StoreResult.idle();
    }

    // Default to pending
    return StoreResult<T>.pending(_lastData);
    // coverage:ignore-end
  }
}
