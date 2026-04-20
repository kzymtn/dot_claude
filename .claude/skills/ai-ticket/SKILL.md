---
name: ai-ticket
description: タスク管理スキル。Plan承認後・タスク着手・中断・終了のタイミングで .ai_tasks/ にチケットを作成・更新し、Nested Git で自動コミットする。
user-invocable: false
---

# ai-ticket: AIタスクチケット管理

## 概要

このスキルは、AIエージェントの作業をチケットとして `.ai_tasks/` ディレクトリに記録・追跡する。
メインリポジトリを汚さずに、AIの思考プロセスや進捗をトレース可能にする。

---

## セットアップ（初回のみ）

`.ai_tasks/` が存在しない場合、以下を実行してから作業を開始する:

```bash
# .ai_tasks/ を Nested Git リポジトリとして初期化
mkdir .ai_tasks && cd .ai_tasks && git init && cd ..

# メインリポジトリの .gitignore に追記
echo ".ai_tasks/" >> .gitignore
```

---

## チケットのフォーマット

ファイル名: `.ai_tasks/TASK-NNN.md`（NNN はゼロ埋め3桁）

```markdown
---
id: TASK-001
title: "タスクの概要タイトル"
status: open               # open | in-progress | closed
assignee: claude           # claude | codex | kazuya
depends_on: []             # 依存チケットIDのリスト。例: [TASK-001, TASK-002]。なければ省略可
created_at: 2026-04-14T10:00:00+09:00
updated_at: 2026-04-14T10:00:00+09:00
---

## 概要

ユーザーの依頼内容・実装方針の要約。

## 作業ログ

### 2026-04-14T10:00:00 [open → in-progress]
タスク着手。〈方針・判断の記録〉

```

---

## 採番ルール

新規チケットを作成する前に既存ファイルの最大番号を確認し、+1 した番号を使用する:

```bash
ls .ai_tasks/TASK-*.md 2>/dev/null | sort | tail -1
```

ファイルが存在しない場合は `TASK-001.md` から始める。

---

## トリガー別の手順

### 1. Plan承認後・編集開始前

ユーザーが Plan を承認した直後、コードの編集を始める前に実行する:

1. チケットを新規作成（status: `open`）
2. 即座に `in-progress` に遷移し、着手コメントを作業ログに追記
3. git commit

```bash
# 例: TASK-001.md を作成し、.ai_tasks/ 内でコミット
cd .ai_tasks && git add TASK-001.md && git commit -m "[ticket] TASK-001: open → in-progress

タスク着手。〈方針の1行要約〉" && cd ..
```

### 2. タスク着手時（サブタスクに新たに取りかかるとき）

TodoWrite でタスクを `in_progress` にするタイミングと同期する:

1. 該当チケットの `updated_at` を更新
2. 作業ログにステータス遷移と着手コメントを追記
3. git commit

### 3. タスク中断時

エラー・ブロック・ユーザーの割り込みなどで作業を止めるとき:

1. `status` は `in-progress` のまま変更しない
2. 作業ログに中断理由を追記（以下のフォーマット）:

```
### 2026-04-14T11:00:00 [中断]
中断理由: 〈具体的な理由。例: sudo 権限が必要なため kazuya の対応待ち〉
次のアクション: 〈再開時に何をすべきか〉
```

3. git commit

### 4. タスク終了時

全作業が完了し、TodoWrite のタスクを `completed` にするタイミングと同期する:

1. `status` を `closed` に変更
2. `updated_at` を更新
3. 作業ログに完了サマリを追記（以下のフォーマット）:

```
### 2026-04-14T12:00:00 [in-progress → closed]
完了。〈何をしたか・結果の1〜3行サマリ〉
```

4. git commit

---

## git commit メッセージの形式

```
[ticket] TASK-NNN: <遷移内容>

<作業ログの要約（1行）>
```

例:
- `[ticket] TASK-001: open → in-progress`
- `[ticket] TASK-001: 中断（sudo 待ち）`
- `[ticket] TASK-001: in-progress → closed`

コミットは必ず `.ai_tasks/` ディレクトリ内で実行し、メインリポジトリの git には影響させない:

```bash
cd .ai_tasks && git add TASK-NNN.md && git commit -m "[ticket] TASK-NNN: ..." && cd ..
```

---

## assignee の判断基準

| assignee | 使う場面 |
|---|---|
| `claude` | デフォルト。計画・タスク分解・レビュー・実装全般 |
| `codex` | コード生成・実装を Codex に委譲するとき |
| `kazuya` | sudo が必要・人間の最終判断が必要・承認が必要な場面 |

kazuya をアサインする際は、中断理由に「何を kazuya に判断してほしいか」を明記する。

---

## 注意事項

- `.ai_tasks/` の git コミットには `--no-verify` を使わない
- チケットファイルは UTF-8 で保存する
- メインリポジトリの git 操作とは完全に分離して実行する
- `cd .ai_tasks && ... && cd ..` のように、コマンドの前後でディレクトリを明示的に戻す
