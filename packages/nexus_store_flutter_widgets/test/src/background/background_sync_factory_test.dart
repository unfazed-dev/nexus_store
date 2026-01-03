import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store_flutter_widgets/src/background/background_sync_factory.dart';
import 'package:nexus_store_flutter_widgets/src/background/background_sync_service.dart';
import 'package:nexus_store_flutter_widgets/src/background/no_op_sync_service.dart';
import 'package:nexus_store_flutter_widgets/src/background/work_manager_sync_service.dart';

void main() {
  group('BackgroundSyncServiceFactory', () {
    group('create', () {
      test('returns WorkManagerSyncService when platform is Android', () {
        final service = BackgroundSyncServiceFactory.create(
          isAndroid: true,
          isIOS: false,
        );

        expect(service, isA<WorkManagerSyncService>());
      });

      test('returns WorkManagerSyncService when platform is iOS', () {
        final service = BackgroundSyncServiceFactory.create(
          isAndroid: false,
          isIOS: true,
        );

        expect(service, isA<WorkManagerSyncService>());
      });

      test('returns NoOpSyncService when platform is neither', () {
        final service = BackgroundSyncServiceFactory.create(
          isAndroid: false,
          isIOS: false,
        );

        expect(service, isA<NoOpSyncService>());
      });

      test('returns NoOpSyncService for web platform', () {
        // Simulating web platform (not Android, not iOS)
        final service = BackgroundSyncServiceFactory.create(
          isAndroid: false,
          isIOS: false,
        );

        expect(service, isA<NoOpSyncService>());
        expect(service.isSupported, isFalse);
      });

      test('returns NoOpSyncService for desktop platforms', () {
        // Simulating desktop platform (not Android, not iOS)
        final service = BackgroundSyncServiceFactory.create(
          isAndroid: false,
          isIOS: false,
        );

        expect(service, isA<NoOpSyncService>());
      });
    });

    group('returned service', () {
      test('Android service is supported', () {
        final service = BackgroundSyncServiceFactory.create(
          isAndroid: true,
          isIOS: false,
        );

        expect(service.isSupported, isTrue);
      });

      test('iOS service is supported', () {
        final service = BackgroundSyncServiceFactory.create(
          isAndroid: false,
          isIOS: true,
        );

        expect(service.isSupported, isTrue);
      });

      test('unsupported platform service is not supported', () {
        final service = BackgroundSyncServiceFactory.create(
          isAndroid: false,
          isIOS: false,
        );

        expect(service.isSupported, isFalse);
      });

      test('returned service implements BackgroundSyncService', () {
        final androidService = BackgroundSyncServiceFactory.create(
          isAndroid: true,
          isIOS: false,
        );
        final iosService = BackgroundSyncServiceFactory.create(
          isAndroid: false,
          isIOS: true,
        );
        final otherService = BackgroundSyncServiceFactory.create(
          isAndroid: false,
          isIOS: false,
        );

        expect(androidService, isA<BackgroundSyncService>());
        expect(iosService, isA<BackgroundSyncService>());
        expect(otherService, isA<BackgroundSyncService>());
      });
    });

    group('singleton behavior', () {
      test('each call creates a new instance', () {
        final service1 = BackgroundSyncServiceFactory.create(
          isAndroid: true,
          isIOS: false,
        );
        final service2 = BackgroundSyncServiceFactory.create(
          isAndroid: true,
          isIOS: false,
        );

        expect(identical(service1, service2), isFalse);
      });
    });

    group('default platform detection', () {
      test('create without parameters uses platform detection', () {
        // Calling create() without parameters uses the internal _isAndroid
        // and _isIOS getters which check Platform.isAndroid and Platform.isIOS.
        // On desktop test runners, both return false,
        // so we get NoOpSyncService.
        final service = BackgroundSyncServiceFactory.create();

        // On non-mobile platforms (where unit tests run), this returns NoOp
        expect(service, isA<BackgroundSyncService>());
        // On desktop/web test environments, mobile platforms are not detected
        expect(service, isA<NoOpSyncService>());
      });

      test('create with null android uses platform detection', () {
        // isAndroid is null, so it falls back to _isAndroid getter
        final service = BackgroundSyncServiceFactory.create(
          isIOS: false,
        );

        // On desktop test runner, Platform.isAndroid returns false
        expect(service, isA<NoOpSyncService>());
      });

      test('create with null iOS uses platform detection', () {
        // isIOS is null, so it falls back to _isIOS getter
        final service = BackgroundSyncServiceFactory.create(
          isAndroid: false,
        );

        // On desktop test runner, Platform.isIOS returns false
        expect(service, isA<NoOpSyncService>());
      });

      test('create with both null uses platform detection for both', () {
        // Both are null, so both fall back to their respective getters
        final service = BackgroundSyncServiceFactory.create(
          
        );

        // On desktop test runner, both Platform checks return false
        expect(service, isA<NoOpSyncService>());
      });
    });
  });
}
