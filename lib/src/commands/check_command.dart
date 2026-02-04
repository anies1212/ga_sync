import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/ga_sync_config.dart';
import '../generators/dart_generator.dart';
import '../sheets/events_reader.dart';
import '../sheets/sheets_client.dart';

/// Check command (for CI)
class CheckCommand {
  /// Check if generated code is up to date
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
        stdout.writeln('No event definitions found.');
        return true;
      }

      // Validation
      final errors = reader.validate(events);
      if (errors.isNotEmpty) {
        stderr.writeln('Validation errors:');
        for (final error in errors) {
          stderr.writeln('  - $error');
        }
        return false;
      }

      // Generate new code
      final generator = DartGenerator();
      final newCode = generator.generate(events);

      // Compare with existing file
      final outputPath = config.events.output;
      final outputFile = File(outputPath);

      if (!outputFile.existsSync()) {
        stderr.writeln(
            'Error: Generated file does not exist: ${p.normalize(outputPath)}');
        stderr.writeln('Run: ga_sync generate events');
        return false;
      }

      final existingCode = await outputFile.readAsString();

      if (existingCode == newCode) {
        stdout.writeln('✓ Code is up to date');
        return true;
      } else {
        stderr.writeln('Error: Generated code is out of date');
        stderr.writeln('Run: ga_sync generate events');
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
