---
name: delegate-to-gemini
description: >
  自身のコンテキストウィンドウに収まらない大規模なリポジトリ・ファイル群を解析する際、
  巨大コンテキスト（100万トークン超）を持つ Gemini CLI に処理を委譲するスキル。
  「リポジトリ全体を解析」「全ファイルを読んで」「大量のファイル」「コードベース全体」
  などのフレーズ、または解析対象のサイズ測定でしきい値を超えた場合に発動する。
  コンテキスト節約が目的なので、小規模ファイルやすでに絞り込み済みの対象には使わない。
---

# delegate-to-gemini

Gemini CLI (`gemini` コマンド) に大規模コンテキスト処理を委譲するスキル。
解析対象のサイズを事前に測定し、しきい値を超えた場合のみ委譲する。

## しきい値（3 段階）

| 操作 | 測定コマンド | しきい値 | 超過時の対応 |
|------|-------------|---------|------------|
| ディレクトリ構造把握 | `tree -L 4 -I "..." \| wc -m` | > 10,000 chars | Gemini に構造解析を委譲 |
| ディレクトリ内容合計 | `git ls-files \| xargs wc -c \| tail -1` | > 150,000 bytes | Gemini に内容解析を委譲 |
| 単一ファイル読み取り前 | `wc -m <file>` または `wc -c <file>` | > 50,000 chars | Gemini にファイル解析を委譲 |

## 手順

### Step 1: サイズ測定

解析対象に応じて下記コマンドを実行し、しきい値と比較する。

```bash
# ── ディレクトリ構造の文字数確認 ──────────────────────────────
tree -L 4 -I "node_modules|.git|dist|build|__pycache__|.venv" <target> | wc -m

# ── ディレクトリ内容の合計バイト確認（git 管理下） ────────────
git ls-files | xargs wc -c 2>/dev/null | tail -1

# ── ディレクトリ内容の合計バイト確認（git 管理外） ────────────
find <target> -type f | xargs wc -c 2>/dev/null | tail -1

# ── 単一ファイルの文字数確認 ──────────────────────────────────
wc -m <file>
# または
wc -c <file>
```

しきい値未満なら通常通り Read ツールや Glob/Grep で自力処理する。

### Step 2: プロンプト構築

委譲が必要と判断したら、Gemini に渡すプロンプトを組み立てる。

- **何を知りたいか** を 1〜3 文で明確に記述する
- 対象ファイル・パスを特定する
- ユーザーの元の質問をそのまま含める

### Step 3: Gemini CLI 実行

**パターン A — ディレクトリ構造解析**

```bash
gemini --yolo -o text "$(printf 'ディレクトリ構造:\n'; tree -L 5 -I 'node_modules|.git|dist|build|__pycache__|.venv' <target>; printf '\n\n質問: <ユーザーの質問>')"
```

**パターン B — ディレクトリ内容解析（git 管理下）**

```bash
gemini --yolo -o text "$(printf 'コードベース内容:\n\n'; git ls-files | head -200 | xargs cat 2>/dev/null | head -c 800000; printf '\n\n質問: <ユーザーの質問>')"
```

> `head -c 800000` で約 800KB に制限し、Gemini の入力上限を超えないようにする。
> ファイル数が多い場合は `git ls-files -- '*.py' '*.ts' '*.md'` のように絞り込む。

**パターン C — 単一ファイル解析**

```bash
gemini --yolo -o text "$(printf 'ファイル内容:\n\n'; cat <file>; printf '\n\n質問: <ユーザーの質問>')"
```

### Step 4: 結果を整理してユーザーに返す

- 出力の先頭にある `YOLO mode is enabled` や `Loaded cached credentials.` はノイズなので除いてよい
- Gemini の回答をそのまま or 整形してユーザーに返す
- 不足部分があれば追加クエリを送る（パターン A〜C を組み合わせてよい）

## 委譲しない条件

- しきい値未満（無条件委譲はしない）
- grep / Glob ですでに対象を絞り込み済みで読める量になっている
- コード生成・既知の定義・数学計算など学習データで解ける問い
- ユーザーが「自分で読んで」と明示した場合

## 注意事項

- `gemini` は `/usr/local/bin/gemini` に存在する
- 認証は `Loaded cached credentials.` で確認（初回は `gcloud auth` が必要な場合あり）
- プロンプト内にシングルクォートが含まれる場合は `printf '%s' "..."` 等でエスケープする
- バイナリファイルは `xargs wc -c` の対象から除外する（`find -name "*.py" -o -name "*.ts"` 等で絞る）
- 実行に失敗した場合はエラー内容を確認し、パスや文字列エスケープを見直して再試行する
- レート制限・エラー時はユーザーに通知する
