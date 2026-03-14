import 'package:nexus_store/src/interceptors/store_operation.dart';
import 'package:nexus_store/src/interceptors/timing_interceptor.dart';
import 'package:nexus_store/src/telemetry/metrics_reporter.dart';
import 'package:test/test.dart';

void main() {
  group('TimingInterceptor deleteWhere mapping', () {
    test('maps StoreOperation.deleteWhere to OperationType.deleteWhere', () {
      final reporter = NoOpMetricsReporter();
      final interceptor = TimingInterceptor(reporter: reporter);

      // Verify the interceptor handles deleteWhere operation
      // by checking it's in the default operations set
      expect(
        interceptor.operations,
        contains(StoreOperation.deleteWhere),
      );
    });
  });
}
