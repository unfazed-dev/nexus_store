/// The type of aggregate operation to perform on a numeric field.
///
/// Used with [StoreBackend.aggregate] and [NexusStore] convenience methods
/// (`sum`, `avg`, `min`, `max`) to compute aggregate values.
///
/// ## Example
///
/// ```dart
/// final total = await store.aggregate<User>(
///   'amount',
///   AggregateType.sum,
///   query: Query<User>().where('status', isEqualTo: 'completed'),
/// );
/// ```
enum AggregateType {
  /// Computes the sum of all values in the field.
  sum,

  /// Computes the average of all values in the field.
  avg,

  /// Finds the minimum value in the field.
  min,

  /// Finds the maximum value in the field.
  max,
}
