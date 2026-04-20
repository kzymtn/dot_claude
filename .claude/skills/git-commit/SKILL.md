---
name: git-commit
description: git commit を作成するときに使う。[type] 形式のコミットタイプ付きメッセージ・シングルイシュー原則・Claude 共著署名を自動適用する。
---

## git commit 作成ルール

### コミットタイプ一覧

Python コミュニティ固有の git commit prefix 慣習は存在しないため、広く採用されている Conventional Commits に準拠し `[type]` ブラケット形式を使用する。

| タイプ | 用途 |
|--------|------|
| `feat` | 新機能追加 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみの変更 |
| `refactor` | 機能変更なしのコード整理 |
| `test` | テストの追加・修正 |
| `chore` | ビルド・依存関係・設定などのメンテナンス |
| `perf` | パフォーマンス改善 |
| `ci` | CI/CD 設定の変更 |
| `style` | フォーマット・空白など（ロジック変更なし） |

### コミットメッセージ形式

```
[type] 変更の概要（命令形・簡潔に）

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 手順

**1. 変更内容を確認する**

以下を並行して実行する:
- `git status` でステージング状態を確認
- `git diff --staged` でステージ済み差分を確認
- `git log --oneline -5` で直近のコミット履歴とスタイルを確認

**2. シングルイシューシングルコミット原則を確認する**

ステージされた変更が **単一の目的（1 つのイシュー・機能・修正）** に絞られているかを判断する。

複数の独立した変更が混在している場合は、**コミットを実行せず**に以下を行う:
- 混在している変更の内訳をユーザーに提示する
- 変更ごとに分割してコミットすることを提案する
- ユーザーの指示を待つ

**3. コミットを実行する**

上記の確認が済んだら、以下の形式で `git commit` を実行する:

```bash
git commit -m "$(cat <<'EOF'
[type] 変更の概要

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 禁止事項

- `--no-verify` など hook をスキップするオプションの使用
- `--amend` の無断使用（ユーザーが明示的に要求した場合を除く）
- `main` / `master` への force push
- ステージされていない変更を無断でステージングする
