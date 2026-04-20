# marimo-cell-edit

user-invocable: false

## When to Apply

以下のいずれかに該当するとき、自動的に本スキルを適用する:

- **marimo notebook を新規作成・起動するとき** — 新しい `.py` ファイルを作成してサーバーを起動する
- **実行中の marimo notebook のセルを追加・編集するとき** — `@app.cell` を含むファイルに変更が必要

サーバーが停止中で直接ファイル編集するフォールバックは `marimo-edit` スキルを参照。

---

## 1. サーバー起動手順（ノートブック作成含む）

### 基本形 — `marimo-serve` を使う（ゾンビシェル防止）

```bash
marimo-serve [--port PORT] [--with PKG]... <file.py>
```

`uvx marimo edit ... &` を Claude Code の `run_in_background: true` で起動すると、marimo プロセスが生きている間ずっとシェル ID が残留してゾンビになる。`marimo-serve` は `nohup` + PID ファイルでデーモン化するため、起動コマンド自体は数秒で完了しシェル ID が蓄積しない。

```bash
# 例: matplotlib を使うノートブックを起動
marimo-serve --with matplotlib notebook.py

# 例: ポートを指定して起動
marimo-serve --port 2725 --with matplotlib --with pandas analysis.py

# 例: 新規ファイル（空ノートブック）
marimo-serve new_analysis.py

# 停止
marimo-serve --stop 2725
```

出力例:
```
started  port=2725  pid=82723  notebook=/path/to/notebook.py
url      http://localhost:2725
log      ~/.local/state/marimo/logs/2725.log
stop     marimo-serve --stop 2725
```

**内部動作**: `--no-token --no-skew-protection --watch` は自動付与。`runtime.watcher_on_save = "autorun"`（`~/.config/marimo/marimo.toml`）と組み合わせることで、ファイルを書いた瞬間に変更セルが自動実行される。

### パッケージの決定方法

`uvx marimo` は隔離環境で動くため、`marimo` 以外のパッケージは `--with` で明示する。

1. 既存ファイルの場合: `import` 文をスキャンして標準ライブラリ以外を列挙
2. 新規ファイルの場合: 使用予定のパッケージを事前に指定

**不要なもの**: `marimo` 自体、Python 標準ライブラリ（`os`, `re`, `json` 等）

### ポートの指定

`--port` を省略すると 2725 から空きポートを自動選択する。複数ノートブックを同時起動する場合は明示指定を推奨。

### バックグラウンド起動

```bash
uvx --with matplotlib marimo edit --no-token --no-skew-protection notebook.py &
# 起動確認（数秒待つ）
sleep 3 && curl -s http://localhost:<PORT>/api/sessions
```

---

## 2. セル状態の確認

編集前にノートブックの現在の状態を確認する:

```bash
# セル一覧を JSON で取得（フルコード付き）
python ~/.claude/skills/marimo-cell-edit/scripts/get_cells.py

# 複数セッションがある場合はファイル名で絞り込む
python ~/.claude/skills/marimo-cell-edit/scripts/get_cells.py --file notebook.py

# ポートを直接指定する場合
python ~/.claude/skills/marimo-cell-edit/scripts/get_cells.py --port 2722
```

出力例:
```json
{
  "base_url": "http://127.0.0.1:2722",
  "session_id": "s_abc123",
  "notebook_path": "/path/to/notebook.py",
  "cells": [
    {"cell_id": "Hbol", "name": "imports", "code": "import marimo as mo\nimport matplotlib.pyplot as plt"},
    {"cell_id": "MJUe", "name": "data", "code": "df = pd.read_csv('data.csv')"}
  ]
}
```

`cell_id` は marimo の内部 ID（`Hbol` 等）。`marimo-cell-edit` に渡す際は function name（`imports` 等）でも可。

---

## 3. セル編集 Workflow

### 単一セルの編集・追加

```bash
# 既存セルを function name で編集（内部 ID に自動解決される）
marimo-cell-edit --save <function_name> "<code>"

# 新規セルを追加（任意の一意な ID を使う）
marimo-cell-edit --save my-new-cell "<code>"

# 改行を含むコード
marimo-cell-edit --save my-cell "x = 1\ny = 2\nprint(x + y)"

# 長いコードは stdin から
cat << 'EOF' | marimo-cell-edit --save my-cell -
import pandas as pd
df = pd.read_csv('data.csv')
df.head()
EOF
```

### 複数セルの一括編集

```bash
# batch.json を用意して一括実行
marimo-cell-edit --save --batch batch.json
```

`batch.json` の形式:
```json
[
  {"cell_id": "imports", "code": "import marimo as mo\nimport pandas as pd"},
  {"cell_id": "new-analysis", "code": "df = pd.read_csv('data.csv')\ndf.describe()"}
]
```

### 複数ノートブックが起動中の場合

```bash
marimo-cell-edit --file notebook.py --save <cell_id> "<code>"
```

---

## 4. その他の操作

```bash
# セッション一覧
marimo-cell-edit --list-sessions

# セル一覧（人間向け表示・60文字切り詰め）
marimo-cell-edit --list-cells

# リクエスト内容を確認（送信しない）
marimo-cell-edit --dry-run my-cell "print('hello')"
```

---

## 5. 制約・注意事項

### `success: true` はリクエスト受理のみ

`POST /api/kernel/run` が `{"success": true}` を返しても、セルの実行エラーは含まない。
実行エラーは WebSocket 経由でブラウザに届くため REST API からは確認できない。
エラー確認には MCP の `get_notebook_errors` ツールを使うか、ブラウザで目視確認する。

### cell_id の自動解決

`marimo-cell-edit` に function name（例: `"imports"`）を渡すと、内部 ID（例: `"Hbol"`）に自動解決してから `/api/kernel/run` に送信する。function name をそのまま `/api/kernel/run` に渡すと新規セルが作成されて変数衝突が起きるため、このツールを通じて操作すること。

### 新規セルのセル ID

新規追加セルの `cell_id` はファイル保存後に marimo がリロードすると seed=42 で再割り当てされる。
再度 `scripts/get_cells.py` を実行して最新の ID を確認すること。
