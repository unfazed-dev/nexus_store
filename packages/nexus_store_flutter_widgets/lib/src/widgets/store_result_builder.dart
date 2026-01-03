/// A widget that builds different UI based on [StoreResult] state.
library;

import 'package:flutter/material.dart';
import 'package:nexus_store_flutter_widgets/src/types/store_result.dart';

/// A widget that builds UI based on the state of a [StoreResult].
///
/// This widget provides a declarative way to handle idle, pending, success,
/// and error states with customizable builders for each state.
///
/// Example:
/// ```dart
/// StoreResultBuilder<User>(
///   result: userResult,
///   builder: (context, user) => Text(user.name),
///   pending: (context, previousUser) => CircularProgressIndicator(),
///   error: (context, error, previousUser) => Text('Error: $error'),
/// )
/// ```
///
/// The widget supports stale-while-revalidate patterns by providing
/// previous data to pending and error builders.
class StoreResultBuilder<T> extends StatelessWidget {
  /// Creates a widget that builds UI based on [StoreResult] state.
  ///
  /// The [result] and [builder] parameters are required.
  const StoreResultBuilder({
    required this.result,
    required this.builder,
    this.idle,
    this.pending,
    this.error,
    super.key,
  });

  /// The store result to build UI from.
  final StoreResult<T> result;

  /// Builder for the success state.
  ///
  /// Called when [result] is [StoreResultSuccess] with the data.
  final Widget Function(BuildContext context, T data) builder;

  /// Builder for the idle state.
  ///
  /// Called when [result] is [StoreResultIdle].
  /// Defaults to an empty [SizedBox].
  final Widget Function(BuildContext context)? idle;

  /// Builder for the pending/loading state.
  ///
  /// Called when [result] is [StoreResultPending].
  /// The [previousData] parameter contains any stale data to show.
  /// Defaults to a centered [CircularProgressIndicator].
  final Widget Function(BuildContext context, T? previousData)? pending;

  /// Builder for the error state.
  ///
  /// Called when [result] is [StoreResultError].
  /// The [previousData] parameter contains any stale data to show.
  /// Defaults to a centered error [Text] widget.
  final Widget Function(
    BuildContext context,
    Object error,
    T? previousData,
  )? error;

  @override
  Widget build(BuildContext context) => result.when(
        idle: () => _buildIdle(context),
        pending: (previousData) => _buildPending(context, previousData),
        success: (data) => builder(context, data),
        error: (err, previousData) => _buildError(context, err, previousData),
      );

  Widget _buildIdle(BuildContext context) =>
      idle?.call(context) ?? const SizedBox.shrink();

  Widget _buildPending(BuildContext context, T? previousData) {
    if (pending != null) {
      return pending!(context, previousData);
    }

    // Show stale data with loading indicator if available
    if (previousData != null) {
      return Stack(
        children: [
          builder(context, previousData),
          const Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(BuildContext context, Object err, T? previousData) {
    if (error != null) {
      return error!(context, err, previousData);
    }

    // Show stale data with error indicator if available
    if (previousData != null) {
      return Stack(
        children: [
          builder(context, previousData),
          Positioned(
            top: 8,
            right: 8,
            child: Tooltip(
              message: err.toString(),
              child: Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        'Error: $err',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

/// Extension methods for building widgets from [StoreResult].
extension StoreResultWidgetExtensions<T> on StoreResult<T> {
  /// Builds a widget based on the state of this result.
  ///
  /// This is a convenience method equivalent to using [StoreResultBuilder].
  Widget buildWidget({
    required Widget Function(BuildContext context, T data) builder,
    required BuildContext context,
    Widget Function(BuildContext context)? idle,
    Widget Function(BuildContext context, T? previousData)? pending,
    Widget Function(BuildContext context, Object error, T? previousData)? error,
  }) =>
      StoreResultBuilder<T>(
        result: this,
        builder: builder,
        idle: idle,
        pending: pending,
        error: error,
      );
}
