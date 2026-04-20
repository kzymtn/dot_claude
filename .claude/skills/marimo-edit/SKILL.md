# marimo-edit

user-invocable: false

## When to Apply

以下のいずれかに該当するとき、自動的に本スキルを適用する:

- **marimo notebook の情報を得るとき** — 実行中ノートブックのセル構造・変数・エラー・依存グラフなどを調べる必要がある
- **marimo が停止中でファイルを直接編集するとき** — サーバーが起動していない状態で `.py` ファイルを編集する

**ノートブックの作成・起動・セル編集は `marimo-cell-edit` スキルに委譲する。**

---

## marimo notebook の情報を得るとき

セルの内容・変数の状態・エラー・依存関係を調べる際は MCP ツールを優先する。

### 利用可能な MCP ツール

| ツール | 用途 |
|--------|------|
| `get_active_notebooks` | アクティブセッション一覧。常にここから始める |
| `get_lightweight_cell_map` | 全セルの構造・ID・実行状態・型の概要 |
| `get_cell_runtime_data` | セルの詳細な実行情報・エラー・定義変数 |
| `get_cell_outputs` | セルの出力内容（HTML・画像・テキスト） |
| `get_cell_dependency_graph` | セル依存グラフ・変数の所有関係 |
| `get_tables_and_variables` | 変数・DataFrame・テーブルの情報 |
| `get_database_tables` | データベース接続のスキーマ |
| `get_notebook_errors` | ランタイムエラー一覧 |
| `lint_notebook` | marimo Lint エラー一覧 |
| `get_marimo_rules` | marimo 公式ガイドライン |

**`edit_notebook` / `run_stale_cells` は外部エージェントから呼び出せない。** これらは marimo エディタ内蔵チャット専用ツール。

### 推奨手順

1. `get_active_notebooks` — セッション確認
2. `get_lightweight_cell_map` — 構造概要（セル数が多い場合はここで絞り込む）
3. 目的に応じて追加取得:
   - エラー調査 → `get_notebook_errors` + `get_cell_runtime_data`
   - 変数確認 → `get_tables_and_variables`
   - 依存把握 → `get_cell_dependency_graph`
   - 出力確認 → `get_cell_outputs`

セッションが存在しない場合のみ、ソースファイルの直接読み込みにフォールバックする。

---

## marimo が停止中のとき（直接ファイル編集）

サーバーが起動していない場合のフォールバック。

1. `Edit` ツールで最小限の差分変更を行う
2. marimo notebook の規約に従う:
   - 各セルは `@app.cell` 装飾付き関数
   - 出力は末尾の `(value,)` タプルで返す
   - セル外にトップレベルの代入を置かない
   - 依存変数は関数引数として宣言する
3. `uvx marimo check <file.py>` で構文・marimo 規約を検証する

marimo が変更を自動検知するため、次回起動時に影響セルが再実行される。

---

## ユーザーにセルの手動実行を要求しない

**禁止:** 「セル X を実行してください」「ノートブックを再実行してください」
**許容:** 「編集しました」（実行への言及なし）/ 「セルを追加・実行しました」
