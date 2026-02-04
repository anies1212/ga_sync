import 'dart:io';

import '../config/ga_sync_config.dart';
import '../parsers/go_router_parser.dart';
import '../sheets/routes_writer.dart';
import '../sheets/sheets_client.dart';

/// Sync routes command
class SyncCommand {
  /// Sync routes to spreadsheet
  Future<void> run({
    String? configPath,
    bool dryRun = false,
  }) async {
    final config = await GaSyncConfig.load(configPath);

    // Parse routes
    final parser = _createParser(config.routes.parser);
    final routes = await parser.parse(config.routes.source);

    if (routes.isEmpty) {
      stdout.writeln('No route definitions found.');
      return;
    }

    stdout.writeln('Found ${routes.length} routes:');
    for (final route in routes) {
      stdout.writeln('  - ${route.path} (${route.screenClass ?? "unknown"})');
    }

    if (dryRun) {
      stdout.writeln('');
      stdout.writeln('(Dry run: no actual sync performed)');
      return;
    }

    // Sync to spreadsheet
    final client = await _createClient(config);

    try {
      final writer = RoutesWriter(client);
      final result = await writer.sync(
        spreadsheetId: config.spreadsheet.id,
        sheetName: config.routes.sheetName,
        routes: routes,
        headerLanguage: config.spreadsheet.headerLanguage,
      );

      stdout.writeln('');
      stdout.writeln('✓ Routes synced');

      if (result.hasChanges) {
        if (result.added.isNotEmpty) {
          stdout.writeln('  Added: ${result.added.length}');
          for (final route in result.added) {
            stdout.writeln('    + ${route.path}');
          }
        }
        if (result.removed.isNotEmpty) {
          stdout.writeln('  Removed: ${result.removed.length}');
          for (final route in result.removed) {
            stdout.writeln('    - ${route.path}');
          }
        }
      } else {
        stdout.writeln('  No changes');
      }
    } finally {
      client.close();
    }
  }

  GoRouterParser _createParser(String parserName) {
    return switch (parserName) {
      'go_router' => GoRouterParser(),
      _ => throw SyncException('Unsupported parser: $parserName'),
    };
  }

  Future<SheetsClient> _createClient(GaSyncConfig config) async {
    if (Platform.environment.containsKey('GOOGLE_APPLICATION_CREDENTIALS')) {
      return SheetsClient.fromEnvironment();
    }
    return SheetsClient.fromServiceAccount(config.spreadsheet.credentials);
  }
}

/// Sync exception
class SyncException implements Exception {
  final String message;

  const SyncException(this.message);

  @override
  String toString() => message;
}
