import 'package:nexus_store/src/telemetry/operation_metric.dart';
import 'package:test/test.dart';

void main() {
  group('OperationType.deleteWhere', () {
    test('deleteWhere enum value exists', () {
      expect(OperationType.deleteWhere, isNotNull);
      expect(
        OperationType.values,
        contains(OperationType.deleteWhere),
      );
    });
  });
}
