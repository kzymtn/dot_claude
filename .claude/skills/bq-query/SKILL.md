---
name: bq-query
description: BigQuery の SQL クエリを書くまたはレビューするときに使う。コスト効率・可読性・冪等性を担保したクエリを書くためのガイドライン。
disable-model-invocation: false
---

## BigQuery クエリ作成ガイドライン

対象クエリ: $ARGUMENTS

---

### 構造ルール

1. **CTE を使って処理を分割する**（サブクエリのネストは 2 段まで）

```sql
WITH
  raw AS (
    SELECT ...
    FROM `project.dataset.table`
    WHERE DATE(created_at) BETWEEN @start_date AND @end_date
  ),
  filtered AS (
    SELECT ...
    FROM raw
    WHERE ...
  )
SELECT ...
FROM filtered
```

2. **パーティションフィルタを必ず含める**
   - `WHERE DATE(_PARTITIONTIME) = ...` または `WHERE date_column BETWEEN ...`
   - フルスキャンになるクエリには `-- FULL SCAN: 理由` コメントを付ける

3. **クエリパラメータを使う**（ハードコード禁止）
   - 日付: `@start_date`, `@end_date`
   - ID 系: `@user_id`, `@campaign_id`

---

### データ品質ルール

4. **NULL の扱いを明示する**
   - `COALESCE(col, 0)` や `IFNULL(col, '')` を必要な箇所に付ける
   - NULL が正しい場合はコメントで明記: `-- NULL = 未設定を意味する`

5. **JOIN は結合後の行数増減を意識する**
   - INNER JOIN: 一致しないレコードが消えることをコメントで明記
   - LEFT JOIN: NULL が発生することを考慮
   - ファンアウトリスク（1:n の JOIN で n 側が複数行ある場合）を確認

6. **DISTINCT の乱用を避ける**
   - DISTINCT が必要な場合は「なぜ重複するか」をコメントで説明

---

### 出力形式

クエリを書いた後、以下を出力する:

```
## クエリの説明
- 目的: ...
- 入力テーブル: project.dataset.table（パーティション列: date_col）
- 出力行数の想定: ...
- コスト見積もり: （スキャンするパーティション数×おおよそのサイズ）

## 注意点
- ...
```
