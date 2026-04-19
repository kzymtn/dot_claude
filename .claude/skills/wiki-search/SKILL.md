---
name: wiki-search
description: >
  Wiki.js でページを検索・発見するためのガイド。
  「wiki で {keyword} について調べて」「wiki に XXX の情報はある?」
  「wiki で検索して」「wiki から関連ページを探して」
  「wiki で {topic} に関するページを見つけて」など、
  コンテンツの場所が不明で検索・発見が必要なときに使用する。
---

# wiki-search — Wiki.js 検索・発見ガイド

`wiki` CLI（`~/.local/bin/wiki`）で Wiki.js のページを検索・発見する。

## 疎通確認

```bash
wiki health
```

## 操作ガイド

### ① キーワード全文検索（最も一般的）

```bash
wiki search "Docker"
wiki search "Docker compose"     # スペース区切りで複合検索
wiki search "postgresql"         # 英語キーワードも有効
wiki search "デプロイ"           # 日本語対応
wiki search "docker" -f text     # テキスト形式（snippet が読みやすい）
```

> ⚠️ 検索結果の `id` は**文字列型**（例: `"42"`）。
> ページ操作には `wiki read <path>` で数値 ID を取得すること。

### ② タグで絞り込み

```bash
wiki tags                        # まずタグ一覧を確認
wiki list --tags docker
wiki list --tags docker,python   # 複数タグ（いずれかに一致）
```

### ③ ツリーで探索的発見

```bash
wiki tree                        # 全体構造
wiki tree engineering            # テーマ別に掘り下げ
wiki tree --mode FOLDERS         # フォルダのみ（どんな階層があるか把握）
```

## 推奨検索戦略

### パターン A: キーワードが明確

```bash
# 1. 全文検索でパスを特定
wiki search "Docker compose" -f text

# 2. パスで全文取得（wiki-read）
wiki read tips/docker-compose
```

### パターン B: 存在確認（「XXX の情報はある?」）

```bash
# 1回目
wiki search "PostgreSQL" -f text

# 0 件なら別キーワードで
wiki search "postgres database" -f text

# それでも 0 件 → 「wiki には該当ページがありません」と報告
```

### パターン C: テーマ別に網羅

```bash
# Step 1: 関連タグを確認
wiki tags -f text | grep -i docker

# Step 2: タグ絞り込み
wiki list --tags docker -f text

# Step 3: ツリーも確認（タグなしページを拾う）
wiki tree engineering -f text
```

## 検索 → 読み取り → 更新の連携フロー

```bash
# 検索
wiki search "デプロイ" -f text
# => path: projects/my-app/deployment

# 全文取得（wiki-read）
wiki read projects/my-app/deployment
# => id: 42

# 更新（wiki-update）
wiki update 42 --content "# 更新後\n\n..."
```

## 判断ガイド

| 状況 | 使うスキル |
|------|-----------|
| キーワード・テーマでページを探したい | **wiki-search** ← これ |
| パス/IDが既知でページ内容を読みたい | **wiki-read** |
| ページ作成・更新・削除 | **wiki-update** |

## エラー対処 / 検索のヒント

| 状況 | 対処 |
|------|------|
| `Connection refused` / 503 | `sudo systemctl status wiki-js-proxy` |
| `total: 0` | 別キーワード・英語・部分文字列で再試行 |
| 検索結果の id でページ操作したい | `wiki read <path>` で数値 ID を再取得 |

## 高度な利用（直接 REST API）

```bash
# 全文検索
curl -s "http://localhost:8089/v1/search?q=キーワード" \
  | jq '{query, total, results: [.results[] | {id, path, title, snippet}]}'

# タグ絞り込み
curl -s "http://localhost:8089/v1/pages?tags=docker&limit=50" \
  | jq '.items[] | {id, path, title}'

# ツリー
curl -s "http://localhost:8089/v1/tree?path=engineering" \
  | jq '.items[] | {path, title, isFolder, depth}'
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

- `wiki --help` / `wiki search --help` でヘルプ表示
- OpenAPI: `http://localhost:8089/openapi.json`
