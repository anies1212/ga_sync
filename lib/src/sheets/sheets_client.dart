import 'dart:io';

import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Google Sheets API client
class SheetsClient {
  final sheets.SheetsApi _api;
  final http.Client _httpClient;

  SheetsClient._(this._api, this._httpClient);

  /// Create client from service account credentials
  static Future<SheetsClient> fromServiceAccount(String credentialsPath) async {
    final file = File(credentialsPath);
    if (!file.existsSync()) {
      throw SheetsException('Credentials file not found: $credentialsPath');
    }

    final credentials = ServiceAccountCredentials.fromJson(
      await file.readAsString(),
    );

    final scopes = [sheets.SheetsApi.spreadsheetsScope];
    final httpClient = await clientViaServiceAccount(credentials, scopes);
    final api = sheets.SheetsApi(httpClient);

    return SheetsClient._(api, httpClient);
  }

  /// Create client from environment variable
  static Future<SheetsClient> fromEnvironment() async {
    final credentialsPath = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
    if (credentialsPath == null || credentialsPath.isEmpty) {
      throw SheetsException(
        'GOOGLE_APPLICATION_CREDENTIALS environment variable is not set',
      );
    }
    return fromServiceAccount(credentialsPath);
  }

  /// Read data from sheet
  Future<List<List<String>>> readSheet({
    required String spreadsheetId,
    required String sheetName,
    String? range,
  }) async {
    final fullRange = range != null ? '$sheetName!$range' : sheetName;

    try {
      final response = await _api.spreadsheets.values.get(
        spreadsheetId,
        fullRange,
      );

      final values = response.values;
      if (values == null || values.isEmpty) {
        return [];
      }

      return values.map((row) {
        return row.map((cell) => cell?.toString() ?? '').toList();
      }).toList();
    } on sheets.DetailedApiRequestError catch (e) {
      throw SheetsException('Failed to read sheet: ${e.message}');
    }
  }

  /// Write data to sheet
  Future<void> writeSheet({
    required String spreadsheetId,
    required String sheetName,
    required List<List<String>> data,
    String startCell = 'A1',
  }) async {
    final range = '$sheetName!$startCell';

    try {
      final valueRange = sheets.ValueRange(
        values: data,
      );

      await _api.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );
    } on sheets.DetailedApiRequestError catch (e) {
      throw SheetsException('Failed to write sheet: ${e.message}');
    }
  }

  /// Clear sheet
  Future<void> clearSheet({
    required String spreadsheetId,
    required String sheetName,
    String? range,
  }) async {
    final fullRange = range != null ? '$sheetName!$range' : sheetName;

    try {
      await _api.spreadsheets.values.clear(
        sheets.ClearValuesRequest(),
        spreadsheetId,
        fullRange,
      );
    } on sheets.DetailedApiRequestError catch (e) {
      throw SheetsException('Failed to clear sheet: ${e.message}');
    }
  }

  /// Close client
  void close() {
    _httpClient.close();
  }
}

/// Sheets API exception
class SheetsException implements Exception {
  final String message;

  const SheetsException(this.message);

  @override
  String toString() => 'SheetsException: $message';
}
