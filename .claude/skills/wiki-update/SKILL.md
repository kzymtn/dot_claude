---
name: wiki-update
description: >
  Wiki.js にページを作成・更新するときのガイド。
  「wiki に書いて」「wiki を更新して」「wiki に記録して」「wiki ページを作って」など、
  wiki.js へのコンテンツ書き込みが必要なときに使用する。
  特殊文字（LaTeX、コード、バックスラッシュ等）を含む内容の書き込みも対応。
---

# wiki-update — Wiki.js 書き込みガイド

`wiki` CLI（`~/.local/bin/wiki`）で Wiki.js にページを作成・更新する。

## 疎通確認

```bash
wiki health
```

## 操作ガイド

### ページ作成

```bash
# シンプルな作成
wiki create --path tips/docker --title "Docker メモ" --content "# Docker\n..."

# ファイルや stdin から渡す（長文・特殊文字に推奨）
cat my-note.md | wiki create --path tips/my-note --title "メモ" --stdin
wiki create --path tips/my-note --title "メモ" --stdin < my-note.md

# タグ付き
wiki create --path tips/python --title "Python Tips" --content "..." --tags python,tips
```

**2 ステップワークフロー**（LaTeX・バックスラッシュ等の特殊文字を含む場合）:

```bash
# Step 1: path/title だけ先に作成
wiki create --path tips/latex --title "LaTeX Tips" --content ""
# => {"id": 42, ...}

# Step 2: 本文を安全に設定（text/plain 送信）
wiki set-content 42 --file content.md
```

### ページ更新（部分更新）

```bash
# タイトルだけ変更
wiki update 42 --title "新しいタイトル"

# コンテンツだけ変更
wiki update 42 --content "# 更新後\n\n本文"

# タグを変更（既存タグを完全置換）
wiki update 42 --tags docker,python

# 複数フィールド同時
wiki update 42 --title "新タイトル" --tags docker
```

### コンテンツを安全に置換（特殊文字対応）

```bash
# ファイルから
wiki set-content 42 --file content.md

# stdin からパイプ
cat content.md | wiki set-content 42 --stdin
wiki set-content 42 --stdin < content.md
```

> バックスラッシュ（`\command` 等）や `$` を含む場合は `update --content` より
> こちらを使う。JSON エスケープ不要でそのまま送れる。

### ページ削除

```bash
wiki delete 42
```

> 削除は取り消せない。事前に `wiki read <path>` で対象を確認すること。

## 事前確認フロー（推奨）

書き込み前に既存ページを確認する:

```bash
# パスで確認（既存ページがあれば ID も分かる）
wiki read tips/my-page

# 見つからない場合は検索
wiki search "キーワード" -f text

# ツリーで周辺を確認
wiki tree tips
```

## Path 命名規則

- 英数字・ハイフン・スラッシュのみ（**日本語不可**）
- 階層はスラッシュ区切り: `engineering/backend/api-design`
- 推奨プレフィックス:
  - `tips/` — ノウハウ・TIL
  - `projects/` — プロジェクト記録
  - `engineering/` — 技術設計・アーキテクチャ
  - `web-apps/` — このモノレポの各アプリ情報

## エラー対処

| 症状 | 原因 | 対処 |
|------|------|------|
| `Connection refused` / 503 | wiki-js-proxy 未起動 | `sudo systemctl status wiki-js-proxy` |
| 404（read で確認中） | パスが存在しない | 新規作成で OK |
| 409 Conflict | パスが既に存在 | `update` コマンドを使う |
| `wikijs_reachable: false` | Wiki.js 本体（8087）が停止 | `cd ~/projects/web-apps-monorepo/apps/wiki && docker compose ps` |

## 高度な利用（直接 REST API）

```bash
# ページ作成
curl -s -X POST http://localhost:8089/v1/pages \
  -H "Content-Type: application/json" \
  -d '{"path":"tips/example","title":"Example","content":"# Example\n\n本文"}'

# 部分更新
curl -s -X PATCH http://localhost:8089/v1/pages/42 \
  -H "Content-Type: application/json" \
  -d '{"content": "# 更新後の内容\n\n本文"}'

# コンテンツ置換（text/plain — 特殊文字対応）
curl -s -X PUT http://localhost:8089/v1/pages/42/content \
  -H "Content-Type: text/plain" \
  --data-binary @content.md

# 削除
curl -s -X DELETE http://localhost:8089/v1/pages/42
```

## エラー時のフォールバック

wiki コマンドがエラーで失敗した場合、CLI が自動でバグレポートを試みる。

**stderr の `[bug-report]` 行で結果を確認:**

```
[bug-report] submitted via API          # プロキシ経由で送信済み
[bug-report] saved offline → <path>    # $WIKI_BUG_REPORTS_DIR 配下に保存済み
```

`$WIKI_BUG_REPORTS_DIR` のデフォルト: `~/.local/share/wiki-js-proxy/bug-reports/`（`WIKI_BUG_REPORTS_DIR` 環境変数で変更可）

**`[bug-report]` 行が出ない場合**（引数バリデーションエラー等）は手動で報告:

```bash
wiki request "[エラー要約]" \
  --description "[実行コマンド・エラー出力・再現手順]" \
  --agent "claude-code"
```

プロキシ復旧後にオフラインレポートを一括送信:

```bash
wiki sync-reports
```

## 参考

- `wiki --help` / `wiki create --help` でヘルプ表示
- OpenAPI: `http://localhost:8089/openapi.json`
- プロキシソース: `/home/kazuya/projects/web-apps-monorepo/apps/wiki-js-proxy/`
