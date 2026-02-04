import 'dart:io';

import '../config/ga_sync_config.dart';

/// 初期化コマンド
class InitCommand {
  /// 設定ファイルを作成
  Future<void> run({bool force = false}) async {
    const configPath = 'ga_sync.yaml';
    final file = File(configPath);

    if (file.existsSync() && !force) {
      throw InitException(
        '設定ファイルが既に存在します: $configPath\n'
        '上書きする場合は --force オプションを使用してください。',
      );
    }

    final content = GaSyncConfig.generateDefault();
    await file.writeAsString(content);

    stdout.writeln('✓ 設定ファイルを作成しました: $configPath');
    stdout.writeln('');
    stdout.writeln('次のステップ:');
    stdout.writeln('1. Google Cloud ConsoleでサービスアカウントをつくりJSONキーを取得');
    stdout.writeln('2. credentials.json をプロジェクトルートに配置');
    stdout.writeln('3. ga_sync.yaml の spreadsheet.id を設定');
    stdout.writeln('4. ga_sync generate events を実行');
  }
}

/// 初期化例外
class InitException implements Exception {
  final String message;

  const InitException(this.message);

  @override
  String toString() => message;
}
