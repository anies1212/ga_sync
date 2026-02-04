import 'dart:io';

import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Google Sheets APIクライアント
class SheetsClient {
  final sheets.SheetsApi _api;
  final http.Client _httpClient;

  SheetsClient._(this._api, this._httpClient);

  /// サービスアカウントで認証してクライアントを作成
  static Future<SheetsClient> fromServiceAccount(String credentialsPath) async {
    final file = File(credentialsPath);
    if (!file.existsSync()) {
      throw SheetsException('認証情報ファイルが見つかりません: $credentialsPath');
    }

    final credentials = ServiceAccountCredentials.fromJson(
      await file.readAsString(),
    );

    final scopes = [sheets.SheetsApi.spreadsheetsScope];
    final httpClient = await clientViaServiceAccount(credentials, scopes);
    final api = sheets.SheetsApi(httpClient);

    return SheetsClient._(api, httpClient);
  }

  /// 環境変数から認証情報を取得
  static Future<SheetsClient> fromEnvironment() async {
    final credentialsPath = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
    if (credentialsPath == null || credentialsPath.isEmpty) {
      throw SheetsException(
        'GOOGLE_APPLICATION_CREDENTIALS環境変数が設定されていません',
      );
    }
    return fromServiceAccount(credentialsPath);
  }

  /// シートからデータを読み込む
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
      throw SheetsException('シート読み込みエラー: ${e.message}');
    }
  }

  /// シートにデータを書き込む
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
      throw SheetsException('シート書き込みエラー: ${e.message}');
    }
  }

  /// シートをクリアする
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
      throw SheetsException('シートクリアエラー: ${e.message}');
    }
  }

  /// クライアントを閉じる
  void close() {
    _httpClient.close();
  }
}

/// Sheets API例外
class SheetsException implements Exception {
  final String message;

  const SheetsException(this.message);

  @override
  String toString() => 'SheetsException: $message';
}
