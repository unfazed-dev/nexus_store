import 'package:bloc/bloc.dart';
import 'package:nexus_store_bloc_binding/nexus_store_bloc_binding.dart';
import 'package:test/test.dart';

void main() {
  group('NexusStoreBlocObserver', () {
    group('constructor', () {
      test('should create with default settings', () {
        final observer = NexusStoreBlocObserver();
        expect(observer, isNotNull);
        expect(observer.logTransitions, isTrue);
        expect(observer.logEvents, isTrue);
        expect(observer.logErrors, isTrue);
      });

      test('should create with custom settings', () {
        final observer = NexusStoreBlocObserver(
          logTransitions: false,
          logEvents: false,
          logErrors: false,
        );
        expect(observer.logTransitions, isFalse);
        expect(observer.logEvents, isFalse);
        expect(observer.logErrors, isFalse);
      });
    });

    group('onTransition', () {
      test('should call onLog when logTransitions is true', () {
        final logs = <String>[];
        final observer = NexusStoreBlocObserver(
          logTransitions: true,
          onLog: (message) => logs.add(message),
        );

        final bloc = _TestBloc();
        final transition = Transition<String, int>(
          currentState: 0,
          event: 'event',
          nextState: 1,
        );

        observer.onTransition(bloc, transition);

        expect(logs, hasLength(1));
        expect(logs.first, contains('Transition'));
        expect(logs.first, contains('_TestBloc'));

        bloc.close();
      });

      test('should not call onLog when logTransitions is false', () {
        final logs = <String>[];
        final observer = NexusStoreBlocObserver(
          logTransitions: false,
          onLog: (message) => logs.add(message),
        );

        final bloc = _TestBloc();
        final transition = Transition<String, int>(
          currentState: 0,
          event: 'event',
          nextState: 1,
        );

        observer.onTransition(bloc, transition);

        expect(logs, isEmpty);

        bloc.close();
      });
    });

    group('onEvent', () {
      test('should call onLog when logEvents is true', () {
        final logs = <String>[];
        final observer = NexusStoreBlocObserver(
          logEvents: true,
          onLog: (message) => logs.add(message),
        );

        final bloc = _TestBloc();

        observer.onEvent(bloc, 'test_event');

        expect(logs, hasLength(1));
        expect(logs.first, contains('Event'));
        expect(logs.first, contains('_TestBloc'));
        expect(logs.first, contains('test_event'));

        bloc.close();
      });

      test('should not call onLog when logEvents is false', () {
        final logs = <String>[];
        final observer = NexusStoreBlocObserver(
          logEvents: false,
          onLog: (message) => logs.add(message),
        );

        final bloc = _TestBloc();

        observer.onEvent(bloc, 'test_event');

        expect(logs, isEmpty);

        bloc.close();
      });
    });

    group('onError', () {
      test('should call onLog when logErrors is true', () {
        final logs = <String>[];
        final observer = NexusStoreBlocObserver(
          logErrors: true,
          onLog: (message) => logs.add(message),
        );

        final bloc = _TestBloc();
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;

        observer.onError(bloc, error, stackTrace);

        expect(logs, hasLength(1));
        expect(logs.first, contains('Error'));
        expect(logs.first, contains('_TestBloc'));
        expect(logs.first, contains('Test error'));

        bloc.close();
      });

      test('should not call onLog when logErrors is false', () {
        final logs = <String>[];
        final observer = NexusStoreBlocObserver(
          logErrors: false,
          onLog: (message) => logs.add(message),
        );

        final bloc = _TestBloc();
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;

        observer.onError(bloc, error, stackTrace);

        expect(logs, isEmpty);

        bloc.close();
      });
    });

    group('onCreate', () {
      test('should call onLog with creation message', () {
        final logs = <String>[];
        final observer = NexusStoreBlocObserver(
          onLog: (message) => logs.add(message),
        );

        final bloc = _TestBloc();

        observer.onCreate(bloc);

        expect(logs, hasLength(1));
        expect(logs.first, contains('Created'));
        expect(logs.first, contains('_TestBloc'));

        bloc.close();
      });
    });

    group('onClose', () {
      test('should call onLog with close message', () {
        final logs = <String>[];
        final observer = NexusStoreBlocObserver(
          onLog: (message) => logs.add(message),
        );

        final bloc = _TestBloc();

        observer.onClose(bloc);

        expect(logs, hasLength(1));
        expect(logs.first, contains('Closed'));
        expect(logs.first, contains('_TestBloc'));

        bloc.close();
      });
    });

    group('onChange', () {
      test('should call onLog with change message for Cubit', () {
        final logs = <String>[];
        final observer = NexusStoreBlocObserver(
          logTransitions: true,
          onLog: (message) => logs.add(message),
        );

        final cubit = _TestCubit();
        final change = Change<int>(currentState: 0, nextState: 1);

        observer.onChange(cubit, change);

        expect(logs, hasLength(1));
        expect(logs.first, contains('Change'));
        expect(logs.first, contains('_TestCubit'));

        cubit.close();
      });
    });

    group('default onLog', () {
      test('should use print when no onLog is provided', () {
        // This test just verifies no exception is thrown
        final observer = NexusStoreBlocObserver();
        final bloc = _TestBloc();

        // These should not throw
        expect(
          () => observer.onCreate(bloc),
          returnsNormally,
        );
        expect(
          () => observer.onClose(bloc),
          returnsNormally,
        );

        bloc.close();
      });
    });
  });
}

/// Test bloc for observer tests
class _TestBloc extends Bloc<String, int> {
  _TestBloc() : super(0) {
    on<String>((event, emit) => emit(state + 1));
  }
}

/// Test cubit for observer tests
class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);

  void increment() => emit(state + 1);
}
