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

## ライセンス

MIT License
