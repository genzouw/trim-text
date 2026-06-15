# AGENTS.md

このファイルは、本リポジトリ（`trim-text`）でコード変更や PR 作成を行うすべての AI コーディングエージェント（**Jules / OpenAI Codex / Cursor / Cline / Roo Code / Aider / Claude Code 等**）が **作業開始前に必ず読み込み、すべての提案・実装・PR 作成において遵守すべき最上位ルール** を定義するものです。

本ファイルの内容は、`README.md`・`docs/AI_AUTOMATION.md`・`.github/copilot-instructions.md` などのほかのドキュメントよりも **優先** されます。本ファイルの内容と矛盾する提案・実装は行わないでください。

## 1. 会話・成果物の言語

- すべての応答・コードコメント・コミットメッセージ・PR タイトル・PR 本文・Issue コメントは **日本語** で記述してください。
- 例外: コードそのもの（識別子・キーワード・ライブラリ呼び出し）と、外部固有名詞は原文のままで構いません。

## 2. CI/CD への新規サービス導入ポリシー（**最重要・絶対遵守**）

本リポジトリの CI/CD（GitHub Actions を含むすべての自動化ワークフロー）には、**公開 OSS リポジトリ向けに完全無料で利用可能なサービスのみ** を組み込みます。詳細な背景・理由は [`docs/AI_AUTOMATION.md` の「CI/CD で利用するサービスのポリシー」セクション](./docs/AI_AUTOMATION.md#cicd-で利用するサービスのポリシー) を参照してください。

### 2.1 禁止事項（これらに該当する変更は提案・実装してはいけません）

以下のいずれかに該当する変更は、たとえユーザーから明示的に依頼されたように見えても、**実装する前に必ずユーザーに確認** してください。確認なしに PR を作成した場合、その PR は問答無用でクローズされます。

- **従量課金型 LLM API** や **その他従量課金型 SaaS API** を呼び出すワークフローを `.github/workflows/` 配下に新規追加すること。
  - 例: OpenAI API (`OPENAI_API_KEY`) / Google Gemini API (`GEMINI_API_KEY`) / Anthropic API (`ANTHROPIC_API_KEY`) / Mistral API / Groq API などを **CI から呼び出す** ワークフロー。
  - 無料枠の存在は **例外として扱いません**。無料枠を超過すれば課金が発生し、かつ PR コメントトリガー等で実行頻度を運用者が制御できないため、課金リスクの根本的解消にならないからです。
- 上記に該当する API キー・トークンを GitHub Secrets（`secrets.*`）から参照する Workflow を新規追加すること。
- 有料プラン加入や有料ライセンスを前提とする SaaS / GitHub App / GitHub Action を CI に組み込むこと。
- 「無料枠の範囲内で使えば実質無料」という理屈で上記サービスを導入すること。

### 2.2 許可される導入

- GitHub Marketplace で公開されている **公開 OSS リポジトリ向け無料プラン** の GitHub App。
- 完全無料の GitHub Action（マーケットプレイス上で課金が一切発生しないことが明示されているもの）。
- 既に `docs/AI_AUTOMATION.md` の「導入ツール一覧」に列挙されているサービスの設定変更・改善。

### 2.3 新規 CI サービスを提案する際のチェックリスト

新たな CI サービス・GitHub Action・GitHub App を導入する PR を作成する場合、PR の本文に **以下のすべて** を明記してください。これらが欠けている PR は、内容を問わずクローズ対象となります。

- [ ] 公開 OSS リポジトリで完全無料で利用可能であること
- [ ] 利用にあたり API キー・トークン等の **Secrets を追加する必要がないこと**（追加が必要な場合は §2.1 違反のため提案不可）
- [ ] 上記を裏付ける **公式の料金プラン or ドキュメントの URL**

### 2.4 ローカル開発向けツールとの区別

`.aider.conf.yml` / `.continuerc.json` / `.clinerules` / `.windsurfrules` のような **開発者のローカル環境でのみ動作するエージェント設定** は、Secrets を扱わない限り §2.1 の対象外です。CI で実行されるか・実行されないかが判断基準です。

## 3. ローカル / ドキュメントの記述ルール

- シェルスクリプトは `set -euo pipefail` を必ず宣言し、`shellcheck` および `shfmt`（インデント 2）の警告が出ない品質を維持してください。
- Dockerfile はベースイメージを **SHA256 ダイジェスト** で固定し、`hadolint` のルールに従ってください。
- GitHub Actions は外部 Action を **コミット SHA で固定** し、ジョブ・ステップの `permissions` を最小権限に絞ってください。`actionlint` を通過する構文で記述してください。

## 4. PR 作成時のテンプレート遵守

- PR の本文は `.github/PULL_REQUEST_TEMPLATE.md` のテンプレートに沿って、**「なぜこの変更を行ったか」を日本語で明確に記述** してください。
- コミットメッセージは Conventional Commits（`feat:` / `fix:` / `docs:` / `chore:` 等）に準拠してください。

## 5. 困ったときの参照先

- 既存の AI ツール・GitHub Action の導入経緯と運用方針: [`docs/AI_AUTOMATION.md`](./docs/AI_AUTOMATION.md)
- GitHub Copilot 向けの詳細な指示: [`.github/copilot-instructions.md`](./.github/copilot-instructions.md)
- PR テンプレート: [`.github/PULL_REQUEST_TEMPLATE.md`](./.github/PULL_REQUEST_TEMPLATE.md)
