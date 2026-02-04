import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

/// GA Sync configuration
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

  /// Load config file
  static Future<GaSyncConfig> load([String? configPath]) async {
    final path = configPath ?? _findConfigFile();
    if (path == null) {
      throw const ConfigException('Config file not found. Run: ga_sync init');
    }

    final file = File(path);
    if (!file.existsSync()) {
      throw ConfigException('Config file does not exist: $path');
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
      throw const ConfigException('spreadsheet config is required');
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

  /// Generate default config file content
  static String generateDefault() {
    return '''
# GA Sync configuration
version: 1

spreadsheet:
  # Google Spreadsheet ID (from URL)
  id: "YOUR_SPREADSHEET_ID"
  # Service account credentials file
  credentials: "credentials.json"

events:
  # Sheet name for event definitions
  sheet_name: "Events"
  # Output file path
  output: "lib/analytics/ga_events.g.dart"
  # Output language
  language: dart

routes:
  # Sheet name for route definitions
  sheet_name: "Routes"
  # Source files to parse
  source:
    - "lib/router/app_router.dart"
  # Router library parser
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

/// Spreadsheet configuration
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
      throw const ConfigException('spreadsheet.id is required');
    }

    return SpreadsheetConfig(
      id: id,
      credentials: credentials,
    );
  }
}

/// Events configuration
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

/// Routes configuration
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

/// Config exception
class ConfigException implements Exception {
  final String message;

  const ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}
