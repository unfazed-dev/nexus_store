import 'package:meta/meta.dart';

/// Options for structured mutation lifecycle management.
///
/// Inspired by TanStack Query's `useMutation` pattern, this provides
/// hooks for pre-mutation setup, post-mutation cache invalidation,
/// and error rollback in a single declaration.
///
/// ## Lifecycle
///
/// 1. [onMutate] — Called before the mutation. Returns optional rollback context.
/// 2. Mutation executes (save/delete).
/// 3a. [onSuccess] — Called if mutation succeeds. Receives result and context.
/// 3b. [onError] — Called if mutation fails. Receives error and context.
/// 4. [onSettled] — Always called after success or error.
/// 5. [invalidateTags] — Cache tags to invalidate on success only.
///
/// ## Example
///
/// ```dart
/// await store.mutate(
///   updatedUser,
///   options: MutationOptions(
///     onMutate: () async {
///       final previous = await store.get(updatedUser.id);
///       return previous; // rollback context
///     },
///     onSuccess: (result, context) async {
///       print('User updated: ${result.name}');
///     },
///     onError: (error, context) async {
///       if (context != null) {
///         await store.save(context); // rollback
///       }
///     },
///     invalidateTags: {'users', 'user-list'},
///   ),
/// );
/// ```
@immutable
class MutationOptions<T> {
  /// Creates mutation options.
  const MutationOptions({
    this.onMutate,
    this.onSuccess,
    this.onError,
    this.onSettled,
    this.invalidateTags,
  });

  /// Called before the mutation executes.
  ///
  /// Returns an optional context object that is passed to [onSuccess],
  /// [onError], and [onSettled]. Useful for storing rollback data.
  final Future<Object?> Function()? onMutate;

  /// Called after a successful mutation.
  ///
  /// Receives the mutation result and the context from [onMutate].
  final Future<void> Function(T result, Object? context)? onSuccess;

  /// Called when the mutation fails.
  ///
  /// Receives the error and the context from [onMutate].
  final Future<void> Function(Object error, Object? context)? onError;

  /// Called after the mutation completes, regardless of success or failure.
  ///
  /// Receives the context from [onMutate].
  final Future<void> Function(Object? context)? onSettled;

  /// Cache tags to invalidate after a successful mutation.
  ///
  /// Tags are NOT invalidated on error.
  final Set<String>? invalidateTags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MutationOptions<T> &&
          runtimeType == other.runtimeType &&
          onMutate == other.onMutate &&
          onSuccess == other.onSuccess &&
          onError == other.onError &&
          onSettled == other.onSettled &&
          _setsEqual(invalidateTags, other.invalidateTags);

  @override
  int get hashCode => Object.hash(
        onMutate,
        onSuccess,
        onError,
        onSettled,
        invalidateTags == null ? null : Object.hashAll(invalidateTags!),
      );

  static bool _setsEqual<E>(Set<E>? a, Set<E>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
