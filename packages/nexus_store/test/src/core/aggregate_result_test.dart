import 'package:nexus_store/nexus_store.dart';
import 'package:test/test.dart';

void main() {
  group('AggregateType', () {
    test('has all four aggregate types', () {
      expect(AggregateType.values, hasLength(4));
      expect(AggregateType.values, contains(AggregateType.sum));
      expect(AggregateType.values, contains(AggregateType.avg));
      expect(AggregateType.values, contains(AggregateType.min));
      expect(AggregateType.values, contains(AggregateType.max));
    });

    test('values have correct indices', () {
      expect(AggregateType.sum.index, 0);
      expect(AggregateType.avg.index, 1);
      expect(AggregateType.min.index, 2);
      expect(AggregateType.max.index, 3);
    });

    test('name returns correct string', () {
      expect(AggregateType.sum.name, 'sum');
      expect(AggregateType.avg.name, 'avg');
      expect(AggregateType.min.name, 'min');
      expect(AggregateType.max.name, 'max');
    });
  });
}
