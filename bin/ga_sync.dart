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
    stderr.writeln('エラー: ${e.message}');
    _printUsage(parser);
    exitCode = 1;
  } catch (e) {
    stderr.writeln('エラー: $e');
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
      break;

    case 'generate':
      final subCommand = command.command;
      if (subCommand == null || subCommand.name != 'events') {
        stderr.writeln('使用法: ga_sync generate events [--dry-run]');
        exitCode = 1;
        return;
      }
      await GenerateCommand().run(
        configPath: command['config'] as String?,
        dryRun: subCommand['dry-run'] as bool,
      );
      break;

    case 'sync':
      final subCommand = command.command;
      if (subCommand == null) {
        stderr.writeln('使用法: ga_sync sync <routes|all> [--dry-run]');
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
          break;
        case 'all':
          await GenerateCommand().run(
            configPath: configPath,
            dryRun: dryRun,
          );
          await SyncCommand().run(
            configPath: configPath,
            dryRun: dryRun,
          );
          break;
      }
      break;

    case 'check':
      final success = await CheckCommand().run(
        configPath: command['config'] as String?,
      );
      if (!success) {
        exitCode = 1;
      }
      break;

    default:
      stderr.writeln('不明なコマンド: ${command.name}');
      exitCode = 1;
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('''
ga_sync - Google Analytics イベント定義同期ツール

使用法: ga_sync <command> [options]

コマンド:
  init                    設定ファイル (ga_sync.yaml) を作成
    -f, --force           既存ファイルを上書き

  generate events         イベント定義からコードを生成 (Spreadsheet → Code)
    -d, --dry-run         実際には生成せず、プレビューのみ
    -c, --config          設定ファイルのパス

  sync routes             ルート定義をスプレッドシートに同期 (Code → Spreadsheet)
    -d, --dry-run         実際には同期せず、プレビューのみ
    -c, --config          設定ファイルのパス

  sync all                generate events と sync routes を両方実行

  check                   生成コードが最新かチェック (CI用)
    -c, --config          設定ファイルのパス

オプション:
  -h, --help              ヘルプを表示
  -v, --version           バージョンを表示

例:
  ga_sync init                      # 設定ファイルを作成
  ga_sync generate events           # イベントコードを生成
  ga_sync generate events --dry-run # プレビューのみ
  ga_sync sync routes               # ルートを同期
  ga_sync check                     # CI用差分チェック
''');
}
