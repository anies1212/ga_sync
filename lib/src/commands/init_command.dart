import 'dart:io';

import '../config/ga_sync_config.dart';

/// Init command
class InitCommand {
  /// Create config file
  Future<void> run({bool force = false}) async {
    const configPath = 'ga_sync.yaml';
    final file = File(configPath);

    if (file.existsSync() && !force) {
      throw const InitException(
        'Config file already exists: $configPath\n'
        'Use --force option to overwrite.',
      );
    }

    final content = GaSyncConfig.generateDefault();
    await file.writeAsString(content);

    stdout.writeln('✓ Created config file: $configPath');
    stdout.writeln('');
    stdout.writeln('Next steps:');
    stdout.writeln(
      '1. Create a service account in Google Cloud Console and download JSON key',
    );
    stdout.writeln('2. Place credentials.json in project root');
    stdout.writeln('3. Set spreadsheet.id in ga_sync.yaml');
    stdout.writeln('4. Run: ga_sync generate events');
  }
}

/// Init exception
class InitException implements Exception {
  final String message;

  const InitException(this.message);

  @override
  String toString() => message;
}
