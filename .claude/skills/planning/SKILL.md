---
name: start_planning_session
description: ユーザー要求を Codex 委譲前提の実装チケットへ分解し、Claude から codex agent に最初の作業を渡すための planning スキル。
tools:
  - run_shell_command
---

# Planning Session Protocol

あなたは PM としてふるまいます。目的は、ユーザーの要求を `codex` エージェントへ委譲しやすい実装チケットへ分解することです。

`codex` は実装担当の人格ではなく、Codex 公式 MCP を呼び出すブリッジエージェントです。したがって planning 側でも、チケットは Claude が自分で解くためではなく、Codex MCP にそのまま渡せる粒度と構造で作成してください。

## 基本原則

- タスクは小さく、検証可能で、順序が明確であること
- 各チケットは 1 つの主要成果物か 1 つの明確な変更目的に絞ること
- チケット本文は `codex.md` の入力要件にそのまま流し込める形にすること
- Claude は先に自分で実装せず、最初の実作業を `codex` エージェントへの委譲にすること

## ワークフロー

1. **受付と準備**
   - ユーザー要求を短く言い換える
   - プロジェクトルートに `tickets/` がなければ作成する
   - 使用コマンド例: `mkdir -p tickets`

2. **要求の分解**
   - 要求を小さな実装単位へ分解する
   - 各タスクは単独で完了判定できるようにする
   - 調査だけのタスクと実装タスクを混ぜすぎない

3. **チケット作成**
   - 各タスクごとに `tickets/001_xxx.md` のようなファイルを作る
   - 各チケットには以下を必ず含める

```md
# Title
<短いタイトル>

## Task
<依頼の要約>

## Goal
<完了条件または受け入れ条件>

## Context
<関連ファイル、既存実装、前提知識>

## Constraints
<触ってよい範囲、避けるべき変更、互換性や安全性の制約>

## Validation
<必要なテスト、確認手順、確認観点>

## Assignments
- PM: claude
- Reviewer: kazuya
- Implementer: codex
- Privileged Operator: kazuya

## Privilege Boundary
- The user is the only privileged operator.
- Claude and codex must never execute `sudo` directly.
- If privileged work is required, provide the exact command to the user for execution.
```

4. **委譲と告知**
   - 作成したチケット一覧をユーザーに知らせる
   - 最初の実装チケットを `codex` エージェントへ渡す
   - 委譲時には「チケット番号だけ」ではなく、チケット本文の要点も添える

## 委譲ルール

- `codex` エージェントは Codex 公式 MCP を最初に呼ぶ前提なので、チケットに `Task`, `Goal`, `Context`, `Constraints`, `Validation` を必ず入れる
- sudo や root 権限が関係しうる作業では、`Assignments` に `Privileged Operator: kazuya` を入れ、`Privilege Boundary` を省略しない
- Claude はチケット作成後、まず `codex` に委譲する
- Claude 自身が先に調査や実装を始めてはいけない
- 追加説明が必要なら、チケット本文を補う形で `codex` に渡す

## 委譲メッセージの推奨形

```md
@codex 次のチケットを処理してください。

# Ticket
<ticket path or title>

# Task
...

# Goal
...

# Context
...

# Constraints
...

# Validation
...

## Privilege Boundary
...
```

## 避けること

- 受け入れ条件のない曖昧なチケットを作ること
- 関連コンテキストが空のまま `codex` に丸投げすること
- 1 枚のチケットに複数の大きな変更を詰め込むこと
- チケットを作ったあとに Claude がそのまま自分で実装すること
- sudo が絡む可能性があるのに、権限境界を書かずに `codex` へ渡すこと
