# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-02-04

### Added

- Initial release
- `ga_sync init` - Create configuration file
- `ga_sync generate events` - Generate Dart code from Google Sheets event definitions
- `ga_sync sync routes` - Sync go_router routes to Google Sheets
- `ga_sync sync all` - Run both generate and sync
- `ga_sync check` - Check if generated code is up to date (for CI)
- Support for `--dry-run` option
- Support for custom config file path
- Google Sheets API integration with service account authentication
- go_router parser with `@ga_description` comment support
- GitHub Actions workflow examples

### Supported Types

- `string` → `String`
- `int`, `integer` → `int`
- `double`, `float`, `number` → `double`
- `bool`, `boolean` → `bool`
- `map` → `Map<String, dynamic>`
- `list` → `List<dynamic>`

[Unreleased]: https://github.com/anies1212/ga_sync/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/anies1212/ga_sync/releases/tag/v0.1.0
