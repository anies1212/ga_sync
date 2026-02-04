import '../models/route_definition.dart';
import 'sheets_client.dart';

/// Write route definitions to spreadsheet
class RoutesWriter {
  final SheetsClient _client;

  const RoutesWriter(this._client);

  /// Sync route definitions
  Future<SyncResult> sync({
    required String spreadsheetId,
    required String sheetName,
    required List<RouteDefinition> routes,
  }) async {
    // Read existing data
    final existingData = await _client.readSheet(
      spreadsheetId: spreadsheetId,
      sheetName: sheetName,
    );

    final existingRoutes = _parseExistingRoutes(existingData);
    final result = _calculateDiff(existingRoutes, routes);

    // Create data with header row
    final data = <List<String>>[
      ['path', 'name', 'description', 'screen_class', 'last_updated'],
      ...routes.map((r) => r.toRow()),
    ];

    // Clear and write
    await _client.clearSheet(
      spreadsheetId: spreadsheetId,
      sheetName: sheetName,
    );

    await _client.writeSheet(
      spreadsheetId: spreadsheetId,
      sheetName: sheetName,
      data: data,
    );

    return result;
  }

  Map<String, RouteDefinition> _parseExistingRoutes(List<List<String>> data) {
    if (data.length <= 1) {
      return {};
    }

    final routes = <String, RouteDefinition>{};

    for (final row in data.skip(1)) {
      if (row.isEmpty || row[0].isEmpty) continue;

      final path = row[0];
      routes[path] = RouteDefinition(
        path: path,
        name: row.length > 1 ? row[1] : null,
        description: row.length > 2 ? row[2] : null,
        screenClass: row.length > 3 ? row[3] : null,
        lastUpdated: DateTime.now(),
      );
    }

    return routes;
  }

  SyncResult _calculateDiff(
    Map<String, RouteDefinition> existing,
    List<RouteDefinition> newRoutes,
  ) {
    final added = <RouteDefinition>[];
    final removed = <RouteDefinition>[];
    final unchanged = <RouteDefinition>[];

    final newPaths = <String>{};

    for (final route in newRoutes) {
      newPaths.add(route.path);

      if (!existing.containsKey(route.path)) {
        added.add(route);
      } else {
        unchanged.add(route);
      }
    }

    for (final entry in existing.entries) {
      if (!newPaths.contains(entry.key)) {
        removed.add(entry.value);
      }
    }

    return SyncResult(
      added: added,
      removed: removed,
      unchanged: unchanged,
    );
  }
}

/// Sync result
class SyncResult {
  final List<RouteDefinition> added;
  final List<RouteDefinition> removed;
  final List<RouteDefinition> unchanged;

  const SyncResult({
    required this.added,
    required this.removed,
    required this.unchanged,
  });

  bool get hasChanges => added.isNotEmpty || removed.isNotEmpty;

  @override
  String toString() {
    return 'SyncResult(added: ${added.length}, removed: ${removed.length}, unchanged: ${unchanged.length})';
  }
}
