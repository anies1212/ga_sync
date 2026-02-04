# GA Sync

Google Analytics のイベント定義とページパスを、スプレッドシートとコード間で双方向同期するCLIツール。

## 機能

- **Events Generator** (Spreadsheet → Code): スプレッドシートのイベント定義からDartコードを自動生成
- **Routes Syncer** (Code → Spreadsheet): go_routerのルート定義をスプレッドシートに同期

## インストール

```bash
dart pub global activate ga_sync
```

または `pubspec.yaml` に追加:

```yaml
dev_dependencies:
  ga_sync: ^0.1.0
```

## セットアップ

### 1. Google Cloud設定

1. [Google Cloud Console](https://console.cloud.google.com/)でプロジェクトを作成
2. Google Sheets APIを有効化
3. サービスアカウントを作成し、JSONキーをダウンロード
4. スプレッドシートをサービスアカウントのメールアドレスと共有

### 2. 初期化

```bash
ga_sync init
```

`ga_sync.yaml` が作成されます:

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

## 使い方

### イベントコード生成

スプレッドシートの「Events」シートからDartコードを生成:

```bash
ga_sync generate events
```

**スプレッドシート形式:**

| event_name | parameters | param_types | description | category |
|------------|------------|-------------|-------------|----------|
| point_earned | cv_id,source_screen | string,string | ポイント獲得時 | conversion |
| button_click | button_id,screen_name | string,string | ボタンクリック時 | interaction |

**生成されるコード:**

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

### ルート同期

go_routerのルート定義をスプレッドシートに同期:

```bash
ga_sync sync routes
```

**解析対象のコード:**

```dart
GoRoute(
  path: '/home',
  name: 'home',
  // @ga_description: ホーム画面
  builder: (context, state) => const HomeScreen(),
),
```

**スプレッドシートに出力:**

| path | name | description | screen_class | last_updated |
|------|------|-------------|--------------|--------------|
| /home | home | ホーム画面 | HomeScreen | 2024-02-04 |

### CI用チェック

生成コードが最新かチェック（CIで使用）:

```bash
ga_sync check
```

差分がある場合は終了コード1を返します。

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `ga_sync init` | 設定ファイルを作成 |
| `ga_sync generate events` | イベントコードを生成 |
| `ga_sync sync routes` | ルートをスプレッドシートに同期 |
| `ga_sync sync all` | generate events と sync routes を両方実行 |
| `ga_sync check` | 生成コードが最新かチェック |

**オプション:**

- `--dry-run, -d`: 実際には実行せず、プレビューのみ
- `--config, -c`: 設定ファイルのパスを指定
- `--force, -f`: 既存ファイルを上書き（init時）

## 環境変数

CI/CDでは環境変数で認証情報を指定:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
ga_sync generate events
```

## GitHub Actions

### セットアップ

1. **GitHub Secretsを設定**
   - `Settings > Secrets and variables > Actions` を開く
   - `GOOGLE_CREDENTIALS` を追加（サービスアカウントJSONキーの内容）

2. **ワークフローファイルをコピー**
   - `example/github-actions/ga-sync.yaml` を `.github/workflows/` にコピー

### 基本的なワークフロー（同期チェック）

```yaml
name: GA Sync Check

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install ga_sync
        run: dart pub global activate ga_sync

      - name: Setup credentials
        env:
          GOOGLE_CREDENTIALS: ${{ secrets.GOOGLE_CREDENTIALS }}
        run: echo "$GOOGLE_CREDENTIALS" > credentials.json

      - name: Check events sync
        run: ga_sync check

      - name: Cleanup
        if: always()
        run: rm -f credentials.json
```

### 自動PRワークフロー

スプレッドシートが更新されたら自動でPRを作成:

```yaml
name: GA Sync Auto Update

on:
  schedule:
    - cron: '0 0 * * *'  # 毎日9時 JST
  workflow_dispatch:

jobs:
  update:
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
          commit-message: 'chore: GAイベント定義を更新'
          title: 'chore: GAイベント定義を更新'
          branch: ga-sync/update-events
```

### 必要なPermissions

GitHub Actionsで自動PRを作成する場合、リポジトリ設定で以下を有効化:
- `Settings > Actions > General > Workflow permissions`
- `Read and write permissions` を選択

## ライセンス

MIT License
