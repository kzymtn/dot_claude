---
name: external-api
description: 外部API（LLM API・Web API等）を呼び出す処理を実装するときに常に適用する。処理時間の見積もり・TEST_MODE によるバッチ検証・キャッシュ活用に関するベストプラクティス。 (project, gitignored)
---

## 外部API利用時の注意

- **処理時間を事前に見積もる**: LLM APIなどの外部サービス呼び出しは想定より時間がかかる
  - API呼び出し回数×レイテンシで大まかな処理時間を見積もる
  - バッチ処理の場合は、小規模テスト（TEST_MODE）で1件あたりの時間を測定してから本番実行
  - キャッシュ機構（joblib.Memory等）を活用して再実行を高速化
