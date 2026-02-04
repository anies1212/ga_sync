import 'dart:io';

import 'package:args/args.dart';
import 'package:ga_sync/ga_sync.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('init', ArgParser()..addFlag('force', abbr: 'f'))
    ..addCommand(
      'generate',
      ArgParser()
        ..addCommand('events', ArgParser()..addFlag('dry-run', abbr: 'd'))
        ..addOption('config', abbr: 'c'),
    )
    ..addCommand(
      'sync',
      ArgParser()
        ..addCommand('routes', ArgParser()..addFlag('dry-run', abbr: 'd'))
        ..addCommand('all', ArgParser()..addFlag('dry-run', abbr: 'd'))
        ..addOption('config', abbr: 'c'),
    )
    ..addCommand('check', ArgParser()..addOption('config', abbr: 'c'))
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addFlag('version', abbr: 'v', negatable: false);

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool || results.command == null) {
      _printUsage(parser);
      return;
    }

    if (results['version'] as bool) {
      stdout.writeln('ga_sync version 0.1.0');
      return;
    }

    await _runCommand(results);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    _printUsage(parser);
    exitCode = 1;
  } catch (e) {
    stderr.writeln('Error: $e');
    exitCode = 1;
  }
}

Future<void> _runCommand(ArgResults results) async {
  final command = results.command!;

  switch (command.name) {
    case 'init':
      await InitCommand().run(
        force: command['force'] as bool,
      );

    case 'generate':
      final subCommand = command.command;
      if (subCommand == null || subCommand.name != 'events') {
        stderr.writeln('Usage: ga_sync generate events [--dry-run]');
        exitCode = 1;
        return;
      }
      await GenerateCommand().run(
        configPath: command['config'] as String?,
        dryRun: subCommand['dry-run'] as bool,
      );

    case 'sync':
      final subCommand = command.command;
      if (subCommand == null) {
        stderr.writeln('Usage: ga_sync sync <routes|all> [--dry-run]');
        exitCode = 1;
        return;
      }

      final dryRun = subCommand['dry-run'] as bool;
      final configPath = command['config'] as String?;

      switch (subCommand.name) {
        case 'routes':
          await SyncCommand().run(
            configPath: configPath,
            dryRun: dryRun,
          );
        case 'all':
          await GenerateCommand().run(
            configPath: configPath,
            dryRun: dryRun,
          );
          await SyncCommand().run(
            configPath: configPath,
            dryRun: dryRun,
          );
      }

    case 'check':
      final success = await CheckCommand().run(
        configPath: command['config'] as String?,
      );
      if (!success) {
        exitCode = 1;
      }

    default:
      stderr.writeln('Unknown command: ${command.name}');
      exitCode = 1;
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('''
ga_sync - Google Analytics event definition sync tool

Usage: ga_sync <command> [options]

Commands:
  init                    Create config file (ga_sync.yaml)
    -f, --force           Overwrite existing file

  generate events         Generate code from event definitions (Spreadsheet -> Code)
    -d, --dry-run         Preview only, don't generate
    -c, --config          Config file path

  sync routes             Sync route definitions to spreadsheet (Code -> Spreadsheet)
    -d, --dry-run         Preview only, don't sync
    -c, --config          Config file path

  sync all                Run both generate events and sync routes

  check                   Check if generated code is up to date (for CI)
    -c, --config          Config file path

Options:
  -h, --help              Show help
  -v, --version           Show version

Examples:
  ga_sync init                      # Create config file
  ga_sync generate events           # Generate event code
  ga_sync generate events --dry-run # Preview only
  ga_sync sync routes               # Sync routes
  ga_sync check                     # Check for CI
''');
}
