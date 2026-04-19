---
name: gemini-search
description: >
  Gemini CLI に Web 検索を委譲し、結果を返す。
  WebSearch/WebFetch ツールが使えない・遅い・制限されている場合や、
  「Gemini で調べて」「gemini に検索させて」「gemini-search」などの
  フレーズで発動する。
  Google 検索グラウンディングを使うため最新情報・リアルタイム情報に強い。
---

# gemini-search

Gemini CLI (`gemini` コマンド) に Web 検索を委譲するスキル。
内部で `google_web_search` ツールを使い、結果を要約して返す。

## 使い方

```bash
gemini --yolo -o text "<検索クエリをここに記述>"
```

**必須オプション:**
- `--yolo`: ツール呼び出しを自動承認（`google_web_search` が自動実行される）
- `-o text`: テキスト形式で出力

## 実行手順

1. ユーザーの質問からクエリを構築
2. Bash ツールで `gemini --yolo -o text "<query>"` を実行
3. 結果をそのまま or 整形してユーザーに返す

## クエリ構築ガイドライン

| 状況 | クエリ例 |
|------|---------|
| 最新情報 | `"<topic> 2025 latest"` |
| 比較 | `"<A> vs <B> comparison"` |
| 日本語 | 日本語クエリそのまま渡してOK |
| 複数観点 | 複数回 gemini を呼ぶ（クエリを変えて） |

## 出力に "YOLO mode is enabled" が含まれる場合

これは正常。`Loaded cached credentials.` の後から実際の回答。
ユーザーへの表示時はこれらのヘッダー行を除いてよい。

## 例

```bash
# 日本語
gemini --yolo -o text "Claude Code 最新機能 2025年"

# 英語比較
gemini --yolo -o text "Cursor vs Claude Code comparison 2025"

# 特定トピック
gemini --yolo -o text "React Server Components best practices 2025"
```

## 注意

- `gemini` は `/usr/local/bin/gemini` に存在
- 認証は `Loaded cached credentials.` で確認（初回は `gcloud auth` が必要な場合あり）
- レート制限・エラー時はユーザーに通知して perplexity-research スキルに fallback
