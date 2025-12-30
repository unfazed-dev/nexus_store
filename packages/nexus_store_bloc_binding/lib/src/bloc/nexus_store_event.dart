import 'package:collection/collection.dart';
import 'package:nexus_store/nexus_store.dart';

/// Base sealed class for [NexusStoreBloc] events.
///
/// All events that can be added to a [NexusStoreBloc] extend this class.
sealed class NexusStoreEvent<T, ID> {
  const NexusStoreEvent();
}

/// Event to load all items from the store.
///
/// Optionally accepts a [query] to filter and sort results.
final class LoadAll<T, ID> extends NexusStoreEvent<T, ID> {
  /// Creates a LoadAll event with an optional query.
  const LoadAll({this.query});

  /// Optional query to filter/sort results.
  final Query<T>? query;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadAll<T, ID> &&
          runtimeType == other.runtimeType &&
          query == other.query;

  @override
  int get hashCode => Object.hash(runtimeType, query);

  @override
  String toString() => 'LoadAll<$T, $ID>(query: $query)';
}

/// Event to save a single item to the store.
final class Save<T, ID> extends NexusStoreEvent<T, ID> {
  /// Creates a Save event with the item to save.
  const Save(
    this.item, {
    this.policy,
    this.tags,
  });

  /// The item to save.
  final T item;

  /// Optional write policy.
  final WritePolicy? policy;

  /// Optional tags for the item.
  final Set<String>? tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Save<T, ID> &&
          runtimeType == other.runtimeType &&
          item == other.item &&
          policy == other.policy &&
          const SetEquality<String>().equals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        item,
        policy,
        tags == null ? null : const SetEquality<String>().hash(tags!),
      );

  @override
  String toString() =>
      'Save<$T, $ID>(item: $item, policy: $policy, tags: $tags)';
}

/// Event to save multiple items to the store.
final class SaveAll<T, ID> extends NexusStoreEvent<T, ID> {
  /// Creates a SaveAll event with the items to save.
  const SaveAll(
    this.items, {
    this.policy,
    this.tags,
  });

  /// The items to save.
  final List<T> items;

  /// Optional write policy.
  final WritePolicy? policy;

  /// Optional tags for the items.
  final Set<String>? tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveAll<T, ID> &&
          runtimeType == other.runtimeType &&
          const ListEquality<dynamic>().equals(items, other.items) &&
          policy == other.policy &&
          const SetEquality<String>().equals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        const ListEquality<dynamic>().hash(items),
        policy,
        tags == null ? null : const SetEquality<String>().hash(tags!),
      );

  @override
  String toString() =>
      'SaveAll<$T, $ID>(items: $items, policy: $policy, tags: $tags)';
}

/// Event to delete an item from the store by ID.
final class Delete<T, ID> extends NexusStoreEvent<T, ID> {
  /// Creates a Delete event with the ID to delete.
  const Delete(
    this.id, {
    this.policy,
  });

  /// The ID of the item to delete.
  final ID id;

  /// Optional write policy.
  final WritePolicy? policy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Delete<T, ID> &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          policy == other.policy;

  @override
  int get hashCode => Object.hash(runtimeType, id, policy);

  @override
  String toString() => 'Delete<$T, $ID>(id: $id, policy: $policy)';
}

/// Event to delete multiple items from the store by IDs.
final class DeleteAll<T, ID> extends NexusStoreEvent<T, ID> {
  /// Creates a DeleteAll event with the IDs to delete.
  const DeleteAll(
    this.ids, {
    this.policy,
  });

  /// The IDs of the items to delete.
  final List<ID> ids;

  /// Optional write policy.
  final WritePolicy? policy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteAll<T, ID> &&
          runtimeType == other.runtimeType &&
          const ListEquality<dynamic>().equals(ids, other.ids) &&
          policy == other.policy;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        const ListEquality<dynamic>().hash(ids),
        policy,
      );

  @override
  String toString() => 'DeleteAll<$T, $ID>(ids: $ids, policy: $policy)';
}

/// Event to refresh the store data.
final class Refresh<T, ID> extends NexusStoreEvent<T, ID> {
  /// Creates a Refresh event.
  const Refresh();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Refresh<T, ID> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Refresh<$T, $ID>()';
}

// Internal events used by NexusStoreBloc

/// Internal event emitted when data is received from the stream.
final class DataReceived<T, ID> extends NexusStoreEvent<T, ID> {
  /// Creates a DataReceived event with the received data.
  const DataReceived(this.data);

  /// The received data.
  final List<T> data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataReceived<T, ID> &&
          runtimeType == other.runtimeType &&
          const ListEquality<dynamic>().equals(data, other.data);

  @override
  int get hashCode =>
      Object.hash(runtimeType, const ListEquality<dynamic>().hash(data));

  @override
  String toString() => 'DataReceived<$T, $ID>(data: $data)';
}

/// Internal event emitted when an error is received from the stream.
final class ErrorReceived<T, ID> extends NexusStoreEvent<T, ID> {
  /// Creates an ErrorReceived event with the error and stack trace.
  const ErrorReceived(this.error, this.stackTrace);

  /// The error that occurred.
  final Object error;

  /// The stack trace of the error.
  final StackTrace stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorReceived<T, ID> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => Object.hash(runtimeType, error, stackTrace);

  @override
  String toString() =>
      'ErrorReceived<$T, $ID>(error: $error, stackTrace: $stackTrace)';
}
