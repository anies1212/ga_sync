import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/ga_sync_config.dart';
import '../generators/dart_generator.dart';
import '../sheets/events_reader.dart';
import '../sheets/sheets_client.dart';

/// Generate events command
class GenerateCommand {
  /// Generate event code
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
        stdout.writeln('No event definitions found.');
        return;
      }

      // Validation
      final errors = reader.validate(events);
      if (errors.isNotEmpty) {
        stderr.writeln('Validation errors:');
        for (final error in errors) {
          stderr.writeln('  - $error');
        }
        throw GenerateException('Validation failed');
      }

      // Code generation
      final generator = DartGenerator();
      final code = generator.generate(events);

      if (dryRun) {
        stdout.writeln('--- Generated code ---');
        stdout.writeln(code);
        stdout.writeln('--- End ---');
        stdout.writeln('');
        stdout.writeln('${events.length} events will be generated.');
        stdout.writeln('Output: ${config.events.output}');
        return;
      }

      // Write to file
      final outputPath = config.events.output;
      final outputFile = File(outputPath);

      // Create directory
      final dir = outputFile.parent;
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      await outputFile.writeAsString(code);

      stdout.writeln('✓ Generated ${events.length} event definitions');
      stdout.writeln('  Output: ${p.normalize(outputPath)}');
    } finally {
      client.close();
    }
  }

  Future<SheetsClient> _createClient(GaSyncConfig config) async {
    // Prefer environment variable
    if (Platform.environment.containsKey('GOOGLE_APPLICATION_CREDENTIALS')) {
      return SheetsClient.fromEnvironment();
    }

    // Use config credentials
    return SheetsClient.fromServiceAccount(config.spreadsheet.credentials);
  }
}

/// Generate exception
class GenerateException implements Exception {
  final String message;

  const GenerateException(this.message);

  @override
  String toString() => message;
}
