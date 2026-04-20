---
name: py-module-scaffold
description: 新しい Python モジュール・スクリプトの雛形を生成する。pipenv プロジェクト・loguru・ruff に準拠した構成で作る。/py-module-scaffold <モジュール名> で呼び出す。
disable-model-invocation: true
allowed-tools: Read, Write, Bash
---

## Python モジュール雛形の生成

対象: $ARGUMENTS

---

### 生成するファイル

現在のディレクトリ構成を確認してから、以下を生成する:

1. **メインスクリプト** (`scripts/<name>.py` または `src/<package>/<name>.py`)

```python
"""
<name>: <1行の説明>

Usage:
    python scripts/<name>.py [options]
"""
from __future__ import annotations

import sys
from pathlib import Path

from loguru import logger


def main() -> None:
    """エントリポイント"""
    logger.info("Starting <name>")
    # TODO: 実装
    logger.info("Done")


if __name__ == "__main__":
    # ログ設定: INFO 以上を stderr に出力
    logger.remove()
    logger.add(sys.stderr, level="INFO")
    main()
```

2. **確認事項をユーザーに提示**

以下を確認してからファイルを生成する:

- モジュールの目的（1行）
- 入力（ファイル / BigQuery / 引数）
- 出力（ファイル / BigQuery / 標準出力）
- 配置先ディレクトリ（`scripts/` か `src/` か）

### 生成後の確認

```bash
ruff check <生成したファイルのパス>
```

エラーがあれば修正してから完了を報告する。

### コーディング規約（必ず守る）

- Python 3.11+ の型ヒントを使う（`list[str]` など、`List[str]` は使わない）
- `print()` を使わず `logger.info()` / `logger.warning()` / `logger.error()` を使う
- docstring は Google スタイル
- `from __future__ import annotations` を先頭に付ける
