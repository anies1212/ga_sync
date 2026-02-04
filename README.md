# ga_sync

[![Pub Version](https://img.shields.io/pub/v/ga_sync)](https://pub.dev/packages/ga_sync)
[![CI](https://github.com/anies1212/ga_sync/actions/workflows/ci.yaml/badge.svg)](https://github.com/anies1212/ga_sync/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Sync Google Analytics event definitions between Google Sheets and your codebase.**

ga_sync is a CLI tool that generates type-safe Dart code from spreadsheet-managed GA event definitions, and syncs your route definitions back to the spreadsheet. Perfect for teams who manage analytics events in spreadsheets but want type-safe code.

## Features

- 📊 **Spreadsheet → Code**: Generate Dart event classes from Google Sheets
- 🛣️ **Code → Spreadsheet**: Sync go_router routes to Google Sheets
- 🔄 **Two-way sync**: Keep spreadsheet and code always in sync
- ✅ **Validation**: Catch errors before they reach production
- 🤖 **CI/CD Ready**: Auto-generate PRs when spreadsheet changes

## Quick Start

### Installation

```bash
dart pub global activate ga_sync
```

### Setup

1. **Create a Google Cloud service account** and download the JSON key
2. **Share your spreadsheet** with the service account email
3. **Initialize config**:

```bash
ga_sync init
```

4. **Edit `ga_sync.yaml`**:

```yaml
version: 1

spreadsheet:
  id: "YOUR_SPREADSHEET_ID"  # From spreadsheet URL
  credentials: "credentials.json"
  header_language: "ja"  # "en" or "ja"

events:
  sheet_name: "イベント"  # or "Events"
  output: "lib/analytics/ga_events.g.dart"

routes:
  sheet_name: "ページパス"  # or "Routes"
  source:
    - "lib/router/app_router.dart"
  parser: go_router
```

5. **Generate code**:

```bash
ga_sync generate events
```

## Usage

### Spreadsheet Format

ga_sync supports two spreadsheet formats for event definitions:

#### Format 1: Paired columns (Recommended for dropdown support)

Best for teams using dropdown menus in spreadsheets.

**English headers:**
| event_name | param1 | type1 | param2 | type2 | param3 | type3 | description | category |
|------------|--------|-------|--------|-------|--------|-------|-------------|----------|
| screen_view | screen_name | string | screen_class | string | | | Screen viewed | navigation |
| purchase | item_id | string | price | double | currency | string | Purchase completed | conversion |

**Japanese headers:**
| イベント名 | パラメータ1 | 型1 | パラメータ2 | 型2 | パラメータ3 | 型3 | 説明 | カテゴリ |
|-----------|------------|-----|------------|-----|------------|-----|------|---------|
| screen_view | screen_name | 文字列 | screen_class | 文字列 | | | 画面表示 | ナビゲーション |

- Add more parameter/type column pairs as needed (パラメータ4, 型4, ...)
- Empty cells are automatically skipped
- Each type column can use dropdown selections

#### Format 2: Comma-separated (Legacy)

| event_name | parameters | parameter_types | description | category |
|------------|------------|-----------------|-------------|----------|
| screen_view | screen_name,screen_class | string,string | Screen viewed | navigation |
| button_click | button_id,screen_name | string,string | Button clicked | interaction |

### Generated Code

```dart
// lib/analytics/ga_events.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

enum GaEventName {
  screenView,
  buttonClick,
  purchase,
}

class ScreenViewEvent {
  final String screenName;
  final String screenClass;

  const ScreenViewEvent({
    required this.screenName,
    required this.screenClass,
  });

  String get eventName => 'screen_view';

  Map<String, dynamic> toParameters() => {
    'screen_name': screenName,
    'screen_class': screenClass,
  };
}

// ... more event classes
```

### Route Sync

Add `@ga_description` and `@ga_screen_class` comments to your routes:

```dart
// @ga_screen_class: ホーム
// @ga_description: Home screen
GoRoute(
  path: '/home',
  name: 'home',
  builder: (context, state) => const HomeScreen(),
),
```

- `@ga_screen_class`: Custom screen class name (takes priority over auto-detected class)
- `@ga_description`: Description for the route

Then sync to spreadsheet:

```bash
ga_sync sync routes
```

## Commands

| Command | Description |
|---------|-------------|
| `ga_sync init` | Create config file |
| `ga_sync generate events` | Generate Dart code from spreadsheet |
| `ga_sync sync routes` | Sync routes to spreadsheet |
| `ga_sync sync all` | Run both commands |
| `ga_sync check` | Check if code is up to date (for CI) |

### Options

- `--dry-run, -d` - Preview changes without writing
- `--config, -c` - Specify config file path
- `--force, -f` - Overwrite existing files (init only)

## GitHub Actions Integration

Automatically create PRs when your spreadsheet is updated.

### 1. Add Secret

Go to `Settings > Secrets and variables > Actions` and add:
- **Name**: `GOOGLE_CREDENTIALS`
- **Value**: Your service account JSON key content

### 2. Add Workflow

Create `.github/workflows/ga-sync.yaml`:

```yaml
name: GA Sync

on:
  workflow_dispatch:  # Manual trigger
  # schedule:
  #   - cron: '0 0 * * *'  # Or daily

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1

      - run: dart pub global activate ga_sync

      - name: Setup credentials
        run: echo "${{ secrets.GOOGLE_CREDENTIALS }}" > credentials.json

      - run: ga_sync generate events
      - run: rm -f credentials.json

      - uses: peter-evans/create-pull-request@v7
        with:
          commit-message: 'chore: update GA event definitions'
          title: 'chore: update GA event definitions'
          branch: ga-sync/update-events
```

### 3. Enable Permissions

Go to `Settings > Actions > General > Workflow permissions` and select **Read and write permissions**.

## Supported Types

Both English and Japanese type names are supported:

| English | Japanese | Dart Type |
|---------|----------|-----------|
| `string` | `文字列`, `テキスト` | `String` |
| `int`, `integer` | `整数`, `数値` | `int` |
| `double`, `float`, `number` | `小数` | `double` |
| `bool`, `boolean` | `真偽値`, `フラグ` | `bool` |
| `map` | `マップ`, `辞書` | `Map<String, dynamic>` |
| `list` | `リスト`, `配列` | `List<dynamic>` |

## Environment Variables

For CI/CD, you can use environment variables instead of config file:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/credentials.json"
ga_sync generate events
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [googleapis](https://pub.dev/packages/googleapis) - Google APIs client
- [code_builder](https://pub.dev/packages/code_builder) - Dart code generation
- [analyzer](https://pub.dev/packages/analyzer) - Dart code analysis
