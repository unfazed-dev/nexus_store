import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('OperationType.updateWhere', () {
    test('updateWhere is a valid OperationType', () {
      expect(OperationType.updateWhere, isNotNull);
    });

    test('updateWhere is included in OperationType values', () {
      expect(OperationType.values, contains(OperationType.updateWhere));
    });

    test('OperationMetric can be created with updateWhere type', () {
      final metric = OperationMetric(
        operation: OperationType.updateWhere,
        duration: const Duration(milliseconds: 15),
        success: true,
        timestamp: DateTime.now(),
        itemCount: 5,
      );

      expect(metric.operation, equals(OperationType.updateWhere));
      expect(metric.itemCount, equals(5));
    });
  });
}
