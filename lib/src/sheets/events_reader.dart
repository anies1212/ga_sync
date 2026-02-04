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

    // Skip header row
    final rows =
        data.skip(1).where((row) => row.isNotEmpty && row[0].isNotEmpty);

    final events = <EventDefinition>[];
    var rowIndex = 2; // 1-indexed, starting after header

    for (final row in rows) {
      try {
        events.add(EventDefinition.fromRow(row));
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
