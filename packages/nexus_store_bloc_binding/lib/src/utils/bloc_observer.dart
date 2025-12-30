import 'package:bloc/bloc.dart';

/// A [BlocObserver] for NexusStore blocs and cubits that provides
/// configurable logging.
///
/// This observer can log transitions, events, errors, and lifecycle events
/// for debugging and monitoring purposes.
///
/// Example:
/// ```dart
/// // Configure globally
/// Bloc.observer = NexusStoreBlocObserver(
///   logTransitions: true,
///   logEvents: true,
///   logErrors: true,
///   onLog: (message) => debugPrint(message),
/// );
///
/// // Or use with a custom logger
/// Bloc.observer = NexusStoreBlocObserver(
///   onLog: (message) => myLogger.info(message),
/// );
/// ```
class NexusStoreBlocObserver extends BlocObserver {
  /// Creates a NexusStoreBlocObserver with configurable logging.
  ///
  /// - [logTransitions] - Whether to log state transitions (default: true)
  /// - [logEvents] - Whether to log events (default: true)
  /// - [logErrors] - Whether to log errors (default: true)
  /// - [onLog] - Custom log handler (default: print)
  NexusStoreBlocObserver({
    this.logTransitions = true,
    this.logEvents = true,
    this.logErrors = true,
    void Function(String message)? onLog,
  }) : _onLog = onLog ?? print;

  /// Whether to log state transitions.
  final bool logTransitions;

  /// Whether to log events.
  final bool logEvents;

  /// Whether to log errors.
  final bool logErrors;

  final void Function(String message) _onLog;

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _onLog('[NexusStore] Created: ${bloc.runtimeType}');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _onLog('[NexusStore] Closed: ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (logEvents) {
      _onLog('[NexusStore] Event: ${bloc.runtimeType} -> $event');
    }
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (logTransitions) {
      _onLog(
        '[NexusStore] Change: ${bloc.runtimeType} | '
        '${change.currentState.runtimeType} -> ${change.nextState.runtimeType}',
      );
    }
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (logTransitions) {
      _onLog(
        '[NexusStore] Transition: ${bloc.runtimeType} | '
        '${transition.event.runtimeType}: '
        '${transition.currentState.runtimeType} -> '
        '${transition.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (logErrors) {
      _onLog(
        '[NexusStore] Error: ${bloc.runtimeType} | $error\n$stackTrace',
      );
    }
  }
}
