import 'dart:io';

import '../config/ga_sync_config.dart';
import '../parsers/go_router_parser.dart';
import '../sheets/routes_writer.dart';
import '../sheets/sheets_client.dart';

/// ルート同期コマンド
class SyncCommand {
  /// ルートをスプレッドシートに同期
  Future<void> run({
    String? configPath,
    bool dryRun = false,
  }) async {
    final config = await GaSyncConfig.load(configPath);

    // ルートをパース
    final parser = _createParser(config.routes.parser);
    final routes = await parser.parse(config.routes.source);

    if (routes.isEmpty) {
      stdout.writeln('ルート定義が見つかりませんでした。');
      return;
    }

    stdout.writeln('${routes.length} 件のルートを検出しました:');
    for (final route in routes) {
      stdout.writeln('  - ${route.path} (${route.screenClass ?? "unknown"})');
    }

    if (dryRun) {
      stdout.writeln('');
      stdout.writeln('(ドライラン: 実際の同期は行われません)');
      return;
    }

    // スプレッドシートに同期
    final client = await _createClient(config);

    try {
      final writer = RoutesWriter(client);
      final result = await writer.sync(
        spreadsheetId: config.spreadsheet.id,
        sheetName: config.routes.sheetName,
        routes: routes,
      );

      stdout.writeln('');
      stdout.writeln('✓ ルートを同期しました');

      if (result.hasChanges) {
        if (result.added.isNotEmpty) {
          stdout.writeln('  追加: ${result.added.length} 件');
          for (final route in result.added) {
            stdout.writeln('    + ${route.path}');
          }
        }
        if (result.removed.isNotEmpty) {
          stdout.writeln('  削除: ${result.removed.length} 件');
          for (final route in result.removed) {
            stdout.writeln('    - ${route.path}');
          }
        }
      } else {
        stdout.writeln('  変更なし');
      }
    } finally {
      client.close();
    }
  }

  GoRouterParser _createParser(String parserName) {
    return switch (parserName) {
      'go_router' => GoRouterParser(),
      _ => throw SyncException('未対応のパーサー: $parserName'),
    };
  }

  Future<SheetsClient> _createClient(GaSyncConfig config) async {
    if (Platform.environment.containsKey('GOOGLE_APPLICATION_CREDENTIALS')) {
      return SheetsClient.fromEnvironment();
    }
    return SheetsClient.fromServiceAccount(config.spreadsheet.credentials);
  }
}

/// 同期例外
class SyncException implements Exception {
  final String message;

  const SyncException(this.message);

  @override
  String toString() => message;
}
