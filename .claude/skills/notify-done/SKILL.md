---
name: notify-done
description: 長時間かかるジョブを実行するときに常に適用する。ジョブ完了時に通知が届くよう notify-done を末尾に付ける。
user-invocable: false
---

## 長時間ジョブの通知ルール

作業をブロックする長時間ジョブを Bash で実行する場合は、コマンドの末尾に `&& ~/.local/bin/notify-done` を付ける。

```bash
<command> && ~/.local/bin/notify-done
```

`~/.local/bin/notify-done` は通知バナーへのメッセージ表示と `say` コマンドによる音声通知を行う自作スクリプト。

### 適用する場面（目安: 30秒超のブロッキングジョブ）

- パッケージインストール（`pip install`, `pipenv install`, `npm install`, `brew install` など）
- テストスイートの実行（`pytest`, `npm test` など）
- ビルド処理（`make`, `docker build` など）
- 大規模データ処理・変換スクリプト
- モデルの学習・推論（LLM API の大量呼び出し含む）
- ファイルの大量コピー・同期（`rsync` など）

### 適用しない場面

- バックグラウンド実行（`command &`）: 終了を待たないため不要
- 即時完了が期待されるコマンド（`ls`, `git status` など）
- パイプラインの途中コマンド
