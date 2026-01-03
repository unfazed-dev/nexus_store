import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/nexus_store.dart';
import 'package:nexus_store_flutter_widgets/nexus_store_flutter_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterMemoryPressureHandler', () {
    late FlutterMemoryPressureHandler handler;

    setUp(() {
      handler = FlutterMemoryPressureHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    test('initial level is none', () {
      expect(handler.currentLevel, MemoryPressureLevel.none);
    });

    test('setLevel changes current level', () {
      handler.setLevel(MemoryPressureLevel.moderate);
      expect(handler.currentLevel, MemoryPressureLevel.moderate);

      handler.setLevel(MemoryPressureLevel.critical);
      expect(handler.currentLevel, MemoryPressureLevel.critical);
    });

    test('reset sets level back to none', () {
      handler.setLevel(MemoryPressureLevel.critical);
      expect(handler.currentLevel, MemoryPressureLevel.critical);

      handler.reset();
      expect(handler.currentLevel, MemoryPressureLevel.none);
    });

    test('triggerEmergency sets emergency level', () {
      handler.triggerEmergency();
      expect(handler.currentLevel, MemoryPressureLevel.emergency);
    });

    test('didHaveMemoryPressure sets critical level', () {
      handler.didHaveMemoryPressure();
      expect(handler.currentLevel, MemoryPressureLevel.critical);
    });

    test('pressureStream emits level changes', () async {
      final levels = <MemoryPressureLevel>[];
      final subscription = handler.pressureStream.listen(levels.add);

      handler
        ..setLevel(MemoryPressureLevel.moderate)
        ..setLevel(MemoryPressureLevel.critical)
        ..setLevel(MemoryPressureLevel.emergency);

      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();

      expect(
        levels,
        containsAllInOrder([
          MemoryPressureLevel.none,
          MemoryPressureLevel.moderate,
          MemoryPressureLevel.critical,
          MemoryPressureLevel.emergency,
        ]),
      );
    });

    test('pressureStream is distinct (no duplicate emissions)', () async {
      final levels = <MemoryPressureLevel>[];
      final subscription = handler.pressureStream.listen(levels.add);

      handler
        ..setLevel(MemoryPressureLevel.moderate)
        ..setLevel(MemoryPressureLevel.moderate)
        ..setLevel(MemoryPressureLevel.critical)
        ..setLevel(MemoryPressureLevel.critical);

      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();

      // Should only have unique transitions
      expect(
        levels,
        equals([
          MemoryPressureLevel.none,
          MemoryPressureLevel.moderate,
          MemoryPressureLevel.critical,
        ]),
      );
    });

    test('implements MemoryPressureHandler interface', () {
      expect(handler, isA<MemoryPressureHandler>());
    });
  });
}
