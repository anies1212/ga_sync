# GA Sync

A CLI tool to sync Google Analytics event definitions and page paths between spreadsheets and code.

## Features

- **Events Generator** (Spreadsheet → Code): Auto-generate Dart code from spreadsheet event definitions
- **Routes Syncer** (Code → Spreadsheet): Sync go_router route definitions to spreadsheet

## Installation

```bash
dart pub global activate ga_sync
```

Or add to `pubspec.yaml`:

```yaml
dev_dependencies:
  ga_sync: ^0.1.0
```

## Setup

### 1. Google Cloud Configuration

1. Create a project in [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Google Sheets API
3. Create a service account and download JSON key
4. Share the spreadsheet with the service account email

### 2. Initialize

```bash
ga_sync init
```

This creates `ga_sync.yaml`:

```yaml
version: 1

spreadsheet:
  id: "YOUR_SPREADSHEET_ID"
  credentials: "credentials.json"

events:
  sheet_name: "Events"
  output: "lib/analytics/ga_events.g.dart"
  language: dart

routes:
  sheet_name: "Routes"
  source:
    - "lib/router/app_router.dart"
  parser: go_router
```

## Usage

### Generate Event Code

Generate Dart code from the "Events" sheet:

```bash
ga_sync generate events
```

**Spreadsheet format:**

| event_name | parameters | param_types | description | category |
|------------|------------|-------------|-------------|----------|
| point_earned | cv_id,source_screen | string,string | When points earned | conversion |
| button_click | button_id,screen_name | string,string | When button clicked | interaction |

**Generated code:**

```dart
// lib/analytics/ga_events.g.dart
enum GaEventName {
  pointEarned,
  buttonClick,
}

class PointEarnedEvent {
  final String cvId;
  final String sourceScreen;

  const PointEarnedEvent({
    required this.cvId,
    required this.sourceScreen,
  });

  Map<String, dynamic> toParameters() => {
    'cv_id': cvId,
    'source_screen': sourceScreen,
  };
}
```

### Sync Routes

Sync go_router route definitions to spreadsheet:

```bash
ga_sync sync routes
```

**Source code:**

```dart
GoRoute(
  path: '/home',
  name: 'home',
  // @ga_description: Home screen
  builder: (context, state) => const HomeScreen(),
),
```

**Spreadsheet output:**

| path | name | description | screen_class | last_updated |
|------|------|-------------|--------------|--------------|
| /home | home | Home screen | HomeScreen | 2024-02-04 |

### CI Check

Check if generated code is up to date (for CI):

```bash
ga_sync check
```

Returns exit code 1 if there are differences.

## Commands

| Command | Description |
|---------|-------------|
| `ga_sync init` | Create config file |
| `ga_sync generate events` | Generate event code |
| `ga_sync sync routes` | Sync routes to spreadsheet |
| `ga_sync sync all` | Run both generate events and sync routes |
| `ga_sync check` | Check if generated code is up to date |

**Options:**

- `--dry-run, -d`: Preview only, don't execute
- `--config, -c`: Specify config file path
- `--force, -f`: Overwrite existing files (for init)

## Environment Variables

For CI/CD, specify credentials via environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
ga_sync generate events
```

## GitHub Actions

### Quick Start

1. **Add GitHub Secret**
   - Go to `Settings > Secrets and variables > Actions`
   - Add `GOOGLE_CREDENTIALS` with your service account JSON key content

2. **Copy workflow file**
   ```bash
   cp example/github-actions/ga-sync.yaml .github/workflows/
   ```

3. **Enable workflow permissions**
   - Go to `Settings > Actions > General > Workflow permissions`
   - Select "Read and write permissions"

### How it works

1. Trigger the workflow (manually via workflow_dispatch, or on schedule)
2. ga_sync generates event definitions from spreadsheet
3. If there are changes, a PR is automatically created

### Example workflow

```yaml
name: GA Sync

on:
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1

      - run: dart pub global activate ga_sync

      - name: Setup credentials
        env:
          GOOGLE_CREDENTIALS: ${{ secrets.GOOGLE_CREDENTIALS }}
        run: echo "$GOOGLE_CREDENTIALS" > credentials.json

      - run: ga_sync generate events
      - run: rm -f credentials.json

      - uses: peter-evans/create-pull-request@v7
        with:
          commit-message: 'chore: update GA event definitions'
          title: 'chore: update GA event definitions'
          branch: ga-sync/update-events
```

See `example/github-actions/ga-sync.yaml` for the full example.

## License

MIT License
