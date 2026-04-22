---
name: open-marimo
description: >
  marimo でノートブックを開く・再起動するときに使う。
  「marimo で開いて」「marimo を起動して」「marimo を再起動して」などのリクエストで適用する。
---

# open-marimo スキル

ユーザーから marimo でノートブックを開くよう指示されたとき、以下の手順を実行する。

## 手順

### 1. 既存の marimo プロセスを停止

対象ファイルに関連する marimo プロセスが起動中であれば停止する。

```bash
pkill -f "marimo edit <notebook.py>"
sleep 1 && ps aux | grep "marimo edit" | grep -v grep
```

### 2. marimo を起動する

プロジェクトの `uv` 環境でバックグラウンド起動する。必ず以下のオプションをすべて付ける:

```bash
uv run marimo edit <notebook.py> --watch --no-token --mcp --port <port>
```

`run_in_background: true` で起動し、shell ID を保持しておく。

| オプション | 理由 |
|---|---|
| `--watch` | ファイル変更を監視してブラウザに即時反映（**必須**。これがないと Claude の編集がブラウザに届かない） |
| `--no-token` | トークン認証を無効化してブラウザ・MCP どちらからもアクセスしやすくする |
| `--mcp` | MCP サーバーを有効化して Claude が notebook を操作できるようにする（**必須**。これがないと `get_active_notebooks` が機能しない） |
| `--port <port>` | ポートを固定して毎回同じ URL でアクセスできるようにする |

**デフォルトポート**: `2718`。既に使用中なら `2719` など別のポートを選ぶ。

### 3. 起動確認

```bash
sleep 3 && curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>
```

200 が返れば起動成功。

### 4. セッション ID を取得する

起動後は必ず `get_active_notebooks` でセッション ID を取得して記録する。

```
mcp__marimo__get_active_notebooks → session_id を記録
```

**重要**: セッション ID はプロセス再起動のたびに変わる。MCP ツールを呼ぶ前に毎回 `get_active_notebooks` で最新の session_id を確認すること。`SESSION_NOT_FOUND` エラーが出たら必ずここに戻る。

### 5. ユーザーへの報告

- URL: `http://localhost:<port>`
- session_id

---

## セッション管理のパターン（よくあるトラブル）

### SESSION_NOT_FOUND エラーが出たとき

marimo の再起動・ブラウザのリロード・`--watch` によるリロードでセッション ID が変わる。
エラーが出たら即座に `get_active_notebooks` を呼び直して新しい session_id を取得する。

```
# エラー例
{"message":"Session s_xxxx not found","code":"SESSION_NOT_FOUND"}

# 対処
→ mcp__marimo__get_active_notebooks で session_id を再取得してから再試行
```

### セルが実行されないとき

`--watch` モードでは marimo の auto-save が無効になるという警告が出るが、**`--watch` は外さない**。
セルが実行されていない場合はブラウザで **Cmd+Shift+Enter**（全セル実行）を案内する。

### ゾンビ background shell を殺すとき

`KillShell` ツールの正しいパラメータは `shell_id`（`bash_id` ではない）:

```
KillShell(shell_id="<id>")
```

すでに dead な shell に対して kill しようとするとエラーになるが無視してよい。

### `--watch` なしで起動してしまったとき

Claude がファイルを編集してもブラウザに反映されない。プロセスを kill して `--watch` 付きで再起動する。

---

## 注意事項

- プロジェクトに `uv` 環境がある場合は必ず `uv run marimo` を使う（グローバルの `marimo` は使わない）。
- `--watch` と auto-save の競合警告 `[W] Enabling watch mode may interfere with auto-save.` は無視してよい。
