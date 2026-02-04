import 'package:ga_sync/src/models/event_definition.dart';
import 'package:test/test.dart';

void main() {
  group('EventDefinition', () {
    test('fromRow parses correctly', () {
      final row = [
        'point_earned',
        'cv_id,cv_type,source_screen',
        'string,string,string',
        'When points earned',
        'conversion',
      ];

      final event = EventDefinition.fromRow(row);

      expect(event.eventName, 'point_earned');
      expect(event.parameters.length, 3);
      expect(event.description, 'When points earned');
      expect(event.category, 'conversion');
    });

    test('className converts to PascalCase', () {
      const event = EventDefinition(
        eventName: 'point_earned',
        parameters: [],
      );

      expect(event.className, 'PointEarned');
    });

    test('enumValue converts to camelCase', () {
      const event = EventDefinition(
        eventName: 'button_click',
        parameters: [],
      );

      expect(event.enumValue, 'buttonClick');
    });

    test('throws on parameter count mismatch', () {
      final row = [
        'test_event',
        'param1,param2',
        'string',
        'test',
      ];

      expect(
        () => EventDefinition.fromRow(row),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on invalid row', () {
      final row = ['event_name', 'params'];

      expect(
        () => EventDefinition.fromRow(row),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('EventParameter', () {
    test('fieldName converts to camelCase', () {
      const param = EventParameter(name: 'source_screen', type: 'string');

      expect(param.fieldName, 'sourceScreen');
    });

    test('dartType converts correctly', () {
      expect(
        const EventParameter(name: 'a', type: 'string').dartType,
        'String',
      );
      expect(
        const EventParameter(name: 'b', type: 'int').dartType,
        'int',
      );
      expect(
        const EventParameter(name: 'c', type: 'double').dartType,
        'double',
      );
      expect(
        const EventParameter(name: 'd', type: 'bool').dartType,
        'bool',
      );
      expect(
        const EventParameter(name: 'e', type: 'unknown').dartType,
        'dynamic',
      );
    });
  });
}
