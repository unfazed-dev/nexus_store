import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_store/src/reliability/degradation_mode.dart';

void main() {
  group('DegradationMode', () {
    group('values', () {
      test('has normal mode', () {
        expect(DegradationMode.normal, isNotNull);
      });

      test('has cacheOnly mode', () {
        expect(DegradationMode.cacheOnly, isNotNull);
      });

      test('has readOnly mode', () {
        expect(DegradationMode.readOnly, isNotNull);
      });

      test('has offline mode', () {
        expect(DegradationMode.offline, isNotNull);
      });

      test('has exactly 4 values', () {
        expect(DegradationMode.values.length, equals(4));
      });
    });

    group('isNormal', () {
      test('returns true for normal mode', () {
        expect(DegradationMode.normal.isNormal, isTrue);
      });

      test('returns false for other modes', () {
        expect(DegradationMode.cacheOnly.isNormal, isFalse);
        expect(DegradationMode.readOnly.isNormal, isFalse);
        expect(DegradationMode.offline.isNormal, isFalse);
      });
    });

    group('isCacheOnly', () {
      test('returns true for cacheOnly mode', () {
        expect(DegradationMode.cacheOnly.isCacheOnly, isTrue);
      });

      test('returns false for other modes', () {
        expect(DegradationMode.normal.isCacheOnly, isFalse);
        expect(DegradationMode.readOnly.isCacheOnly, isFalse);
        expect(DegradationMode.offline.isCacheOnly, isFalse);
      });
    });

    group('isReadOnly', () {
      test('returns true for readOnly mode', () {
        expect(DegradationMode.readOnly.isReadOnly, isTrue);
      });

      test('returns false for other modes', () {
        expect(DegradationMode.normal.isReadOnly, isFalse);
        expect(DegradationMode.cacheOnly.isReadOnly, isFalse);
        expect(DegradationMode.offline.isReadOnly, isFalse);
      });
    });

    group('isOffline', () {
      test('returns true for offline mode', () {
        expect(DegradationMode.offline.isOffline, isTrue);
      });

      test('returns false for other modes', () {
        expect(DegradationMode.normal.isOffline, isFalse);
        expect(DegradationMode.cacheOnly.isOffline, isFalse);
        expect(DegradationMode.readOnly.isOffline, isFalse);
      });
    });

    group('isDegraded', () {
      test('returns false for normal mode', () {
        expect(DegradationMode.normal.isDegraded, isFalse);
      });

      test('returns true for all other modes', () {
        expect(DegradationMode.cacheOnly.isDegraded, isTrue);
        expect(DegradationMode.readOnly.isDegraded, isTrue);
        expect(DegradationMode.offline.isDegraded, isTrue);
      });
    });

    group('allowsReads', () {
      test('returns true for normal mode', () {
        expect(DegradationMode.normal.allowsReads, isTrue);
      });

      test('returns true for cacheOnly mode', () {
        expect(DegradationMode.cacheOnly.allowsReads, isTrue);
      });

      test('returns true for readOnly mode', () {
        expect(DegradationMode.readOnly.allowsReads, isTrue);
      });

      test('returns false for offline mode', () {
        expect(DegradationMode.offline.allowsReads, isFalse);
      });
    });

    group('allowsWrites', () {
      test('returns true for normal mode', () {
        expect(DegradationMode.normal.allowsWrites, isTrue);
      });

      test('returns false for cacheOnly mode', () {
        expect(DegradationMode.cacheOnly.allowsWrites, isFalse);
      });

      test('returns false for readOnly mode', () {
        expect(DegradationMode.readOnly.allowsWrites, isFalse);
      });

      test('returns false for offline mode', () {
        expect(DegradationMode.offline.allowsWrites, isFalse);
      });
    });

    group('allowsBackendCalls', () {
      test('returns true for normal mode', () {
        expect(DegradationMode.normal.allowsBackendCalls, isTrue);
      });

      test('returns false for cacheOnly mode', () {
        expect(DegradationMode.cacheOnly.allowsBackendCalls, isFalse);
      });

      test('returns true for readOnly mode', () {
        expect(DegradationMode.readOnly.allowsBackendCalls, isTrue);
      });

      test('returns false for offline mode', () {
        expect(DegradationMode.offline.allowsBackendCalls, isFalse);
      });
    });

    group('isWorseThan', () {
      test('normal is not worse than any mode', () {
        expect(DegradationMode.normal.isWorseThan(DegradationMode.normal),
            isFalse);
        expect(DegradationMode.normal.isWorseThan(DegradationMode.cacheOnly),
            isFalse);
        expect(
            DegradationMode.normal.isWorseThan(DegradationMode.readOnly), isFalse);
        expect(
            DegradationMode.normal.isWorseThan(DegradationMode.offline), isFalse);
      });

      test('cacheOnly is worse than normal', () {
        expect(DegradationMode.cacheOnly.isWorseThan(DegradationMode.normal),
            isTrue);
      });

      test('readOnly is worse than cacheOnly', () {
        expect(DegradationMode.readOnly.isWorseThan(DegradationMode.cacheOnly),
            isTrue);
      });

      test('offline is worse than all other modes', () {
        expect(DegradationMode.offline.isWorseThan(DegradationMode.normal),
            isTrue);
        expect(DegradationMode.offline.isWorseThan(DegradationMode.cacheOnly),
            isTrue);
        expect(DegradationMode.offline.isWorseThan(DegradationMode.readOnly),
            isTrue);
      });
    });

    group('worst', () {
      test('returns offline when comparing all modes', () {
        expect(
          DegradationMode.worst([
            DegradationMode.normal,
            DegradationMode.cacheOnly,
            DegradationMode.readOnly,
            DegradationMode.offline,
          ]),
          equals(DegradationMode.offline),
        );
      });

      test('returns readOnly when comparing without offline', () {
        expect(
          DegradationMode.worst([
            DegradationMode.normal,
            DegradationMode.cacheOnly,
            DegradationMode.readOnly,
          ]),
          equals(DegradationMode.readOnly),
        );
      });

      test('returns normal for empty list', () {
        expect(DegradationMode.worst([]), equals(DegradationMode.normal));
      });

      test('returns normal when all normal', () {
        expect(
          DegradationMode.worst([DegradationMode.normal, DegradationMode.normal]),
          equals(DegradationMode.normal),
        );
      });
    });
  });
}
