import 'dart:async';

import 'package:test/test.dart';
import 'package:nexus_store/src/cache/memory_pressure_level.dart';
import 'package:nexus_store/src/cache/memory_pressure_handler.dart';

void main() {
  group('MemoryPressureHandler', () {
    group('ThresholdMemoryPressureHandler', () {
      late ThresholdMemoryPressureHandler handler;

      setUp(() {
        handler = ThresholdMemoryPressureHandler(
          maxBytes: 1000,
          moderateThreshold: 0.7,
          criticalThreshold: 0.9,
        );
      });

      tearDown(() {
        handler.dispose();
      });

      test('initial level is none', () {
        expect(handler.currentLevel, equals(MemoryPressureLevel.none));
      });

      test('updateUsage with low usage keeps level at none', () {
        handler.updateUsage(500); // 50%
        expect(handler.currentLevel, equals(MemoryPressureLevel.none));
      });

      test('updateUsage at moderate threshold sets moderate level', () {
        handler.updateUsage(700); // 70%
        expect(handler.currentLevel, equals(MemoryPressureLevel.moderate));
      });

      test('updateUsage above moderate but below critical stays moderate', () {
        handler.updateUsage(850); // 85%
        expect(handler.currentLevel, equals(MemoryPressureLevel.moderate));
      });

      test('updateUsage at critical threshold sets critical level', () {
        handler.updateUsage(900); // 90%
        expect(handler.currentLevel, equals(MemoryPressureLevel.critical));
      });

      test('updateUsage above 100% sets emergency level', () {
        handler.updateUsage(1100); // 110%
        expect(handler.currentLevel, equals(MemoryPressureLevel.emergency));
      });

      test('pressureStream emits level changes', () async {
        final levels = <MemoryPressureLevel>[];
        final sub = handler.pressureStream.listen(levels.add);

        handler.updateUsage(500); // none
        handler.updateUsage(700); // moderate
        handler.updateUsage(900); // critical
        handler.updateUsage(500); // back to none

        await Future.delayed(Duration(milliseconds: 10));
        await sub.cancel();

        // Should emit: moderate, critical, none (skips duplicate none at start)
        expect(levels, contains(MemoryPressureLevel.moderate));
        expect(levels, contains(MemoryPressureLevel.critical));
        expect(levels, contains(MemoryPressureLevel.none));
      });

      test('pressureStream only emits on level changes', () async {
        final levels = <MemoryPressureLevel>[];
        final sub = handler.pressureStream.listen(levels.add);

        handler.updateUsage(700); // moderate
        handler.updateUsage(750); // still moderate
        handler.updateUsage(800); // still moderate

        await Future.delayed(Duration(milliseconds: 10));
        await sub.cancel();

        // Should only emit one moderate
        expect(
            levels.where((l) => l == MemoryPressureLevel.moderate), hasLength(1));
      });

      test('triggerEmergency sets emergency level', () {
        handler.triggerEmergency();
        expect(handler.currentLevel, equals(MemoryPressureLevel.emergency));
      });

      test('reset sets level back to none', () {
        handler.updateUsage(900);
        expect(handler.currentLevel, equals(MemoryPressureLevel.critical));

        handler.reset();
        expect(handler.currentLevel, equals(MemoryPressureLevel.none));
      });

      test('works with unlimited maxBytes (null)', () {
        final unlimitedHandler = ThresholdMemoryPressureHandler();

        // Should always be none since there's no limit
        unlimitedHandler.updateUsage(1000000);
        expect(unlimitedHandler.currentLevel, equals(MemoryPressureLevel.none));

        unlimitedHandler.dispose();
      });
    });

    group('ManualMemoryPressureHandler', () {
      late ManualMemoryPressureHandler handler;

      setUp(() {
        handler = ManualMemoryPressureHandler();
      });

      tearDown(() {
        handler.dispose();
      });

      test('initial level is none', () {
        expect(handler.currentLevel, equals(MemoryPressureLevel.none));
      });

      test('setLevel changes current level', () {
        handler.setLevel(MemoryPressureLevel.moderate);
        expect(handler.currentLevel, equals(MemoryPressureLevel.moderate));

        handler.setLevel(MemoryPressureLevel.critical);
        expect(handler.currentLevel, equals(MemoryPressureLevel.critical));
      });

      test('pressureStream emits level changes', () async {
        final levels = <MemoryPressureLevel>[];
        final sub = handler.pressureStream.listen(levels.add);

        handler.setLevel(MemoryPressureLevel.moderate);
        handler.setLevel(MemoryPressureLevel.critical);
        handler.setLevel(MemoryPressureLevel.none);

        await Future.delayed(Duration(milliseconds: 10));
        await sub.cancel();

        // Includes initial 'none' plus 3 changes
        expect(levels, hasLength(4));
        expect(levels, contains(MemoryPressureLevel.moderate));
        expect(levels, contains(MemoryPressureLevel.critical));
      });
    });
  });
}
