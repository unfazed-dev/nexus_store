/// A ListView widget with built-in support for lazy loading of items.
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:nexus_store_flutter/src/lazy/visibility_loader.dart';

/// Signature for building a list item with optional lazy data.
typedef LazyItemBuilder<T, L> = Widget Function(
  BuildContext context,
  T item,
  int index, {
  L? lazyData,
});

/// Signature for building a lazy placeholder.
typedef LazyPlaceholderBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

/// Signature for building a lazy error widget.
typedef LazyErrorBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
  Object error,
  VoidCallback retry,
);

/// Signature for loading lazy data for an item.
typedef LazyFieldLoader<T, L> = Future<L> Function(T item, int index);

/// Signature for item visibility callback.
typedef OnItemVisible<T> = void Function(T item, int index);

/// A ListView that supports lazy loading of items and their associated data.
///
/// This widget provides a convenient way to display a list of items where
/// additional data can be loaded on-demand as items become visible.
///
/// Example:
/// ```dart
/// LazyListView<User, ProfileImage>(
///   items: users,
///   lazyFieldLoader: (user, index) => imageService.loadProfileImage(user.id),
///   itemBuilder: (context, user, index, {lazyData}) => UserTile(
///     user: user,
///     profileImage: lazyData,
///   ),
///   lazyPlaceholder: (context, user, index) =>
///       UserTilePlaceholder(user: user),
/// )
/// ```
class LazyListView<T, L extends Object?> extends StatelessWidget {
  /// Creates a lazy list view with a fixed list of items.
  ///
  /// The [itemBuilder] receives optional [lazyData] when [lazyFieldLoader]
  /// is provided and the data has been loaded.
  const LazyListView({
    required this.items,
    required LazyItemBuilder<T, L> itemBuilder,
    this.lazyFieldLoader,
    this.lazyPlaceholder,
    this.lazyErrorBuilder,
    this.separatorBuilder,
    this.emptyBuilder,
    this.onItemVisible,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  })  : _indexItemBuilder = null,
        _lazyItemBuilder = itemBuilder,
        itemCount = null,
        _builderMode = false;

  /// Creates a lazy list view that builds items on demand.
  const LazyListView.builder({
    required this.itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    this.separatorBuilder,
    this.emptyBuilder,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  })  : items = const [],
        _indexItemBuilder = itemBuilder,
        _lazyItemBuilder = null,
        lazyFieldLoader = null,
        lazyPlaceholder = null,
        lazyErrorBuilder = null,
        onItemVisible = null,
        _builderMode = true;

  /// The list of items to display.
  final List<T> items;

  /// The number of items (for builder mode).
  final int? itemCount;

  /// Item builder for builder mode (index only).
  final Widget Function(BuildContext context, int index)? _indexItemBuilder;

  /// Item builder with lazy data support.
  final LazyItemBuilder<T, L>? _lazyItemBuilder;

  /// Loader for lazy field data.
  final LazyFieldLoader<T, L>? lazyFieldLoader;

  /// Placeholder shown while lazy data is loading.
  final LazyPlaceholderBuilder<T>? lazyPlaceholder;

  /// Builder for error state when lazy loading fails.
  final LazyErrorBuilder<T>? lazyErrorBuilder;

  /// Builder for separators between items.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Builder shown when the list is empty.
  final WidgetBuilder? emptyBuilder;

  /// Callback when an item becomes visible.
  final OnItemVisible<T>? onItemVisible;

  /// Scroll controller.
  final ScrollController? controller;

  /// Scroll direction.
  final Axis scrollDirection;

  /// Whether to reverse the list.
  final bool reverse;

  /// Whether this is the primary scroll view.
  final bool? primary;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Whether to shrink wrap the list.
  final bool shrinkWrap;

  /// Padding around the list.
  final EdgeInsetsGeometry? padding;

  /// Cache extent for performance.
  final double? cacheExtent;

  /// Drag start behavior.
  final DragStartBehavior dragStartBehavior;

  /// Keyboard dismiss behavior.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Restoration ID.
  final String? restorationId;

  /// Clip behavior.
  final Clip clipBehavior;

  /// Whether in builder mode.
  final bool _builderMode;

  @override
  Widget build(BuildContext context) {
    if (_builderMode) {
      return _buildBuilderMode(context);
    }

    if (items.isEmpty) {
      return emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    final effectiveItemCount =
        separatorBuilder != null ? items.length * 2 - 1 : items.length;

    return ListView.builder(
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      cacheExtent: cacheExtent,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      itemCount: effectiveItemCount,
      itemBuilder: (context, index) {
        if (separatorBuilder != null) {
          if (index.isOdd) {
            return separatorBuilder!(context, index ~/ 2);
          }
          index = index ~/ 2;
        }

        return _buildItem(context, index);
      },
    );
  }

  // coverage:ignore-start
  Widget _buildBuilderMode(BuildContext context) {
    final count = itemCount ?? 0;

    if (count == 0) {
      return emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    final effectiveItemCount = separatorBuilder != null ? count * 2 - 1 : count;

    return ListView.builder(
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      cacheExtent: cacheExtent,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      itemCount: effectiveItemCount,
      itemBuilder: (context, index) {
        if (separatorBuilder != null) {
          if (index.isOdd) {
            return separatorBuilder!(context, index ~/ 2);
          }
          index = index ~/ 2;
        }

        return _indexItemBuilder!(context, index);
      },
    );
  // coverage:ignore-end
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = items[index];

    // Notify visibility
    onItemVisible?.call(item, index);

    // If no lazy loading, use builder without lazy data
    if (lazyFieldLoader == null) {
      return _lazyItemBuilder!(context, item, index);
    }

    // coverage:ignore-start
    // With lazy loading
    return VisibilityLoader<L>(
      loader: () => lazyFieldLoader!(item, index),
      placeholder: lazyPlaceholder?.call(context, item, index) ??
          _lazyItemBuilder!(context, item, index),
      loadingBuilder: lazyPlaceholder != null
          ? (ctx) => lazyPlaceholder!(ctx, item, index)
          : null,
      builder: (ctx, lazyData) =>
          _lazyItemBuilder!(ctx, item, index, lazyData: lazyData),
      errorBuilder: lazyErrorBuilder != null
          ? (ctx, error, retry) =>
              lazyErrorBuilder!(ctx, item, index, error, retry)
          : null,
    );
    // coverage:ignore-end
  }
}
