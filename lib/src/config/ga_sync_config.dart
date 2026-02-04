import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

/// GA Sync設定クラス
class GaSyncConfig {
  final int version;
  final SpreadsheetConfig spreadsheet;
  final EventsConfig events;
  final RoutesConfig routes;

  const GaSyncConfig({
    required this.version,
    required this.spreadsheet,
    required this.events,
    required this.routes,
  });

  /// 設定ファイルを読み込む
  static Future<GaSyncConfig> load([String? configPath]) async {
    final path = configPath ?? _findConfigFile();
    if (path == null) {
      throw ConfigException('設定ファイルが見つかりません。ga_sync init を実行してください。');
    }

    final file = File(path);
    if (!file.existsSync()) {
      throw ConfigException('設定ファイルが存在しません: $path');
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content) as YamlMap;

    return GaSyncConfig._fromYaml(yaml);
  }

  factory GaSyncConfig._fromYaml(YamlMap yaml) {
    final version = yaml['version'] as int? ?? 1;
    final spreadsheetYaml = yaml['spreadsheet'] as YamlMap?;
    final eventsYaml = yaml['events'] as YamlMap?;
    final routesYaml = yaml['routes'] as YamlMap?;

    if (spreadsheetYaml == null) {
      throw ConfigException('spreadsheet設定が必要です');
    }

    return GaSyncConfig(
      version: version,
      spreadsheet: SpreadsheetConfig._fromYaml(spreadsheetYaml),
      events: eventsYaml != null
          ? EventsConfig._fromYaml(eventsYaml)
          : const EventsConfig(),
      routes: routesYaml != null
          ? RoutesConfig._fromYaml(routesYaml)
          : const RoutesConfig(),
    );
  }

  /// デフォルト設定ファイルの内容を生成
  static String generateDefault() {
    return '''
# GA Sync設定ファイル
version: 1

spreadsheet:
  # Google SpreadsheetのID（URLから取得）
  id: "YOUR_SPREADSHEET_ID"
  # サービスアカウントの認証情報ファイル
  credentials: "credentials.json"

events:
  # イベント定義のシート名
  sheet_name: "Events"
  # 生成するコードの出力先
  output: "lib/analytics/ga_events.g.dart"
  # 出力言語
  language: dart

routes:
  # ルート定義のシート名
  sheet_name: "Routes"
  # 解析対象のソースファイル
  source:
    - "lib/router/app_router.dart"
  # 使用するルーターライブラリ
  parser: go_router
''';
  }

  static String? _findConfigFile() {
    final candidates = ['ga_sync.yaml', 'ga_sync.yml'];
    final currentDir = Directory.current.path;

    for (final candidate in candidates) {
      final path = p.join(currentDir, candidate);
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }
}

/// スプレッドシート設定
class SpreadsheetConfig {
  final String id;
  final String credentials;

  const SpreadsheetConfig({
    required this.id,
    required this.credentials,
  });

  factory SpreadsheetConfig._fromYaml(YamlMap yaml) {
    final id = yaml['id'] as String?;
    final credentials = yaml['credentials'] as String? ?? 'credentials.json';

    if (id == null || id.isEmpty) {
      throw ConfigException('spreadsheet.id が必要です');
    }

    return SpreadsheetConfig(
      id: id,
      credentials: credentials,
    );
  }
}

/// イベント設定
class EventsConfig {
  final String sheetName;
  final String output;
  final String language;

  const EventsConfig({
    this.sheetName = 'Events',
    this.output = 'lib/analytics/ga_events.g.dart',
    this.language = 'dart',
  });

  factory EventsConfig._fromYaml(YamlMap yaml) {
    return EventsConfig(
      sheetName: yaml['sheet_name'] as String? ?? 'Events',
      output: yaml['output'] as String? ?? 'lib/analytics/ga_events.g.dart',
      language: yaml['language'] as String? ?? 'dart',
    );
  }
}

/// ルート設定
class RoutesConfig {
  final String sheetName;
  final List<String> source;
  final String parser;

  const RoutesConfig({
    this.sheetName = 'Routes',
    this.source = const ['lib/router/app_router.dart'],
    this.parser = 'go_router',
  });

  factory RoutesConfig._fromYaml(YamlMap yaml) {
    final sourceYaml = yaml['source'];
    List<String> source;

    if (sourceYaml is YamlList) {
      source = sourceYaml.map((e) => e.toString()).toList();
    } else if (sourceYaml is String) {
      source = [sourceYaml];
    } else {
      source = const ['lib/router/app_router.dart'];
    }

    return RoutesConfig(
      sheetName: yaml['sheet_name'] as String? ?? 'Routes',
      source: source,
      parser: yaml['parser'] as String? ?? 'go_router',
    );
  }
}

/// 設定エラー
class ConfigException implements Exception {
  final String message;

  const ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}
