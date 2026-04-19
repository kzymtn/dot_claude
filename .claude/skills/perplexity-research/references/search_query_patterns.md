# Search query patterns

## Rules

- 1〜6 単語
- メタ語禁止: "最新の" "包括的な" "ベストガイド" は検索精度を下げる
- 時間修飾子は質問が時間限定の場合のみ（例: "2024"）
- `site:` 演算子: site-scoped クエリのみで使用
- 引用符: ユーザが明示した場合のみ

## クエリ種別テンプレート

### Factual
```
"<エンティティ> <属性>"
例: ユーザ「現在の USD/JPY レートは?」→ クエリ: "USD JPY rate"
```

### Comparative
```
"<A> vs <B>"
または "<A> <軸>", "<B> <軸>" を別クエリで（直接比較がインデックスされにくい場合）
```

### Investigative
```
broad: "<トピック>"
→ narrow: "<トピック> <サブアスペクト>"
例: "relativistic spin hydrodynamics"
  → "spin hydrodynamics review"
  → "spin hydrodynamics heavy ion"
```

## サブ質問 → クエリのマッピング原則

1 サブ質問 = 最低 2 クエリ（broad + specific）。
単一クエリは corpus の一部しか取れない。

## クエリ再試行のタイミング

初回検索で Tier 1 ソースが 0 件の場合:
1. 語彙を変えた別クエリを 1 本発行
2. それでも 0 件なら Tier 2 に降格して採用し、Limitations に記載
