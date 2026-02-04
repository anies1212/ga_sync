import '../models/event_definition.dart';
import 'sheets_client.dart';

/// イベント定義をスプレッドシートから読み込む
class EventsReader {
  final SheetsClient _client;

  const EventsReader(this._client);

  /// イベント定義を読み込む
  Future<List<EventDefinition>> read({
    required String spreadsheetId,
    required String sheetName,
  }) async {
    final data = await _client.readSheet(
      spreadsheetId: spreadsheetId,
      sheetName: sheetName,
    );

    if (data.isEmpty) {
      return [];
    }

    // ヘッダー行をスキップ
    final rows = data.skip(1).where((row) => row.isNotEmpty && row[0].isNotEmpty);

    final events = <EventDefinition>[];
    var rowIndex = 2; // 1-indexed, ヘッダー行の次から

    for (final row in rows) {
      try {
        events.add(EventDefinition.fromRow(row));
      } catch (e) {
        throw EventsReaderException(
          '行 $rowIndex でエラー: $e',
          rowIndex: rowIndex,
        );
      }
      rowIndex++;
    }

    return events;
  }

  /// イベント定義をバリデーション
  List<ValidationError> validate(List<EventDefinition> events) {
    final errors = <ValidationError>[];
    final seenNames = <String>{};

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final rowIndex = i + 2; // ヘッダー行を考慮

      // イベント名の重複チェック
      if (seenNames.contains(event.eventName)) {
        errors.add(ValidationError(
          rowIndex: rowIndex,
          message: 'イベント名が重複しています: ${event.eventName}',
        ));
      }
      seenNames.add(event.eventName);

      // イベント名の形式チェック
      if (!_isValidSnakeCase(event.eventName)) {
        errors.add(ValidationError(
          rowIndex: rowIndex,
          message: 'イベント名はsnake_caseで記述してください: ${event.eventName}',
        ));
      }

      // パラメータ名の形式チェック
      for (final param in event.parameters) {
        if (!_isValidSnakeCase(param.name)) {
          errors.add(ValidationError(
            rowIndex: rowIndex,
            message: 'パラメータ名はsnake_caseで記述してください: ${param.name}',
          ));
        }
      }
    }

    return errors;
  }

  bool _isValidSnakeCase(String name) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
  }
}

/// イベント読み込み例外
class EventsReaderException implements Exception {
  final String message;
  final int rowIndex;

  const EventsReaderException(this.message, {required this.rowIndex});

  @override
  String toString() => 'EventsReaderException: $message (row: $rowIndex)';
}

/// バリデーションエラー
class ValidationError {
  final int rowIndex;
  final String message;

  const ValidationError({
    required this.rowIndex,
    required this.message,
  });

  @override
  String toString() => '行 $rowIndex: $message';
}
