import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/ga_sync_config.dart';
import '../generators/dart_generator.dart';
import '../sheets/events_reader.dart';
import '../sheets/sheets_client.dart';

/// 差分チェックコマンド（CI用）
class CheckCommand {
  /// 生成コードとの差分をチェック
  Future<bool> run({String? configPath}) async {
    final config = await GaSyncConfig.load(configPath);
    final client = await _createClient(config);

    try {
      final reader = EventsReader(client);
      final events = await reader.read(
        spreadsheetId: config.spreadsheet.id,
        sheetName: config.events.sheetName,
      );

      if (events.isEmpty) {
        stdout.writeln('イベント定義が見つかりませんでした。');
        return true;
      }

      // バリデーション
      final errors = reader.validate(events);
      if (errors.isNotEmpty) {
        stderr.writeln('バリデーションエラー:');
        for (final error in errors) {
          stderr.writeln('  - $error');
        }
        return false;
      }

      // 新しいコードを生成
      final generator = DartGenerator();
      final newCode = generator.generate(events);

      // 既存ファイルと比較
      final outputPath = config.events.output;
      final outputFile = File(outputPath);

      if (!outputFile.existsSync()) {
        stderr.writeln('エラー: 生成ファイルが存在しません: ${p.normalize(outputPath)}');
        stderr.writeln('ga_sync generate events を実行してください。');
        return false;
      }

      final existingCode = await outputFile.readAsString();

      if (existingCode == newCode) {
        stdout.writeln('✓ コードは最新です');
        return true;
      } else {
        stderr.writeln('エラー: 生成コードが最新ではありません');
        stderr.writeln('ga_sync generate events を実行してコードを更新してください。');
        return false;
      }
    } finally {
      client.close();
    }
  }

  Future<SheetsClient> _createClient(GaSyncConfig config) async {
    if (Platform.environment.containsKey('GOOGLE_APPLICATION_CREDENTIALS')) {
      return SheetsClient.fromEnvironment();
    }
    return SheetsClient.fromServiceAccount(config.spreadsheet.credentials);
  }
}
