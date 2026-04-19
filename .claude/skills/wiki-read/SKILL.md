---
name: wiki-read
description: >
  Wiki.js のページを読み取り・閲覧するためのガイド。
  「wiki を読んで」「wiki のページを見せて」「wiki の {path} を確認して」
  「wiki の一覧」「wiki のタグ一覧」「wiki のツリー」
  「web-apps の wiki に何がある?」など、
  wiki.js のコンテンツを参照・閲覧するときに使用する。
---

# wiki-read — Wiki.js ページ読み取りガイド

`wiki` CLI（`~/.local/bin/wiki`）で Wiki.js のページを読み取る。

## 疎通確認

```bash
wiki health
# wikijs_reachable: true であれば OK
```

## 操作ガイド

### ① パスで読み取り（最も一般的）

```bash
wiki read tips/example
wiki read engineering/api-design
wiki read web-apps/memos-ma -f text    # テキスト形式（content が読みやすい）
```

### ② ID で読み取り

```bash
wiki read --id 42
```

### ③ 最近更新されたページ一覧

```bash
wiki list                    # 最近更新された 20 件
wiki list --limit 50
wiki list --tags docker      # タグで絞り込み
wiki list -f text
```

### ④ ツリー構造を確認

```bash
wiki tree                        # ルートから全体
wiki tree web-apps               # サブディレクトリ以下
wiki tree --mode FOLDERS         # フォルダのみ（全体構造把握に便利）
wiki tree tips --mode PAGES -f text
```

### ⑤ タグ一覧

```bash
wiki tags
wiki tags -f text
# => tag フィールドの値を wiki list --tags <tag> に渡す
```

## 複数ページの読み取りパターン

```bash
# Step 1: ツリーでパスを把握
wiki tree engineering -f text

# Step 2: 各ページを読む
wiki read engineering/api-design
wiki read engineering/backend/database
```

## 判断ガイド

| 状況 | 使うスキル |
|------|-----------|
| パス/IDが既知でページ内容を読みたい | **wiki-read** ← これ |
| キーワードで探したい・場所が不明 | **wiki-search** |
| ページ作成・更新・削除 | **wiki-update** |

## エラー対処

| 症状 | 原因 | 対処 |
|------|------|------|
| `Connection refused` / 503 | wiki-js-proxy 未起動 | `sudo systemctl status wiki-js-proxy` |
| 404 Not Found | パスが存在しない | `wiki tree` でパスを確認 |
| `wikijs_reachable: false` | Wiki.js 本体（8087）が停止 | `cd ~/projects/web-apps-monorepo/apps/wiki && docker compose ps` |

## 高度な利用（直接 REST API）

curl でも同等の操作が可能:

```bash
# パスで取得
curl -s http://localhost:8089/v1/pages/by-path/tips/example | jq '{id, path, title, content}'

# ID で取得
curl -s http://localhost:8089/v1/pages/42 | jq '{id, path, title}'

# 一覧
curl -s "http://localhost:8089/v1/pages?limit=20&orderBy=UPDATED" | jq '.items[] | {id, path, title}'

# ツリー
curl -s "http://localhost:8089/v1/tree?path=web-apps" | jq '.items[] | {path, title, isFolder}'

# タグ
curl -s http://localhost:8089/v1/tags | jq '.items[] | {tag}'
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

- `wiki --help` / `wiki read --help` でヘルプ表示
- OpenAPI: `http://localhost:8089/openapi.json`
- プロキシソース: `/home/kazuya/projects/web-apps-monorepo/apps/wiki-js-proxy/`
