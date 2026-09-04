1. **目的**: CIで実行される bats テストの結果を JUnit 形式で出力し、Pull Request 上で直接確認できるようにすることで、CIログを追う手間を省き、開発体験を向上させます。
2. **導入する/変更するもの**:
   - `.github/workflows/test.yml`: `bats` の実行オプションを変更し、`EnricoMi/publish-unit-test-result-action` を追加しました。また、Action が結果を投稿できるよう `permissions` に `checks: write`, `pull-requests: write` を追加しました。
   - `docs/AI_AUTOMATION.md`: 新規導入したツールの目的や無料であることの証明を記載しました。
3. **「公開 OSS で完全無料」の証明**: `EnricoMi/publish-unit-test-result-action` はオープンソースの GitHub Action であり、外部サービスや API を利用せず、GitHub Actions のランナー上でローカルに実行され、組み込みの `GITHUB_TOKEN` を使って GitHub API にのみアクセスするため、[GitHub Actions の料金](https://docs.github.com/en/billing/concepts/product-billing/github-actions) 以外に課金が発生しません (公開 OSS リポジトリでは完全無料)。
4. **既存ツールとの重複がないことの確認**: 現在、リポジトリに導入されている静的解析や Lint ツール（CodeRabbit、actionlint など）はコード品質をチェックするものであり、テスト実行結果のレポートを PR にインライン表示するツールは導入されていないため、機能の重複はありません。
5. **マージ前に必要な手動セットアップ手順**:
   1. 特に追加の設定は不要です。マージ後、次回以降の PR から自動的にテスト結果のレポートが作成されます。
6. **想定リスクとロールバック手順**:
   - リスク: GitHub Token の権限不足などにより Action が失敗する可能性があります。
   - ロールバック手順: `.github/workflows/test.yml` から `EnricoMi/publish-unit-test-result-action` のステップを削除して PR をマージするか、Revert します。
