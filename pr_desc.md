## 目的
JTF日本語標準スタイルガイドに沿ったドキュメントの静的チェック（textlint）を自動化し、日本語ドキュメントの品質と統一感を向上させるため。

## 導入するもの
- `.github/workflows/textlint.yml`: textlint による静的解析を CI で実行するワークフロー。
- `.textlintrc.json`: `textlint-rule-preset-ja-technical-writing` を使用するための設定ファイル。
- `docs/AI_AUTOMATION.md`: 導入ツール一覧に textlint を追加。

## 「公開 OSS で完全無料」の証明
GitHub-hosted runner 上で `npx` を利用して実行されるため、GitHub Actions の公開リポジトリ向け無料枠に含まれます。
- https://docs.github.com/ja/billing/managing-billing-for-github-actions/about-billing-for-github-actions#about-billing-for-github-actions

## 既存ツールとの重複がないことの確認
既存のリンター（actionlint, shellcheck, shfmt, hadolint, markdownlint-cli2, cspell）はいずれも「日本語の文章校正（文法、表記ゆれなど）」を行うものではないため、機能の重複はありません。

## マージ前に必要な手動セットアップ手順
1. 特に追加の App インストールや設定は不要です。マージ後、次回以降の PR および main ブランチへの Push で自動的に実行されます。

## 想定リスクとロールバック手順
- **想定リスク**: `textlint` が既存のドキュメントでエラーを多数検知し、CI が失敗する可能性があります。これを回避するため、初期導入時は `continue-on-error: true` を設定しています。
- **ロールバック手順**: 本 PR を Revert してください。
