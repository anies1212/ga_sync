import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/ga_sync_config.dart';
import '../generators/dart_generator.dart';
import '../sheets/events_reader.dart';
import '../sheets/sheets_client.dart';

/// イベントコード生成コマンド
class GenerateCommand {
  /// イベントコードを生成
  Future<void> run({
    String? configPath,
    bool dryRun = false,
  }) async {
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
        return;
      }

      // バリデーション
      final errors = reader.validate(events);
      if (errors.isNotEmpty) {
        stderr.writeln('バリデーションエラー:');
        for (final error in errors) {
          stderr.writeln('  - $error');
        }
        throw GenerateException('バリデーションに失敗しました');
      }

      // コード生成
      final generator = DartGenerator();
      final code = generator.generate(events);

      if (dryRun) {
        stdout.writeln('--- 生成されるコード ---');
        stdout.writeln(code);
        stdout.writeln('--- ここまで ---');
        stdout.writeln('');
        stdout.writeln('${events.length} 件のイベントが生成されます。');
        stdout.writeln('出力先: ${config.events.output}');
        return;
      }

      // ファイルに書き込み
      final outputPath = config.events.output;
      final outputFile = File(outputPath);

      // ディレクトリを作成
      final dir = outputFile.parent;
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      await outputFile.writeAsString(code);

      stdout.writeln('✓ ${events.length} 件のイベント定義を生成しました');
      stdout.writeln('  出力先: ${p.normalize(outputPath)}');
    } finally {
      client.close();
    }
  }

  Future<SheetsClient> _createClient(GaSyncConfig config) async {
    // 環境変数を優先
    if (Platform.environment.containsKey('GOOGLE_APPLICATION_CREDENTIALS')) {
      return SheetsClient.fromEnvironment();
    }

    // 設定ファイルの認証情報を使用
    return SheetsClient.fromServiceAccount(config.spreadsheet.credentials);
  }
}

/// 生成例外
class GenerateException implements Exception {
  final String message;

  const GenerateException(this.message);

  @override
  String toString() => message;
}
