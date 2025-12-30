import 'package:collection/collection.dart';
import 'package:nexus_store/nexus_store.dart';

/// Base sealed class for [NexusItemBloc] events.
///
/// All events that can be added to a [NexusItemBloc] extend this class.
sealed class NexusItemEvent<T, ID> {
  const NexusItemEvent();
}

/// Event to load the item from the store.
final class LoadItem<T, ID> extends NexusItemEvent<T, ID> {
  /// Creates a LoadItem event.
  const LoadItem();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadItem<T, ID> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'LoadItem<$T, $ID>()';
}

/// Event to save an item to the store.
final class SaveItem<T, ID> extends NexusItemEvent<T, ID> {
  /// Creates a SaveItem event with the item to save.
  const SaveItem(
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
      other is SaveItem<T, ID> &&
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
      'SaveItem<$T, $ID>(item: $item, policy: $policy, tags: $tags)';
}

/// Event to delete the item from the store.
final class DeleteItem<T, ID> extends NexusItemEvent<T, ID> {
  /// Creates a DeleteItem event.
  const DeleteItem({this.policy});

  /// Optional write policy.
  final WritePolicy? policy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteItem<T, ID> &&
          runtimeType == other.runtimeType &&
          policy == other.policy;

  @override
  int get hashCode => Object.hash(runtimeType, policy);

  @override
  String toString() => 'DeleteItem<$T, $ID>(policy: $policy)';
}

/// Event to refresh the item data.
final class RefreshItem<T, ID> extends NexusItemEvent<T, ID> {
  /// Creates a RefreshItem event.
  const RefreshItem();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefreshItem<T, ID> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'RefreshItem<$T, $ID>()';
}

// Internal events used by NexusItemBloc

/// Internal event emitted when data is received from the stream.
final class ItemDataReceived<T, ID> extends NexusItemEvent<T, ID> {
  /// Creates an ItemDataReceived event with the received data.
  const ItemDataReceived(this.data);

  /// The received data (null if not found).
  final T? data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemDataReceived<T, ID> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => Object.hash(runtimeType, data);

  @override
  String toString() => 'ItemDataReceived<$T, $ID>(data: $data)';
}

/// Internal event emitted when an error is received from the stream.
final class ItemErrorReceived<T, ID> extends NexusItemEvent<T, ID> {
  /// Creates an ItemErrorReceived event with the error and stack trace.
  const ItemErrorReceived(this.error, this.stackTrace);

  /// The error that occurred.
  final Object error;

  /// The stack trace of the error.
  final StackTrace stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemErrorReceived<T, ID> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => Object.hash(runtimeType, error, stackTrace);

  @override
  String toString() =>
      'ItemErrorReceived<$T, $ID>(error: $error, stackTrace: $stackTrace)';
}
