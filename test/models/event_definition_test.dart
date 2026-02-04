import 'package:ga_sync/src/models/event_definition.dart';
import 'package:test/test.dart';

void main() {
  group('EventDefinition', () {
    test('fromRowで正しくパースできる', () {
      final row = [
        'point_earned',
        'cv_id,cv_type,source_screen',
        'string,string,string',
        'ポイント獲得時',
        'conversion',
      ];

      final event = EventDefinition.fromRow(row);

      expect(event.eventName, 'point_earned');
      expect(event.parameters.length, 3);
      expect(event.description, 'ポイント獲得時');
      expect(event.category, 'conversion');
    });

    test('classNameがPascalCaseに変換される', () {
      final event = EventDefinition(
        eventName: 'point_earned',
        parameters: [],
      );

      expect(event.className, 'PointEarned');
    });

    test('enumValueがcamelCaseに変換される', () {
      final event = EventDefinition(
        eventName: 'button_click',
        parameters: [],
      );

      expect(event.enumValue, 'buttonClick');
    });

    test('パラメータ数不一致でエラー', () {
      final row = [
        'test_event',
        'param1,param2',
        'string',
        'テスト',
      ];

      expect(
        () => EventDefinition.fromRow(row),
        throwsA(isA<FormatException>()),
      );
    });

    test('不正な行でエラー', () {
      final row = ['event_name', 'params'];

      expect(
        () => EventDefinition.fromRow(row),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('EventParameter', () {
    test('fieldNameがcamelCaseに変換される', () {
      final param = EventParameter(name: 'source_screen', type: 'string');

      expect(param.fieldName, 'sourceScreen');
    });

    test('dartTypeが正しく変換される', () {
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
