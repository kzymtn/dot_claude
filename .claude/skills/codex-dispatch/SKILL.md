---
name: codex-dispatch
description: codex に委譲可能なチケットを .ai_tasks/ から列挙し、codex exec で順次実行するときに使う。「codex に片付けさせて」「委譲して」などのリクエストで適用する。
user-invocable: false
---

# codex-dispatch: Codex へのチケット委譲エージェント

## 概要

`.ai_tasks/` 内の `assignee: codex` かつ `status: open` のチケットを開始可能なものから順に `codex exec` へ委譲して実行する。
Claude がオーケストレーターとして各ステップを担う。

---

## 前提条件の確認

実行前に以下を確認する:

1. `.ai_tasks/` ディレクトリが存在するか
2. `.ai_tasks/` が Git リポジトリとして初期化されているか（`ls .ai_tasks/.git`）
3. `codex` コマンドが使用可能か（`which codex`）

いずれかが満たされない場合はユーザーに報告して停止する。

---

## チケットの選定手順

### Step 1: 対象チケットの列挙

`.ai_tasks/TASK-*.md` を全件読み込み、以下の条件を満たすチケットを抽出する:

- `status: open`
- `assignee: codex`

### Step 2: 開始可能チケットのフィルタリング

抽出したチケットのうち、`depends_on` フィールドに列挙された TASK-ID が全て `status: closed` になっているもののみを対象とする。

- `depends_on` フィールドがない、または空リスト `[]` の場合は無条件で開始可能とみなす
- 依存先が未完了の場合は「依存待ち」として処理をスキップし、ユーザーへ報告する

### Step 3: 処理順の決定

開始可能チケットを `id` の昇順（TASK-001 → TASK-002 → ...）で処理する。

---

## 各チケットの処理手順

チケット 1 件ごとに以下を逐次実行する。並列実行はしない。

### 1. チケットを in-progress に遷移

チケットファイルの `status` を `open` → `in-progress` に書き換え、`updated_at` を現在時刻に更新する。
作業ログに以下を追記する:

```
### <ISO8601タイムスタンプ> [open → in-progress]
Codex へ委譲。タスク実行開始。
```

`.ai_tasks/` 内で git commit する:

```bash
cd .ai_tasks && git add TASK-NNN.md && git commit -m "[ticket] TASK-NNN: open → in-progress

Codex へ委譲。実行開始。" && cd ..
```

### 2. codex exec でタスクを実行

チケットファイルの全文をプロンプトとして `codex exec` に渡す:

```bash
codex exec \
  --full-auto \
  --cd <プロジェクトルートの絶対パス> \
  "$(cat .ai_tasks/TASK-NNN.md)"
```

`<プロジェクトルートの絶対パス>` は `pwd` で取得した現在のプロジェクトルートを使用する。

### 3. 終了後の処理

**成功（終了コード 0）の場合:**

チケットの `status` を `in-progress` → `closed` に変更し、`updated_at` を更新する。
作業ログに以下を追記する:

```
### <ISO8601タイムスタンプ> [in-progress → closed]
Codex による実行完了。
```

`.ai_tasks/` 内で git commit する:

```bash
cd .ai_tasks && git add TASK-NNN.md && git commit -m "[ticket] TASK-NNN: in-progress → closed

Codex による実行完了。" && cd ..
```

**失敗（終了コード 非0）の場合:**

`status` は `in-progress` のまま変更しない。`updated_at` を更新する。
作業ログに以下を追記する:

```
### <ISO8601タイムスタンプ> [中断]
中断理由: codex exec が非ゼロ終了（終了コード: <コード>）
次のアクション: エラー内容を確認し、手動で再実行するか assignee を kazuya に変更して人間の対応を求める
```

`.ai_tasks/` 内で git commit する:

```bash
cd .ai_tasks && git add TASK-NNN.md && git commit -m "[ticket] TASK-NNN: 中断（codex exec 失敗）" && cd ..
```

その後、次のチケットへ進む前にユーザーへ失敗を報告し、続行するか確認する。

---

## 全件処理後のサマリ報告

全チケットの処理が終わったら、以下の形式で報告する:

```
## codex-dispatch 完了サマリ

- 処理対象: N 件
- 成功（closed）: N 件
- 失敗（中断）: N 件
- 依存待ちスキップ: N 件

### 失敗したチケット
- TASK-NNN: <タイトル>（理由: ...）

### 依存待ちのチケット
- TASK-NNN: <タイトル>（depends_on: [TASK-XXX]）
```

---

## 注意事項

- `codex exec --full-auto` は `sandbox_mode: workspace-write` で動作する。sudo が必要な操作は Codex がエラーを返すため、そのチケットは失敗扱いとして `assignee: kazuya` への変更を検討する
- `.ai_tasks/` の git コミットはメインリポジトリの git と完全に分離して実行する（`cd .ai_tasks && git ... && cd ..`）
- チケットファイルは UTF-8 で保存する
