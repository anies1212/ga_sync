import '../models/event_definition.dart';
import 'sheets_client.dart';

/// Read event definitions from spreadsheet
class EventsReader {
  final SheetsClient _client;

  const EventsReader(this._client);

  /// Read event definitions
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

    // Parse header row to determine column positions
    final headers = data.first;
    final columnMap = _parseHeaders(headers);

    // Skip header row
    final rows =
        data.skip(1).where((row) => row.isNotEmpty && row[0].isNotEmpty);

    final events = <EventDefinition>[];
    var rowIndex = 2; // 1-indexed, starting after header

    for (final row in rows) {
      try {
        events.add(_parseRow(row, columnMap));
      } catch (e) {
        throw EventsReaderException(
          'Error at row $rowIndex: $e',
          rowIndex: rowIndex,
        );
      }
      rowIndex++;
    }

    return events;
  }

  /// Parse header row to determine column mapping
  _ColumnMap _parseHeaders(List<String> headers) {
    int? eventNameCol;
    int? descriptionCol;
    int? categoryCol;
    final parameterCols = <int>[]; // パラメータ列のインデックス
    final typeCols = <int>[]; // 型列のインデックス

    for (var i = 0; i < headers.length; i++) {
      final header = headers[i].trim().toLowerCase();

      // イベント名列
      if (_isEventNameHeader(header)) {
        eventNameCol = i;
        continue;
      }

      // 説明列
      if (_isDescriptionHeader(header)) {
        descriptionCol = i;
        continue;
      }

      // カテゴリ列
      if (_isCategoryHeader(header)) {
        categoryCol = i;
        continue;
      }

      // パラメータ列（パラメータ1, パラメータ2, ... or parameters）
      if (_isParameterHeader(header)) {
        parameterCols.add(i);
        continue;
      }

      // 型列（型1, 型2, ... or parameter_types）
      if (_isTypeHeader(header)) {
        typeCols.add(i);
        continue;
      }
    }

    // Fallback to legacy format if new format not detected
    if (parameterCols.isEmpty && eventNameCol != null) {
      // Legacy format: event_name, parameters, parameter_types, description, category
      return _ColumnMap(
        eventNameCol: eventNameCol,
        descriptionCol: descriptionCol ?? 3,
        categoryCol: categoryCol ?? 4,
        parameterCols: [1], // Single column with comma-separated values
        typeCols: [2], // Single column with comma-separated values
        isLegacyFormat: true,
      );
    }

    return _ColumnMap(
      eventNameCol: eventNameCol ?? 0,
      descriptionCol: descriptionCol ?? headers.length - 2,
      categoryCol: categoryCol ?? headers.length - 1,
      parameterCols: parameterCols,
      typeCols: typeCols,
      isLegacyFormat: false,
    );
  }

  bool _isEventNameHeader(String header) {
    return header == 'event_name' ||
        header == 'eventname' ||
        header == 'イベント名' ||
        header == 'イベント';
  }

  bool _isDescriptionHeader(String header) {
    return header == 'description' || header == '説明';
  }

  bool _isCategoryHeader(String header) {
    return header == 'category' || header == 'カテゴリ';
  }

  bool _isParameterHeader(String header) {
    return header == 'parameters' ||
        header == 'パラメータ' ||
        header.startsWith('パラメータ') ||
        header.startsWith('parameter') ||
        header.startsWith('param');
  }

  bool _isTypeHeader(String header) {
    return header == 'parameter_types' ||
        header == 'パラメータ型' ||
        header.startsWith('型') ||
        header.startsWith('type');
  }

  /// Parse a single row using column mapping
  EventDefinition _parseRow(List<String> row, _ColumnMap columnMap) {
    final eventName = _getCell(row, columnMap.eventNameCol);
    final description = _getCell(row, columnMap.descriptionCol);
    final category = _getCell(row, columnMap.categoryCol);

    final parameters = <EventParameter>[];

    if (columnMap.isLegacyFormat) {
      // Legacy format: comma-separated values in single columns
      final paramStr = _getCell(row, columnMap.parameterCols.first);
      final typeStr = _getCell(row, columnMap.typeCols.first);

      if (paramStr.isNotEmpty) {
        final paramNames = paramStr.split(',').map((e) => e.trim()).toList();
        final paramTypes = typeStr.isEmpty
            ? <String>[]
            : typeStr.split(',').map((e) => e.trim()).toList();

        for (var i = 0; i < paramNames.length; i++) {
          if (paramNames[i].isNotEmpty) {
            parameters.add(
              EventParameter(
                name: paramNames[i],
                type: i < paramTypes.length ? paramTypes[i] : 'string',
              ),
            );
          }
        }
      }
    } else {
      // New format: paired parameter/type columns
      final maxPairs =
          columnMap.parameterCols.length < columnMap.typeCols.length
              ? columnMap.parameterCols.length
              : columnMap.typeCols.length;

      for (var i = 0; i < maxPairs; i++) {
        final paramName = _getCell(row, columnMap.parameterCols[i]);
        final paramType = _getCell(row, columnMap.typeCols[i]);

        // Skip empty parameters
        if (paramName.isNotEmpty) {
          parameters.add(
            EventParameter(
              name: paramName,
              type: paramType.isNotEmpty ? paramType : 'string',
            ),
          );
        }
      }
    }

    return EventDefinition(
      eventName: eventName,
      parameters: parameters,
      description: description.isNotEmpty ? description : null,
      category: category.isNotEmpty ? category : null,
    );
  }

  String _getCell(List<String> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return row[index].trim();
  }

  /// Validate event definitions
  List<ValidationError> validate(List<EventDefinition> events) {
    final errors = <ValidationError>[];
    final seenNames = <String>{};

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final rowIndex = i + 2; // Account for header row

      // Check for duplicate event names
      if (seenNames.contains(event.eventName)) {
        errors.add(
          ValidationError(
            rowIndex: rowIndex,
            message: 'Duplicate event name: ${event.eventName}',
          ),
        );
      }
      seenNames.add(event.eventName);

      // Check event name format
      if (!_isValidSnakeCase(event.eventName)) {
        errors.add(
          ValidationError(
            rowIndex: rowIndex,
            message: 'Event name must be snake_case: ${event.eventName}',
          ),
        );
      }

      // Check parameter name format
      for (final param in event.parameters) {
        if (!_isValidSnakeCase(param.name)) {
          errors.add(
            ValidationError(
              rowIndex: rowIndex,
              message: 'Parameter name must be snake_case: ${param.name}',
            ),
          );
        }
      }
    }

    return errors;
  }

  bool _isValidSnakeCase(String name) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
  }
}

/// Column mapping for spreadsheet
class _ColumnMap {
  final int eventNameCol;
  final int descriptionCol;
  final int categoryCol;
  final List<int> parameterCols;
  final List<int> typeCols;
  final bool isLegacyFormat;

  const _ColumnMap({
    required this.eventNameCol,
    required this.descriptionCol,
    required this.categoryCol,
    required this.parameterCols,
    required this.typeCols,
    required this.isLegacyFormat,
  });
}

/// Events reader exception
class EventsReaderException implements Exception {
  final String message;
  final int rowIndex;

  const EventsReaderException(this.message, {required this.rowIndex});

  @override
  String toString() => 'EventsReaderException: $message (row: $rowIndex)';
}

/// Validation error
class ValidationError {
  final int rowIndex;
  final String message;

  const ValidationError({
    required this.rowIndex,
    required this.message,
  });

  @override
  String toString() => 'Row $rowIndex: $message';
}
