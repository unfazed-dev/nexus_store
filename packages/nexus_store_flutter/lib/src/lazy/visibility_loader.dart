/// A widget that loads data on-demand with visibility-based triggering.
library;

import 'dart:async';

import 'package:flutter/material.dart';

/// State of the visibility loader.
enum VisibilityLoaderState {
  /// Initial state, not yet loaded.
  idle,

  /// Currently loading data.
  loading,

  /// Data loaded successfully.
  loaded,

  /// Loading failed with an error.
  error,
}

/// Controller for managing [VisibilityLoader] state.
///
/// Use this controller to programmatically trigger loading, reloading,
/// or resetting the loader state.
///
/// Example:
/// ```dart
/// final controller = VisibilityLoaderController();
///
/// VisibilityLoader<User>(
///   controller: controller,
///   loader: () => api.fetchUser(),
///   // ...
/// )
///
/// // Later, to reload:
/// controller.reload();
/// ```
class VisibilityLoaderController extends ChangeNotifier {
  VisibilityLoaderState _state = VisibilityLoaderState.idle;
  _ControllerAction? _pendingAction;

  /// Current state of the loader.
  VisibilityLoaderState get state => _state;

  /// Whether the loader is currently loading.
  bool get isLoading => _state == VisibilityLoaderState.loading;

  /// Whether data has been loaded.
  bool get isLoaded => _state == VisibilityLoaderState.loaded;

  /// Triggers a load if not already loaded.
  void load() {
    _pendingAction = _ControllerAction.load;
    notifyListeners();
  }

  /// Forces a reload, even if already loaded.
  void reload() {
    _pendingAction = _ControllerAction.reload;
    notifyListeners();
  }

  /// Resets the loader to its initial state.
  void reset() {
    _state = VisibilityLoaderState.idle;
    _pendingAction = _ControllerAction.reset;
    notifyListeners();
  }

  // ignore: use_setters_to_change_properties
  void _setState(VisibilityLoaderState state) {
    _state = state;
  }

  _ControllerAction? _consumeAction() {
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }
}

enum _ControllerAction { load, reload, reset }

/// A widget that loads data on-demand with visibility-based triggering.
///
/// This widget provides a flexible way to load data asynchronously with
/// built-in support for loading states, error handling, and retry
/// functionality.
///
/// Example:
/// ```dart
/// VisibilityLoader<User>(
///   loader: () => userRepository.fetchUser(id),
///   placeholder: CircularProgressIndicator(),
///   builder: (context, user) => UserCard(user: user),
///   errorBuilder: (context, error, retry) => ErrorWidget(
///     error: error,
///     onRetry: retry,
///   ),
/// )
/// ```
class VisibilityLoader<T> extends StatefulWidget {
  /// Creates a visibility loader widget.
  const VisibilityLoader({
    required this.loader,
    required this.placeholder,
    required this.builder,
    this.controller,
    this.loadingBuilder,
    this.errorBuilder,
    this.triggerOnBuild = true,
    this.loadOnce = false,
    super.key,
  });

  /// The async function that loads the data.
  final Future<T> Function() loader;

  /// Widget to show before loading starts.
  final Widget placeholder;

  /// Builder for the loaded data.
  final Widget Function(BuildContext context, T data) builder;

  /// Optional controller for programmatic control.
  final VisibilityLoaderController? controller;

  /// Builder for the loading state.
  ///
  /// If not provided, [placeholder] is shown during loading.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for the error state.
  ///
  /// The [retry] callback can be used to retry loading.
  final Widget Function(
    BuildContext context,
    Object error,
    VoidCallback retry,
  )? errorBuilder;

  /// Whether to trigger loading when the widget is first built.
  ///
  /// Defaults to true.
  final bool triggerOnBuild;

  /// Whether to only load once and skip reloads on rebuild.
  ///
  /// When true, the widget will not reload data even if rebuilt.
  /// Use [VisibilityLoaderController.reload] to force a reload.
  final bool loadOnce;

  @override
  State<VisibilityLoader<T>> createState() => _VisibilityLoaderState<T>();
}

class _VisibilityLoaderState<T> extends State<VisibilityLoader<T>> {
  VisibilityLoaderState _state = VisibilityLoaderState.idle;
  T? _data;
  Object? _error;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleControllerAction);

    if (widget.triggerOnBuild) {
      _load();
    }
  }

  @override
  void didUpdateWidget(VisibilityLoader<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerAction);
      widget.controller?.addListener(_handleControllerAction);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerAction);
    super.dispose();
  }

  void _handleControllerAction() {
    final action = widget.controller?._consumeAction();
    if (action == null) return;

    switch (action) {
      case _ControllerAction.load:
        if (_state != VisibilityLoaderState.loaded) {
          _load();
        }
      case _ControllerAction.reload:
        _load();
      case _ControllerAction.reset:
        setState(() {
          _state = VisibilityLoaderState.idle;
          _data = null;
          _error = null;
          _hasLoadedOnce = false;
        });
    }
  }

  Future<void> _load() async {
    // Skip if loadOnce is true and we've already loaded
    if (widget.loadOnce &&
        _hasLoadedOnce &&
        _state == VisibilityLoaderState.loaded) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _state = VisibilityLoaderState.loading;
      _error = null;
    });
    widget.controller?._setState(VisibilityLoaderState.loading);

    try {
      final data = await widget.loader();

      if (!mounted) return;

      setState(() {
        _state = VisibilityLoaderState.loaded;
        _data = data;
        _hasLoadedOnce = true;
      });
      widget.controller?._setState(VisibilityLoaderState.loaded);
    } on Exception catch (e) {
      if (!mounted) return;

      setState(() {
        _state = VisibilityLoaderState.error;
        _error = e;
      });
      widget.controller?._setState(VisibilityLoaderState.error);
    }
  }

  void _retry() {
    _load();
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case VisibilityLoaderState.idle:
        return widget.placeholder;

      case VisibilityLoaderState.loading:
        return widget.loadingBuilder?.call(context) ?? widget.placeholder;

      case VisibilityLoaderState.loaded:
        return widget.builder(context, _data as T);

      case VisibilityLoaderState.error:
        if (widget.errorBuilder != null) {
          return widget.errorBuilder!(context, _error!, _retry);
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
    }
  }
}
