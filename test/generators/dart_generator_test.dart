import 'package:ga_sync/src/generators/dart_generator.dart';
import 'package:ga_sync/src/models/event_definition.dart';
import 'package:test/test.dart';

void main() {
  group('DartGenerator', () {
    late DartGenerator generator;

    setUp(() {
      generator = DartGenerator();
    });

    test('空のイベントリストでも生成できる', () {
      final code = generator.generate([]);

      // 空のリストの場合、enumは生成されない（Dartでは空enumは不正）
      expect(code, isNot(contains('enum GaEventName')));
      expect(code, contains('GENERATED CODE'));
    });

    test('イベントクラスが正しく生成される', () {
      final events = [
        EventDefinition(
          eventName: 'button_click',
          parameters: [
            EventParameter(name: 'button_id', type: 'string'),
            EventParameter(name: 'screen_name', type: 'string'),
          ],
          description: 'ボタンクリック時',
        ),
      ];

      final code = generator.generate(events);

      expect(code, contains('class ButtonClickEvent'));
      expect(code, contains('final String buttonId'));
      expect(code, contains('final String screenName'));
      expect(code, contains("'button_id': buttonId"));
      expect(code, contains("'screen_name': screenName"));
    });

    test('enumが正しく生成される', () {
      final events = [
        EventDefinition(eventName: 'event_one', parameters: []),
        EventDefinition(eventName: 'event_two', parameters: []),
      ];

      final code = generator.generate(events);

      expect(code, contains('enum GaEventName'));
      expect(code, contains('eventOne'));
      expect(code, contains('eventTwo'));
    });

    test('拡張メソッドが正しく生成される', () {
      final events = [
        EventDefinition(eventName: 'test_event', parameters: []),
      ];

      final code = generator.generate(events);

      expect(code, contains('extension GaEventExtensions'));
      expect(code, contains("GaEventName.testEvent => 'test_event'"));
    });

    test('複数パラメータ型が正しく生成される', () {
      final events = [
        EventDefinition(
          eventName: 'complex_event',
          parameters: [
            EventParameter(name: 'str_param', type: 'string'),
            EventParameter(name: 'int_param', type: 'int'),
            EventParameter(name: 'double_param', type: 'double'),
            EventParameter(name: 'bool_param', type: 'bool'),
          ],
        ),
      ];

      final code = generator.generate(events);

      expect(code, contains('final String strParam'));
      expect(code, contains('final int intParam'));
      expect(code, contains('final double doubleParam'));
      expect(code, contains('final bool boolParam'));
    });
  });
}
