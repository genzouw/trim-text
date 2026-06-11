# AGENTS.md

このファイルは、本リポジトリで作業する **AI コーディングエージェント** （GitHub Copilot Agent、Jules、Codex、Claude Code、Aider、Cursor、Cline、Windsurf、Continue.dev、Sweep、PR-Agent、Devin など）に向けた指示書です。人間の貢献者にもそのまま適用されます。

## 大原則: CI/CD では「無料サービスのみ」を利用する

本リポジトリの CI/CD（GitHub Actions を含むすべての自動化ワークフロー）では、**公開 OSS リポジトリ向けに無料で利用可能なサービスのみ** を利用します。詳細なポリシーは [`docs/AI_AUTOMATION.md` の「CI/CD で利用するサービスのポリシー」](docs/AI_AUTOMATION.md#cicd-で利用するサービスのポリシー) を必ず参照してください。

エージェントが新規ワークフローや CI 連携サービスを追加・提案する際は、以下を **絶対に守ってください**。

### 禁止事項（PR を作成しないこと）

以下に該当する PR は **作成しないでください**。作成しても自動的にクローズされます。

- **従量課金型 API キーを要求するワークフロー / Action の新規追加**
  - 例: `GEMINI_API_KEY`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `CLAUDE_API_KEY`, `MISTRAL_API_KEY`, `COHERE_API_KEY`, `GROQ_API_KEY`, `DEEPSEEK_API_KEY`, `PERPLEXITY_API_KEY` などを GitHub Secrets に登録して CI から呼び出すもの。
  - LLM プロバイダの API キー全般。無料枠が存在しても、超過すると課金が発生するため対象です。
- **有料プラン / 有料ライセンスを必要とするサービスの CI 組み込み**
  - 無料トライアル中のサービスや、シート課金が発生するサービスも禁止です。
- **公開 OSS でも有料となる SaaS の追加**
  - 例: 公開リポジトリでも Pro プラン以上を要求するもの。
- **「無料枠内に収まる前提」での従量課金 API 利用**
  - レート制限・利用量制限により破綻するため禁止です。

### 許可されているもの

- GitHub Marketplace の **公開 OSS リポジトリ向け無料プラン**
- GitHub App の **公開 OSS リポジトリ向け無料利用枠**
- 完全無料の GitHub Action / Workflow
- ローカル LLM（Ollama 等）を用いる、Secrets 不要の自動化

### AI コードレビューを追加したい場合

本リポジトリでは、以下の **完全無料の GitHub App** が既に設定されています。重複する PR を作らないでください。

- [CodeRabbit](https://github.com/apps/coderabbitai) — `.coderabbit.yaml`
- [PR-Agent (Qodo Merge)](https://github.com/apps/qodo-merge) — `.pr_agent.toml`
- [Gemini Code Assist](https://github.com/apps/gemini-code-assist) — GitHub App（API キー不要）

`truongnh1992/gemini-ai-code-reviewer` のような **GEMINI_API_KEY を必要とする Action ベースの実装は導入禁止** です（[PR #68](https://github.com/genzouw/trim-text/pull/68) はこの理由でクローズされました）。

### LLM 機能をローカルで利用する場合

LLM の API キー（`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN` 等）は、**ローカル環境の環境変数としてのみ** 利用してください。**GitHub Secrets への登録および CI への組み込みは禁止** です。

## 例外申請

上記ポリシーから外れる導入を検討する場合は、**PR を作成する前に Issue で提案** し、リポジトリオーナー（@genzouw）の明示的な承認を得てください。承認のない有料サービス導入 PR はクローズされます。

## エージェント向けチェックリスト

新規 Workflow / CI サービス追加 PR を作成する前に、以下をすべて満たしているか確認してください。

- [ ] 追加するサービスは **公開 OSS リポジトリで完全無料** で利用できる
- [ ] GitHub Secrets に **LLM プロバイダの API キー** を追加していない
- [ ] PR 説明文に「公開 OSS リポジトリで無料利用可能であること」「課金が発生しないこと」を明記し、**公式の料金プラン / ドキュメントの URL** を提示している
- [ ] 既存の AI ツール（CodeRabbit, PR-Agent, Gemini Code Assist 等）と機能が重複していない

## 参考

- [docs/AI_AUTOMATION.md](docs/AI_AUTOMATION.md) — 導入済み AI ツール一覧と CI/CD ポリシーの全文
- [README.md](README.md) — プロジェクト概要
