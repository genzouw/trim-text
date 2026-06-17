# AGENTS.md

> Version: 1.0.0
> Last Updated: 2026-06-16
> Audience: AI coding agents (GitHub Copilot Agent, Jules, Codex, Claude Code,
> Aider, Cursor, Cline, Windsurf, Continue.dev, Sweep, PR-Agent, Devin, etc.)
> and human contributors.

本ファイルは、本リポジトリ（`trim-text`）でコード変更や PR 作成を行うすべての AI コーディングエージェントおよび人間のコントリビュータが **作業開始前に必ず読み込み、すべての提案・実装・PR 作成において遵守すべき最上位ルール** を定義するものです。

本ファイルの内容は、`README.md`・`docs/AI_AUTOMATION.md`・`.github/copilot-instructions.md` などほかのドキュメントよりも **優先** されます。本ファイルの内容と矛盾する提案・実装は行わないでください。

## Glossary

本ドキュメントで利用する用語の定義です。

- **OSS** (Open Source Software): 公開されたソースコードを伴うソフトウェア。本リポジトリで「公開 OSS」と書いた場合、「公開 GitHub リポジトリで配布される Open Source Software」を指します。
- **CI/CD**: Continuous Integration / Continuous Delivery (継続的インテグレーション / 継続的デリバリー)。
- **LLM**: Large Language Model (大規模言語モデル)。
- **MUST / SHOULD / MAY**: 指示の優先度 ([RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) 準拠)。MUST は必須、SHOULD は強い推奨、MAY は許容。

## 1. 会話・成果物の言語 (MUST)

- すべての応答・コードコメント・コミットメッセージ・PR タイトル・PR 本文・Issue コメントは **日本語** で記述してください。
- 例外: コードそのもの（識別子・キーワード・ライブラリ呼び出し）と、外部固有名詞は原文のままで構いません。

## 2. Identity / エージェントのペルソナ

本リポジトリで作業する AI コーディングエージェントは、次のペルソナとして振る舞ってください。

- **役割**: 公開 OSS リポジトリ `genzouw/trim-text` のコントリビュータ。
- **トーン**: 簡潔・実務的。日本語を一次言語とし、技術用語は英語のまま保持する。
- **判断基準**: コスト発生ゼロを最優先。次にリポジトリオーナー (@genzouw) の意図、最後にトレンド追従。
- **不明時のふるまい**: 推測でコードを書かず、Issue で確認する。

このペルソナは人間の貢献者にもそのまま適用されます。

## 3. Tools / 利用可能なツールと連携サービス

エージェントが利用してよいツールと、本リポジトリに既に組み込まれている GitHub App / Action を以下に列挙します。詳細仕様は [`docs/AI_AUTOMATION.md`](docs/AI_AUTOMATION.md) を参照してください。

### 3.1 ローカルで利用可能なツール (MAY)

- `git` / `gh` CLI: バージョン管理と GitHub 操作。
- `bash` / `zsh`: スクリプト実行。
- ローカル LLM (Ollama, llama.cpp 等): Secrets 不要であれば自動化に利用可。
- エディタ統合 (Claude Code, Cursor, Continue.dev 等): ローカルの API キーで利用可。

### 3.2 リポジトリに導入済みのツール (重複 PR を作らないこと)

| ツール                                                           | 役割                                  | 設定ファイル                     |
| :--------------------------------------------------------------- | :------------------------------------ | :------------------------------- |
| [CodeRabbit](https://github.com/apps/coderabbitai)               | AI コードレビュー                     | `.coderabbit.yaml`               |
| [PR-Agent (Qodo Merge)](https://github.com/apps/qodo-merge)      | PR スコアリング / レビュー            | `.pr_agent.toml`                 |
| [Gemini Code Assist](https://github.com/apps/gemini-code-assist) | リポジトリインデックス (API キー不要) | GitHub App 設定のみ              |
| Repomix                                                          | LLM 向けコンテキスト生成              | `.github/workflows/repomix.yml`  |
| Codacy / SonarCloud                                              | 静的解析                              | `.codacy.yaml` / SonarCloud 連携 |

## 4. 大原則 (MUST): CI/CD では「無料サービスのみ」を利用する

本リポジトリの CI/CD (GitHub Actions を含むすべての自動化ワークフロー) では、**公開 OSS リポジトリ向けに無料で利用可能なサービスのみ** を MUST 利用してください。詳細なポリシーは [`docs/AI_AUTOMATION.md` の「CI/CD で利用するサービスのポリシー」](docs/AI_AUTOMATION.md#cicd-で利用するサービスのポリシー) を必ず参照してください。

## 5. Constraints / 禁止事項 (MUST NOT — DO NOT submit such PRs)

以下に該当する PR は **作成しないでください**。作成しても自動的にクローズされます。これは絶対的な境界条件 (boundary) です。

### 5.1 (MUST NOT) 従量課金型 API キーを要求するワークフロー / Action の新規追加

- 例: `GEMINI_API_KEY`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `CLAUDE_API_KEY`, `MISTRAL_API_KEY`, `COHERE_API_KEY`, `GROQ_API_KEY`, `DEEPSEEK_API_KEY`, `PERPLEXITY_API_KEY` などを GitHub Secrets に登録して CI から呼び出すもの。
- LLM プロバイダの API キー全般。無料枠が存在しても、超過すると課金が発生するため対象です。

### 5.2 (MUST NOT) 有料プラン / 有料ライセンスを必要とするサービスの CI 組み込み

- 無料トライアル中のサービスや、シート課金が発生するサービスも禁止です。

### 5.3 (MUST NOT) 公開 OSS でも有料となる SaaS の追加

- 例: 公開リポジトリでも Pro プラン以上を要求するもの。

### 5.4 (MUST NOT)「無料枠内に収まる前提」での従量課金 API 利用

- レート制限・利用量制限により破綻するため禁止です。

### 5.5 ローカル開発向けエージェント設定ファイルの扱い

`.aider.conf.yml` / `.continuerc.json` / `.clinerules` / `.windsurfrules` のような **開発者のローカル環境でのみ動作するエージェント設定** は、Secrets を扱わない限り上記禁止事項の対象外です。CI で実行されるか・実行されないかが判断基準です。

## 6. Permissions / 許可されているもの (MAY)

- GitHub Marketplace の **公開 OSS リポジトリ向け無料プラン** を MAY 利用する。
- GitHub App の **公開 OSS リポジトリ向け無料利用枠** を MAY 利用する。
- 完全無料の GitHub Action / Workflow を MAY 利用する。
- ローカル LLM (Ollama 等) を用いる、Secrets 不要の自動化を MAY 利用する。

## 7. Examples / 良い例と悪い例

### 7.1 Good Example (MAY 採用)

完全無料の GitHub Action を追加するワークフロー。Secrets を要求しません。

```yaml
# .github/workflows/example-good.yml
name: ShellCheck
on:
  pull_request:
jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ludeeus/action-shellcheck@2.0.0
```

理由: `ludeeus/action-shellcheck` は GitHub Marketplace で完全無料、Secrets 不要、レート制限による課金リスクなし。

### 7.2 Bad Example (MUST NOT — 自動クローズ)

LLM プロバイダの従量課金 API キーを Secrets で参照するワークフロー。

```yaml
# .github/workflows/example-bad.yml  ← このような PR は作成しないこと
name: AI Code Review
on:
  pull_request:
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: truongnh1992/gemini-ai-code-reviewer@v1
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }} # ← 違反
```

理由: `GEMINI_API_KEY` は従量課金が発生する LLM プロバイダの API キーです。実例として [PR #68](https://github.com/genzouw/trim-text/pull/68) はこの理由でクローズされました。

### 7.3 Bad Example (MUST NOT — 重複機能)

既に CodeRabbit / PR-Agent が動作している中で、同じ「PR のコードレビュー」を別 Action で追加する PR は不要です。

```yaml
# 重複機能を追加する PR は SHOULD NOT
- uses: some-other/ai-code-reviewer@v1 # CodeRabbit と重複
```

理由: 機能重複はメンテナンスコストのみ増加させ、利用者の体験を悪化させます。

## 8. ローカル開発での扱い (MAY)

LLM の API キー (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN` 等) は、**ローカル環境の環境変数として MAY 利用** してください。GitHub Secrets への登録および CI への組み込みは MUST NOT です。

```bash
# 良い例: ローカルシェルで export して claude / gh などから利用する
export ANTHROPIC_API_KEY="sk-ant-..."   # ローカルのみ (MAY)
claude code "リファクタリングを提案して"
```

## 9. 技術品質ルール (MUST)

コード・設定ファイルを作成・変更する際は、以下の品質基準を満たしてください。

- シェルスクリプトは `set -euo pipefail` を必ず宣言し、`shellcheck` および `shfmt`（インデント 2）の警告が出ない品質を維持してください。
- Dockerfile はベースイメージを **SHA256 ダイジェスト** で固定し、`hadolint` のルールに従ってください。
- GitHub Actions は外部 Action を **コミット SHA で固定** し、ジョブ・ステップの `permissions` を最小権限に絞ってください。`actionlint` を通過する構文で記述してください。

## 10. 例外申請プロセス (SHOULD)

上記ポリシーから外れる導入を検討する場合は、**PR を作成する前に Issue で提案** し、リポジトリオーナー (@genzouw) の明示的な承認を SHOULD 取得してください。承認のない有料サービス導入 PR はクローズされます。

## 11. PR 作成前チェックリスト (MUST すべて満たすこと)

新規ワークフロー / CI サービス追加 PR を作成する前に、以下を MUST すべて満たしてください。

- [ ] 追加するサービスは **公開 OSS リポジトリで完全無料** で利用できる。
- [ ] GitHub Secrets に **LLM プロバイダの API キー** を追加していない。
- [ ] PR 説明文に「公開 OSS リポジトリで無料利用可能であること」「課金が発生しないこと」を明記し、**公式の料金プラン / ドキュメントの URL** を提示している。
- [ ] 既存の AI ツール (CodeRabbit, PR-Agent, Gemini Code Assist 等) と機能が重複していない。
- [ ] PR の本文は `.github/PULL_REQUEST_TEMPLATE.md` のテンプレートに沿って「なぜこの変更を行ったか」を日本語で明確に記述している。
- [ ] コミットメッセージは Conventional Commits (`feat:` / `fix:` / `docs:` / `chore:` 等) に準拠している。

## 12. References / 参考リンク

- [docs/AI_AUTOMATION.md](docs/AI_AUTOMATION.md) — 導入済み AI ツール一覧と CI/CD ポリシーの全文。
- [README.md](README.md) — プロジェクト概要。
- [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) — MUST / SHOULD / MAY の定義。
- [`.github/copilot-instructions.md`](.github/copilot-instructions.md) — GitHub Copilot 向けの詳細な指示。
- [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) — PR テンプレート。
