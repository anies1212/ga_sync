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
      final event = EventDefinition(
        eventName: 'point_earned',
        parameters: [],
      );

      expect(event.className, 'PointEarned');
    });

    test('enumValue converts to camelCase', () {
      final event = EventDefinition(
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
      final param = EventParameter(name: 'source_screen', type: 'string');

      expect(param.fieldName, 'sourceScreen');
    });

    test('dartType converts correctly', () {
      expect(
        EventParameter(name: 'a', type: 'string').dartType,
        'String',
      );
      expect(
        EventParameter(name: 'b', type: 'int').dartType,
        'int',
      );
      expect(
        EventParameter(name: 'c', type: 'double').dartType,
        'double',
      );
      expect(
        EventParameter(name: 'd', type: 'bool').dartType,
        'bool',
      );
      expect(
        EventParameter(name: 'e', type: 'unknown').dartType,
        'dynamic',
      );
    });
  });
}
