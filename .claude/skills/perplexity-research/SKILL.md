---
name: perplexity-research
description: >
  複数 Web ソースを横断検索し、段階的ランキング・クロスソース検証を経て
  全事実主張に引用を付けた回答を生成する。Perplexity / Deep Research 型の
  retrieval-rank-ground パイプラインを Gemini CLI + WebSearch + WebFetch で実装する。
  「調べて」「最新の」「比較して」「どのソースが信頼できる」「research」
  「survey」「look up」「引用付きで」「ソースを示して」「Perplexity みたいに」
  「Deep Research」などのフレーズ、または学習データだけでは検証不能な
  最新情報・比較分析・文献サーベイ・ファクトチェックが必要な質問に発動する。
  数学問題・コード生成・既知の定義など学習データのみで解ける問いには使わない。
---

# perplexity-research

/gemini-search (gemini コマンド) と WebSearch と WebFetch を使い、Perplexity 型の 5 ステージパイプラインで回答する。
引用なしの事実主張は回答に含めない。
claude のトークン数を節約するため大枠把握や論文を読むのには /gemini-search を優先的に用いる．

## パイプライン概要

```
[Stage 1] クエリ分析・サブ質問分解
      ↓
[Stage 2] ハイブリッド検索（broad + specific × サブ質問）
      ↓
[Stage 3] 段階的ランキング → フェッチ → スパン抽出
      ↓
[Stage 4] クロスソース検証
      ↓
[Stage 5] 引用付き合成 + Limitations
```

ステージを飛ばさない。時間的プレッシャーがあっても Stage 4 だけは省略禁止
（省略が事後に検出しにくいため）。

---

## Stage 1: クエリ分析・サブ質問分解

質問を次の 3 種に分類:

| 種別 | 例 | サブ質問数 |
|------|-----|-----------|
| **Factual** | 「X の現 CEO は?」 | 1 |
| **Comparative** | 「A と B のレイテンシ比較」 | 軸 × エンティティ数 |
| **Investigative** | 「X について何がわかっているか」 | 機構・証拠・限界・代替案 等 |

分解が非自明な場合のみユーザに提示する。自明なら無言で進む。

クエリ→検索式変換ルールは `references/search_query_patterns.md` 参照。

---

## Stage 2: ハイブリッド検索

各サブ質問に対して **最低 2 クエリ** 発行:
- **broad**: 標準語彙 1〜4 単語
- **specific**: モデル名・法令番号・著者名など固有語を含む 2〜6 単語

研究トピックなら追加:
- **site-scoped**: `arxiv.org` や公式ドキュメントドメインを含む検索式

候補 URL を収集後、`scripts/dedupe_domains.py` のロジック（後述）でドメイン重複排除。
目標: サブ質問ごとに **5〜15 URL** を Stage 3 に渡す。

ドメイン重複排除ロジック（Python 実行可能な場合は `scripts/dedupe_domains.py` を使う）:
```python
from urllib.parse import urlparse
seen = set()
deduped = []
for url in candidates:
    domain = urlparse(url).netloc.removeprefix("www.")
    if domain not in seen:
        seen.add(domain)
        deduped.append(url)
```

---

## Stage 3: 段階的ランキング → フェッチ → スパン抽出

### プリフィルタ（スニペットのみ、フェッチ前）

除外条件（いずれか該当で DROP）:
1. `references/source_quality_rubric.md` の除外リストに該当するドメイン
2. スニペットにサブ質問の回答語句がない
3. freshness 要件を満たさない（「最新」「現在」を含む質問 → 1 年以内、歴史的質問 → 無制限）

### 一次ランキング（残存 URL に適用）

優先順位:
1. Tier 1（公式ドキュメント、査読済み、政府機関、一次ソースジャーナリズム）
2. Tier 2（確立したトレード誌、署名付き技術ブログ）
3. Tier 3（Wikipedia 等 — 一次ソースがない場合のみ）

詳細は `references/source_quality_rubric.md` 参照。

### フェッチ

各サブ質問の上位 3〜5 URL を WebFetch で取得。
フェッチ後、サブ質問に回答する **具体的なスパン（文または段落）** を特定し verbatim で記録。
引用に使うのはスパンであり、ページ全体ではない。

---

## Stage 4: クロスソース検証

最終回答に使う各主張について:

| 状況 | 処置 |
|------|------|
| ソース 1 つのみが支持 | single-sourced とマーク |
| 複数ソースが一致 | 最権威ソースのみ引用 |
| ソース間で矛盾 | 両立場を引用付きで提示、矛盾を明示（自動採用禁止） |
| 取得スパンに紐付けられない | 回答から除外 or "未検証" と明示 |

---

## Stage 5: 引用付き合成 + Limitations

引用ルール詳細は `references/citation_format.md` 参照。核心ルール:

- 事実主張を含む全文に引用マーカーを付ける
- デフォルトは言い換え、直接引用は法的文言・定義・発言帰属に限定
- 矛盾は「Source A は X と報告 [cite]。Source B は Y と報告 [cite]。相違原因: <理由>」形式
- 回答を答えから始める（証拠から始めない）

**Limitations セクションを必ず末尾に付ける**:
```
**Limitations**
- <検索で埋まらなかったサブ質問>
- <未解決の矛盾>
- <ペイウォール等のカバレッジ留保>
```

---

## アンチパターン

- 記憶で検索未取得の主張を補完すること
- 「複数ソースが〜と述べている」のような集約引用（個別帰属すること）
- クエリ外の内容で回答を水増しすること
- Stage 4 の省略
- スパンが存在しないのに存在するかのように見せる引用
