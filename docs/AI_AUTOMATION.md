# AI 開発フロー自動化ツールの導入ガイドライン

本リポジトリでは、ソースコード（Docker イメージ・CLI ツール）の公開だけでなく、最新の生成 AI を活用した開発フローの自動化と最適化を試験的に導入し、プロトタイプとして検証する目的を持っています。
公開 GitHub リポジトリで無料で利用可能なツール・サービスを積極的に導入しています。

## CI/CD で利用するサービスのポリシー

本リポジトリの CI/CD（GitHub Actions を含むすべての自動化ワークフロー）では、**公開 OSS リポジトリ向けに無料で利用可能なサービスのみ**を利用します。AI エージェントを含む自動化ツールが新たなサービスを CI に組み込む際は、以下のルールを必ず守ってください。

- **禁止**: 無料枠を超えると課金が発生する従量課金型 API（例: 各種 LLM プロバイダの API キーを要求するもの）を、CI のワークフローへ組み込むこと。
- **禁止**: 利用に有料プランへの加入や有料ライセンスを必要とするサービスを CI に組み込むこと。
- **禁止**: 上記に該当する API キーやトークンを `Secrets` として要求する Workflow を新規追加すること。
- **許可**: GitHub Marketplace の公開 OSS リポジトリ向け無料プラン、GitHub App の公開 OSS リポジトリ向け無料利用枠、および完全無料の Action のみ。
- **必須**: PR で新たな CI サービスを追加する場合は、PR 説明文に「公開 OSS リポジトリで無料利用可能であること」「課金が発生しないこと」を明示し、それを確認できる公式の料金プランやドキュメントの URL を提示すること。
- **例外**: 上記ポリシーから外れる導入を検討する場合は、PR を作成する前に Issue で提案し、リポジトリオーナーの明示的な承認を得てください。承認のない有料サービス導入 PR はクローズされます。

以下に、現在導入されている主要な AI ツールとその目的、および機能させるために必要な手動の事前設定手順を記載します。

## 導入ツール一覧

### 1. PR-Agent (Qodo)

- **目的**: プルリクエスト作成時に、AI がコードの変更内容を自動でレビューし、改善提案、変更概要の生成、セキュリティチェックなどを行います。
- **設定ファイル**: `.pr_agent.toml`
- **特徴**: リブランディングされた Qodo の機能を活用し、変更のスコアリング(`require_score_review = true`) やラベル提案などを通じて、自動マージ判定やレビュアーの負担軽減に貢献します。
- **事前設定**:
  1. GitHub App として [PR-Agent](https://github.com/apps/qodo-merge) (または Qodo Merge) をリポジトリにインストールしてください（公開リポジトリは無料）。
  2. インストール後、リポジトリへのアクセス権限（Read & Write）を付与してください。

### 2. CodeRabbit

- **目的**: AI ベースの bot レビュアーとして、インサイトに富んだコードレビューを実行します。セキュリティの脆弱性やコーディング規約の違反などを検出します。
- **設定ファイル**: `.coderabbit.yaml`
- **特徴**: プロジェクト全体への影響や、ドキュメント・テストコードとの整合性を厳格にチェックします。
- **事前設定**:
  1. GitHub App として [CodeRabbit](https://github.com/apps/coderabbitai) をインストールしてください（公開 OSS リポジトリは無料）。
  2. プロジェクトのダッシュボードからリポジトリを有効化し、適切な権限を付与してください。

### 3. Gemini AI Code Reviewer

- **目的**: Google の Gemini AI モデルを使用して、Pull Request のコードレビューを自動的に実行します。
- **設定ファイル**: なし（GitHub App として動作するため、ワークフローファイルは不要です）
- **特徴**: GitHub App として動作し、最新の Gemini モデルを利用したコードレビューを提供します。公開リポジトリ向けに無料で利用可能です。
- **事前設定**:
  1. GitHub App として [Gemini Code Assist](https://github.com/apps/gemini-code-assist) をリポジトリにインストールしてください（公開リポジトリは無料）。
  2. インストール後、リポジトリへのアクセス権限（Read & Write）を付与してください。

### 4. Sweep AI

- **目的**: Issue の内容に基づき、AI がリポジトリ全体をコンテキストとして読み込み、自動でコードの修正と Pull Request の作成を行う自律型エージェントです。
- **設定ファイル**: `sweep.yaml`
- **特徴**: 日本語でのやり取り、プロジェクト固有の Lint（shellcheck, shfmt, hadolint）の遵守、セキュリティ観点でのコード修正を自動で行います。
- **事前設定**:
  1. GitHub App として [Sweep](https://github.com/apps/sweep-ai) をインストールしてください（公開リポジトリは無料）。
  2. リポジトリへのアクセス権限を付与することで、Issue に `sweep:` などのトリガーをつけるか Sweep が自動でタスクをピックアップして動作し始めます。

### 5. Bloop AI (AIコード検索エンジン)

- **目的**: リポジトリ全体をインデックス化し、自然言語による検索やコードベースに関する質問を可能にします。
- **設定ファイル**: `.bloopignore`
- **特徴**: 開発者がコードの目的や構造を簡単に把握できるようになり、新規参画時のオンボーディングなどをサポートします。
- **事前設定**:
  1. GitHub App として [bloop](https://github.com/apps/bloop-ai) をインストールしてください（公開リポジトリは無料）。
  2. インストール後、リポジトリへのアクセス権限を付与してください。

### 6. Repomix (LLM 向けリポジトリコンテキスト生成) とサーチサービス連携

- **目的**: AI アシスタントや LLM、AI 検索エンジンに対して、リポジトリ全体の構造や主要なコードを読み込ませるためのコンテキストファイル（XML、および `llms.txt` 規格の Markdown）を自動生成します。
- **設定ファイル**: `.github/workflows/repomix.yml`
- **特徴**: リポジトリの最新状態を常に Artifact として提供するだけでなく、GitHub Pages を通じて `llms.txt` および `llms-full.txt` を公開することで、Perplexity や ChatGPT Web Browsing などの AI エージェントからのアクセスを容易にします。また、`repomix.config.json` により、LLM向けにプロジェクト独自のカスタムインストラクションを付与しています。
- **事前設定**:
  1. リポジトリの `Settings` > `Pages` から、**Build and deployment** の Source を **GitHub Actions** に設定し、GitHub Pages を有効化してください。

### 7. OSSF Scorecard (サプライチェーンセキュリティ・品質評価)

- **目的**: 業界標準の品質・セキュリティ評価ツールを利用して、公開リポジトリの継続的なセキュリティスキャンと品質チェック（トークン権限、ブランチ保護、テストの有無など）を行います。
- **設定ファイル**: `.github/workflows/scorecard.yml`
- **特徴**: GitHub の Code Scanning アラートと連携し、セキュリティベストプラクティスへの準拠状況を自動的に評価・可視化します。
- **事前設定**:
  1. 特に追加の App インストールは不要ですが、GitHub の Code Scanning の機能を有効化していることを確認してください。

### 8. DeepSource (AIを活用した静的解析と自動修正)

- **目的**: AI による高度な静的解析と Autofix（自動修正）機能を利用して、シェルスクリプトや Dockerfile の品質向上とセキュリティ強化を図ります。
- **設定ファイル**: `.deepsource.toml`
- **特徴**: 既存の CI/CD を補完する形で、コードのアンチパターンやパフォーマンスの問題を自動的に検出し、修正案を提案します。
- **事前設定**:
  1. GitHub App として [DeepSource](https://github.com/apps/deepsource) をインストールしてください（公開 OSS リポジトリは無料）。
  2. プロジェクトのダッシュボードからリポジトリを連携し、初期設定を行ってください。

### 9. Mend Renovate (高度な依存関係管理)

- **目的**: Dependabot よりさらに高度な依存関係の自動更新・グルーピング・マージ制御を行います。
- **設定ファイル**: `renovate.json`
- **特徴**: パッチ・マイナーバージョンの自動マージなど、柔軟なルール設定によりメンテナンスコストを削減します。
- **事前設定**:
  1. GitHub App として [Mend Renovate](https://github.com/apps/renovate) をインストールしてください（公開リポジトリは無料）。

### 10. Release Please (リリース自動化)

- **目的**: Conventional Commits に基づいてリリース PR を自動生成し、セマンティックバージョニングによるタグ付けと CHANGELOG 生成を行います。
- **設定ファイル**: `.github/workflows/release-please.yml`
- **特徴**: リリースの運用を完全に自動化・標準化します。
- **事前設定**:
  1. コミットメッセージに Conventional Commits の形式（`feat:`, `fix:`, `chore:` 等）を厳密に守るようにしてください。

### 11. Devcontainer (開発環境のコード化)

- **目的**: 開発環境を Docker コンテナとして定義し、チーム全体や AI エージェントが同一の環境で開発・テストを行えるようにします。
- **設定ファイル**: `.devcontainer/devcontainer.json`
- **特徴**: GitHub Codespaces、Cursor、Windsurf、Roo Code (Cline) などのモダンな IDE や AI アシスタントと連携し、すぐにテストやLintが実行可能なコンテキストを提供します。
- **事前設定**:
  1. 特に追加の設定は不要ですが、Devcontainer に対応した IDE（VS Code, Cursor など）で「Reopen in Container」を選択して起動してください。

### 12. Continue.dev (AI コーディングアシスタント)

- **目的**: オープンソースの AI アシスタントである Continue を活用し、リポジトリ固有のコンテキストを考慮したコード生成や質問対応を行います。
- **設定ファイル**: `.continue/config.json`
- **特徴**: 開発者のエディタ内で、ローカルおよびクラウドのLLMを用いてコードの補完やチャットベースのサポートを提供します。
- **事前設定**:
  1. VS Code や Cursor などの拡張機能として [Continue](https://continue.dev/) をインストールしてください。
  2. リポジトリの `.continue/config.json` が自動的に読み込まれ、プロジェクト固有のルール（`sweep.yaml` など）が適用されます。

### 13. StepSecurity Harden-Runner (CI/CD サプライチェーンセキュリティ)

- **目的**: GitHub Actions 実行時の予期せぬ外部通信を監視・遮断し、サプライチェーン攻撃（依存関係の改ざんによる情報漏洩など）を防止します。
- **設定ファイル**: 各種ワークフロー（例: `.github/workflows/docker-build.yml` など）
- **特徴**: 2024年以降の CI/CD セキュリティのトレンドである egress 通信の制限を無料で実現します。
- **事前設定**:
  1. ワークフローに追加された `step-security/harden-runner` アクションにより自動的に適用されます。

### 14. LLM SEO / GEO (AI検索エンジン最適化)

- **目的**: Perplexity、ChatGPT Search、Google AI Overviews などの AI 検索エンジンがリポジトリのコンテキストを正しく理解し、参照できるようにします。
- **設定ファイル**: `.github/workflows/repomix-pages.yml`
- **特徴**: `llms.txt` だけでなく、`robots.txt` や `sitemap.xml` を自動生成し、AI ボットのクローラビリティを向上させます。また、IndexNowのPing機能を利用し、更新時にリアルタイムで検索エンジンに通知を送信します。

### 15. Aider (AI ペアプログラミング)

- **目的**: ターミナル上で動作するAIペアプログラミングツールとして、コードの変更、リファクタリング、バグ修正を対話的に行います。
- **設定ファイル**: `.aider.conf.yml`
- **特徴**: コマンドラインから直接LLMと連携し、自動コミットや Lint 実行（`auto-lint`）をサポートします。
- **事前設定**:
  1. ローカル環境に Aider をインストールしてください（例: `pip install aider-chat`）。
  2. 利用する LLM の API キー（例: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`）を環境変数に設定して実行してください。

### 16. Roo Code (旧 Cline) / Windsurf (AI IDE アシスタント)

- **目的**: VS Code 拡張機能や専用 IDE を通じて、自律型の AI エージェントとしてタスクを処理します。
- **設定ファイル**: `.clinerules`, `.windsurfrules`
- **特徴**: エディタ内でプロジェクトのコンテキストを理解し、ファイルの作成・編集、コマンドの実行を自律的に行います。
- **事前設定**:
  1. VS Code に [Roo Code](https://marketplace.visualstudio.com/items?itemName=RooCode.roo-cline) 拡張機能をインストールするか、[Windsurf IDE](https://codeium.com/windsurf) をインストールしてください。
  2. 各拡張機能・IDE 内の設定画面から、利用する LLM のプロバイダと API キーを設定してください。

### 17. gitStream (PR Pipeline Automation)

- **目的**: Pull Requestの規模に応じたレビュー時間の見積もり（ETR）算出や、ドキュメントのみの変更の自動承認など、継続的マージ（Continuous Merge）を自動化します。
- **設定ファイル**: `.cm/gitstream.cm`, `.github/workflows/gitstream.yml`
- **特徴**: リポジトリの運用ルールをコードとして定義し（Policy-as-Code）、レビュアーの負担軽減とマージまでのリードタイム短縮を実現します。
- **事前設定**:
  1. GitHub App として [gitStream](https://github.com/apps/gitstream-cm) をリポジトリにインストールしてください（公開リポジトリは無料）。
  2. インストール後、ダッシュボードからリポジトリを連携させてください。

### 18. VulnHawk (AI-powered SAST Scanner)

- **目的**: 従来のパターンマッチングツール（SemgrepやCodeQL）では見逃されがちな、認証バイパスやIDOR、ビジネスロジックのバグをLLM（生成AI）を用いて検出します。
- **設定ファイル**: `.github/workflows/vulnhawk.yml`
- **特徴**: [VulnHawk](https://github.com/momenbasel/vulnhawk) は OpenAI, Claude, Claude Code, またはローカルのOllamaをバックエンドとして活用し、高度なセキュリティスキャンを提供します。本リポジトリでは無料利用枠を考慮し、ローカルやClaude CodeのOAuthトークンなどを活用します。
- **事前設定**:
  1. GitHub Secrets に `CLAUDE_CODE_OAUTH_TOKEN` (Claude Codeを利用する場合)、または `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` 等を設定してください。完全無料で使用する場合はローカル環境のOllama等を利用してください。

### 19. Vibecop (AIコード品質ゲート)

- **目的**: LLMを使用しない決定論的な解析手法により、AIコーディングエージェントが導入しがちなスロップ（無駄なコメントや非効率なコード、セキュリティリスクなど）を検出し、コード品質を維持します。
- **設定ファイル**: `.github/workflows/vibecop.yml`
- **特徴**: [Vibecop](https://github.com/vibe-cop/vibecop) は PR 時の自動レビューに組み込まれ、`ast-grep`ベースの高速な静的解析を実行します。GitHub Actionsとして実行するため、利用は無料です。
- **事前設定**:
  1. 特に追加の設定は不要です。`.github/workflows/vibecop.yml` を通じて GitHub Actions 上で自動実行されます。

### 20. AI-BOM (AI部品表・構成管理スキャナ)

- **目的**: プロジェクト内で使用されているAIモデル、エージェント、API、および関連する脆弱性を自動検出し、ソフトウェア部品表(SBOM)やSARIF形式で可視化します。
- **設定ファイル**: `.github/workflows/ai-bom.yml`
- **特徴**: [AI-BOM](https://github.com/safe-dep/ai-bom) は Trivy や Syft などの従来のSBOMツールでは検出が難しいAI固有のコンポーネントを検出し、GitHub Code Scanning と連携します。公開リポジトリ向けのActionとして無料で利用可能です。
- **事前設定**:
  1. 特に追加の設定は不要ですが、GitHub の Code Scanning 機能が有効になっていることを確認してください。

## CI/CD との連携

Dependabot や Renovate によるマイナー・パッチバージョンの更新などは、自動でマージが行われるように設定されています。これにより、依存関係の更新プロセスが完全に自動化されています。
さらに、pre-commit.ci によるコードの自動フォーマットや、Release Please によるリリースPRの自動作成など、CI/CD における様々な自動化が導入されています。

## プルリクエスト作成時の注意事項

これらの AI ツールは、プルリクエストの概要（Description）やコミットメッセージをコンテキストとして活用します。そのため、PULL_REQUEST_TEMPLATE に沿って、**「なぜこの変更を行ったか」を日本語で明確に記述**するように心がけてください。
