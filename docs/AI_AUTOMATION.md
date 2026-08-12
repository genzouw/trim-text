# AI 開発フロー自動化ツールの導入ガイドライン

本リポジトリでは、ソースコード（Docker イメージ・CLI ツール）を公開しています。それだけでなく、最新の生成 AI を活用した開発フローの自動化と最適化を試験的に導入し、プロトタイプとして検証する目的を持っています。
公開 GitHub リポジトリにおいて、無料で利用可能なツール・サービスを積極的に導入しています。

## CI/CD で利用するサービスのポリシー

本リポジトリの CI/CD（GitHub Actions を含むすべての自動化ワークフロー）では、**公開 OSS リポジトリ向けに無料で利用可能なサービスのみ**を利用します。AI エージェントを含む自動化ツールが新たなサービスを CI に組み込む際は、以下のルールを必ず守ってください。

- **禁止**: 無料枠を超えると課金が発生する従量課金型 API（例: 各種 LLM プロバイダの API キーを要求するもの）を、CI のワークフローへ組み込むこと。
- **禁止**: 利用に有料プランへの加入や有料ライセンスを必要とするサービスを CI に組み込むこと。
- **禁止**: 上記に該当する API キーやトークンを `Secrets` として要求する Workflow を新規追加すること。
- **許可**: GitHub Marketplace の公開 OSS リポジトリ向け無料プラン、GitHub App の公開 OSS リポジトリ向け無料利用枠、および完全無料の Action のみ。
- **必須**: 本リポジトリは GitHub Actions の「Allowed actions」設定を `selected` にしており、GitHub 製・認証済みクリエイター製・および明示的に許可リストへ登録した Action だけが実行できます。許可されていない Action を `uses:` に指定したワークフローは、ジョブが 1 つも起動しないまま `startup_failure` で終了します（PR のチェック一覧にも現れないため、見落としやすい点に注意してください）。サードパーティ製の CLI ツールを利用したい場合は、Action を追加するのではなく、公式リリースのバイナリを SHA256 で検証してから実行するローカルの composite action（`.github/actions/setup-*`）として実装してください。
- **必須**: PR で新たな CI サービスを追加する場合は、PR 説明文に「公開 OSS リポジトリで無料利用可能であること」「課金が発生しないこと」を明示してください。あわせて、それを確認できる公式の料金プランやドキュメントの URL を提示すること。
- **例外**: 上記ポリシーから外れる導入を検討する場合は、PR を作成する前に Issue で提案し、リポジトリオーナーの明示的な承認を得てください。承認のない有料サービス導入 PR はクローズされます。

以下に、現在導入されている主要な自動化ツール（AI ツールおよび従来の CI/CD ツールを含む）とその目的、および機能させるために必要な手動の事前設定手順を記載します。

## 導入ツール一覧

### textlint (技術文書向けルール)

- **目的**: 日本語ドキュメント（Markdownなど）の品質を保つため、技術文書向けのルールセット（`textlint-rule-preset-ja-technical-writing`）で文章の校正を自動で行います。
- **設定ファイル**: `.textlintrc.json`, `.github/workflows/textlint.yml`
- **特徴**: `textlint-rule-preset-ja-technical-writing` を用いてテクニカルライティングの観点から文章の問題を自動検出します。読点の多用や長すぎる文などを対象とし、reviewdog連携によりPRの変更箇所に直接インラインコメントで指摘します。
- **事前設定**:
  1. 特に追加の設定は不要です。GitHub Actions（`textlint.yml`）で自動的に実行されます。

### 1. PR-Agent (Qodo)

- **目的**: プルリクエスト作成時に、AI がコードの変更内容を自動でレビューし、改善提案、変更概要の生成、セキュリティチェックなどを行います。
- **設定ファイル**: `.pr_agent.toml`
- **特徴**: リブランディングされた Qodo の機能を活用しています。変更のスコアリング(`require_score_review = true`) やラベル提案などを通じて、自動マージ判定やレビュアーの負担軽減に貢献します。
- **事前設定**:
  1. GitHub App として [PR-Agent](https://github.com/apps/qodo-merge) (または Qodo Merge) をリポジトリにインストールしてください（公開リポジトリは無料）。
  2. インストール後、リポジトリへのアクセス権限（Read & Write）を付与してください。

### 2. CodeRabbit

- **目的**: AI ベースの bot レビュアーとして、インサイトに富んだコードレビューします。セキュリティの脆弱性やコーディング規約の違反などを検出します。
- **設定ファイル**: `.coderabbit.yaml`
- **特徴**: プロジェクト全体への影響や、ドキュメント・テストコードとの整合性を厳格にチェックします。
- **事前設定**:
  1. GitHub App として [CodeRabbit](https://github.com/apps/coderabbitai) をインストールしてください（公開 OSS リポジトリは無料）。
  2. プロジェクトのダッシュボードからリポジトリを有効化し、適切な権限を付与してください。

### 3. Sweep AI

- **目的**: Issue の内容に基づき、AI がリポジトリ全体をコンテキストとして読み込み、自動でコードを修正し、Pull Request を作成する自律型エージェントです。
- **設定ファイル**: `sweep.yaml`
- **特徴**: 日本語でのやり取り、プロジェクト固有の Lint（shellcheck, shfmt, hadolint）の遵守、セキュリティ観点でのコード修正を自動で行います。
- **注意**: Sweep AI は JetBrains IDE 向けのコーディングアシスタントへ方針転換したため、GitHub App としての提供は終了しています（インストールページ `github.com/apps/sweep-ai` は削除済み）。本リポジトリの `sweep.yaml` は設定として残っていますが、現在は機能しません。詳細は [sweep.dev](https://sweep.dev/) を参照してください。
- **事前設定**:
  1. 新規のインストールはできません。

### 4. Bloop AI (AIコード検索エンジン)

- **目的**: リポジトリ全体をインデックス化し、自然言語による検索やコードベースに関する質問を可能にします。
- **設定ファイル**: `.bloopignore`
- **特徴**: 開発者がコードの目的や構造を簡単に把握できるようになり、新規参画時のオンボーディングなどをサポートします。
- **注意**: Bloop AI は 2026 年 4 月にサービスを終了しました。GitHub App およびホスト型サービスは提供されておらず、本リポジトリの `.bloopignore` は設定として残っていますが、現在は機能しません。ソースコードは [BloopAI](https://github.com/BloopAI) にてコミュニティ管理の OSS として公開されています。
- **事前設定**:
  1. 新規のインストールはできません。

### 5. Repomix (LLM 向けリポジトリコンテキスト生成) とサーチサービス連携

- **目的**: AI アシスタントや LLM、AI 検索エンジンに対して、リポジトリ全体の構造や主要なコードを読み込ませます。そのためのコンテキストファイル（XML、および `llms.txt` 規格の Markdown）を自動生成します。
- **設定ファイル**: `.github/workflows/repomix.yml`
- **特徴**: リポジトリの最新状態を常に Artifact として提供します。さらに、GitHub Pages を通じて `llms.txt` および `llms-full.txt` を公開します。これにより、Perplexity や ChatGPT Web Browsing などの AI エージェントからのアクセスを容易にします。また、`repomix.config.json` により、LLM向けにプロジェクト独自のカスタムインストラクションを付与しています。
- **事前設定**:
  1. リポジトリの `Settings` > `Pages` を開きます。**Build and deployment** の Source を **GitHub Actions** に設定し、GitHub Pages を有効化してください。

### 6. OSSF Scorecard (サプライチェーンセキュリティ・品質評価)

- **目的**: 業界標準の品質・セキュリティ評価ツールを利用して、公開リポジトリの継続的なセキュリティスキャンと品質チェック（トークン権限、ブランチ保護、テストの有無など）を行います。
- **設定ファイル**: `.github/workflows/scorecard.yml`
- **特徴**: GitHub の Code Scanning アラートと連携し、セキュリティベストプラクティスへの準拠状況を自動的に評価・可視化します。
- **事前設定**:
  1. 特に追加の App インストールは不要ですが、GitHub の Code Scanning の機能を有効化していることを確認してください。

### 7. DeepSource (AIを活用した静的解析と自動修正)

- **目的**: AI による高度な静的解析と Autofix（自動修正）機能を利用して、シェルスクリプトや Dockerfile の品質向上とセキュリティ強化を図ります。
- **設定ファイル**: `.deepsource.toml`
- **特徴**: 既存の CI/CD を補完する形で、コードのアンチパターンやパフォーマンスの問題を自動的に検出し、修正案を提案します。
- **事前設定**:
  1. GitHub App として [DeepSource](https://github.com/apps/deepsource-io) をインストールしてください（公開 OSS リポジトリは無料）。
  2. プロジェクトのダッシュボードからリポジトリを連携し、初期設定してください。

### 8. Mend Renovate (高度な依存関係管理)

- **目的**: Dependabot よりさらに高度な依存関係の自動更新・グルーピング・マージ制御をします。
- **設定ファイル**: `renovate.json`
- **特徴**: パッチ・マイナーバージョンの自動マージなど、柔軟なルール設定によりメンテナンスコストを削減します。
- **事前設定**:
  1. GitHub App として [Mend Renovate](https://github.com/apps/renovate) をインストールしてください（公開リポジトリは無料）。

### 9. Release Please (リリース自動化)

- **目的**: Conventional Commits に基づいてリリース PR を自動生成し、セマンティックバージョニングによるタグ付けと CHANGELOG の生成をします。
- **設定ファイル**: `.github/workflows/release-please.yml`
- **特徴**: リリースの運用を完全に自動化・標準化します。
- **事前設定**:
  1. コミットメッセージでは Conventional Commits の形式（`feat:`, `fix:`, `chore:` 等）を厳密に守ってください。

### 10. Devcontainer (開発環境のコード化)

- **目的**: 開発環境を Docker コンテナとして定義し、チーム全体や AI エージェントが同一の環境で開発・テストを行えるようにします。
- **設定ファイル**: `.devcontainer/devcontainer.json`
- **特徴**: GitHub Codespaces、Cursor、Windsurf、Roo Code (Cline) などのモダンな IDE や AI アシスタントと連携します。これにより、すぐにテストやLintが実行可能なコンテキストを提供します。
- **事前設定**:
  1. 特に追加の設定は不要ですが、Devcontainer に対応した IDE（VS Code, Cursor など）で「Reopen in Container」を選択して起動してください。

### 11. Continue.dev (AI コーディングアシスタント)

- **目的**: オープンソースの AI アシスタントである Continue を活用し、リポジトリ固有のコンテキストを考慮したコード生成や質問対応を行います。
- **設定ファイル**: `.continue/config.json`
- **特徴**: 開発者のエディタ内で、ローカルおよびクラウドのLLMを用いてコードの補完やチャットベースのサポートを提供します。
- **事前設定**:
  1. VS Code や Cursor などの拡張機能として [Continue](https://continue.dev/) をインストールしてください。
  2. リポジトリの `.continue/config.json` が自動的に読み込まれ、プロジェクト固有のルール（`sweep.yaml` など）が適用されます。

### 12. StepSecurity Harden-Runner (CI/CD サプライチェーンセキュリティ)

- **目的**: GitHub Actions 実行時の予期せぬ外部通信を監視・遮断し、サプライチェーン攻撃（依存関係の改ざんによる情報漏洩など）を防止します。
- **設定ファイル**: 各種ワークフロー（例: `.github/workflows/docker-build.yml` など）
- **特徴**: 2024年以降の CI/CD セキュリティのトレンドである egress 通信の制限を無料で実現します。
- **事前設定**:
  1. ワークフローに追加された `step-security/harden-runner` アクションにより自動的に適用されます。

### 13. LLM SEO / GEO (AI検索エンジン最適化)

- **目的**: Perplexity、ChatGPT Search、Google AI Overviews などの AI 検索エンジンがリポジトリのコンテキストを正しく理解し、参照できるようにします。
- **設定ファイル**: `.github/workflows/repomix-pages.yml`
- **特徴**: `llms.txt` だけでなく、`robots.txt` や `sitemap.xml` を自動生成し、AI ボットのクローラビリティを向上させます。また、IndexNowのPing機能を利用し、更新時にリアルタイムで検索エンジンに通知を送信します。

### 14. Aider (AI ペアプログラミング)

- **目的**: ターミナル上で動作するAIペアプログラミングツールとして、コードの変更、リファクタリング、バグ修正を対話的に行います。
- **設定ファイル**: `.aider.conf.yml`
- **特徴**: コマンドラインから直接LLMと連携し、自動コミットや Lint 実行（`auto-lint`）をサポートします。
- **事前設定**:
  1. ローカル環境に Aider をインストールしてください（例: `pip install aider-chat`）。
  2. 利用する LLM の API キー（例: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`）を環境変数に設定して実行してください。

### 15. Roo Code (旧 Cline) / Windsurf (AI IDE アシスタント)

- **目的**: VS Code 拡張機能や専用 IDE を通じて、自律型の AI エージェントとしてタスクを処理します。
- **設定ファイル**: `.clinerules`, `.windsurfrules`
- **特徴**: エディタ内でプロジェクトのコンテキストを理解し、ファイルの作成・編集、コマンドの実行を自律的に行います。
- **事前設定**:
  1. VS Code に [Roo Code](https://marketplace.visualstudio.com/items?itemName=RooVeterinaryInc.roo-cline) 拡張機能をインストールするか、[Windsurf IDE（現 Devin Desktop）](https://devin.ai/desktop) をインストールしてください。
  2. 各拡張機能・IDE 内の設定画面から、利用する LLM のプロバイダと API キーを設定してください。

### 16. gitStream (PR Pipeline Automation)

- **目的**: Pull Requestの規模に応じたレビュー時間の見積もり（ETR）算出や、ドキュメントのみの変更の自動承認など、継続的マージ（Continuous Merge）を自動化します。
- **設定ファイル**: `.cm/gitstream.cm`, `.github/workflows/gitstream.yml`
- **特徴**: リポジトリの運用ルールをコードとして定義し（Policy-as-Code）、レビュアーの負担軽減とマージまでのリードタイム短縮を実現します。
- **事前設定**:
  1. GitHub App として [gitStream](https://github.com/apps/gitstream-cm) をリポジトリにインストールしてください（公開リポジトリは無料）。
  2. インストール後、ダッシュボードからリポジトリを連携させてください。

### 17. Lychee (Link Checker)

- **目的**: ドキュメント（Markdown など）内のリンク切れを自動的に検出し、メンテナンス漏れを防ぎます。
- **設定ファイル**: `.github/workflows/lychee.yml`
- **特徴**: AI を使用しない従来の静的リンクチェッカーです。高速でオープンソースであり、公開リポジトリ向けの Action として無料で利用可能です。`cron` スケジュール実行により、定期的に外部リンクの生存確認も行います。
- **事前設定**:
  1. 特に追加の設定は不要です。GitHub Actions 上で自動的に実行されます。

### 18. textlint (日本語の文章校正)

- **目的**: 日本語のドキュメント（Markdown など）に対して、JTF 日本語標準スタイルガイドなどの技術文書向けルールに基づいた校正を自動で行います。
- **設定ファイル**: `.textlintrc.json`, `.github/workflows/textlint.yml`
- **特徴**: npm から実行可能な静的解析ツールであり、レビューコメントを自動化することで日本語の品質・一貫性を保ちます。公開リポジトリ向けの Action として無料で利用可能です。
- **事前設定**:
  1. 特に追加の設定は不要です。GitHub Actions 上で自動的に実行されます。

## CI/CD との連携

Dependabot や Renovate によるマイナー・パッチバージョンの更新などは、自動でマージが行われるように設定されています。これにより、依存関係の更新プロセスが完全に自動化されています。
さらに、pre-commit.ci によるコードの自動フォーマットや、Release Please によるリリースPRの自動作成など、CI/CD における様々な自動化が導入されています。

## プルリクエスト作成時の注意事項

これらの AI ツールは、プルリクエストの概要（Description）やコミットメッセージをコンテキストとして活用します。そのため、PULL_REQUEST_TEMPLATE を踏まえ、**「なぜこの変更をしたか」を日本語で明確に記述**してください。

### 19. textlint (日本語の文章校正ツール)

- **目的**: Markdown などのドキュメントを対象に、日本語の技術文書向けのルール (JTF 日本語標準スタイルガイドなど) に従った静的な文章校正をします。
- **設定ファイル**: `.textlintrc.json`, `.github/workflows/textlint.yml`
- **特徴**: 表記ゆれや句読点の誤り、長すぎる文などを自動検出し、読みやすく統一感のある日本語ドキュメントの維持に貢献します。
- **事前設定**:
  1. 特に追加の設定は不要です。GitHub Actions 上で自動的に実行されます。

### 20. Semantic Pull Request (Pull Request タイトル検証)

- **目的**: Pull Request のタイトルが [Conventional Commits](https://www.conventionalcommits.org/) の形式になっているかをチェックし、Release Please による自動リリース運用を安定させます。
- **設定ファイル**: `.github/workflows/semantic-pull-request.yml`
- **特徴**: `amannn/action-semantic-pull-request` を使用して PR タイトルを検証します。公開 OSS リポジトリ向けの Action として無料で利用可能です。
- **事前設定**:
  1. 特に追加の設定は不要です。Pull Request 作成時・編集時に GitHub Actions 上で自動的に実行されます。

### 21. Woke (インクルーシブ言語 Linter)

- **目的**: ドキュメントやコード内に非インクルーシブな表現（主従関係を表す旧来の用語や、許可・拒否リストの旧称など）が含まれていないか静的にチェックします。
- **設定ファイル**: `.github/workflows/woke.yml`
- **特徴**: オープンソースのCLIツールである `woke` を利用し、非インクルーシブな言葉を検出した際に `reviewdog` と連携して PR に自動でインラインコメントを投稿します。外部APIキーを必要とせず、完全無料で動作します。
- **事前設定**:
  1. 特に追加の設定は不要です。`.github/workflows/woke.yml` を通じて GitHub Actions 上で自動実行されます（組み込みの `GITHUB_TOKEN` を使用します）。

### 22. GenAI Issue Labeller (AIによるIssue自動ラベリング)

- **目的**: 投稿または更新された GitHub Issue の内容を解析し、最適なラベルを AI (GitHub Models) を使用して自動的に割り当てます。
- **設定ファイル**: `.github/workflows/issue-labeller.yml`
- **特徴**: 外部の有料 LLM API キーを必要とせず、GitHub Models の推論 API と組み込みの `GITHUB_TOKEN` を利用して動作します。これにより、完全無料で Issue の自動分類を実現し、リポジトリ管理者の負担を軽減します。
- **事前設定**:
  1. GitHub Models が組織（Organization）またはエンタープライズレベルで有効化されている必要があります。
  2. 組織のオーナー権限で `Settings` > `Code, planning, and automation` > `Models` > `Development` へアクセスし、GitHub Models を有効化してください。

### 23. AI PR Policy Checker (AIによるポリシー要件チェック)

- **目的**: プロジェクトで要求されている厳格な PR ポリシー（目的、無料の証明、重複確認、セットアップ手順などの6つの必須セクション）が PR タイトルおよび説明文で満たされているか、LLM を用いて自動的にチェックし、不足している場合は PR コメントとしてフィードバックします。
- **設定ファイル**: `.github/workflows/pr-policy-checker.yml`
- **特徴**: `actions/ai-inference` アクションを使用します。推論には GitHub Models の推論 API を利用し、モデルはワークフロー定義（`.github/workflows/pr-policy-checker.yml` の `model:`）を参照します。認証には組み込みの `GITHUB_TOKEN` を利用します。外部の有料 LLM API キーを必要とせず、完全無料でチェックを実現します。
- **事前設定**:
  1. GitHub Models が組織（Organization）またはエンタープライズレベルで有効化されている必要があります。
  2. 組織のオーナー権限で `Settings` > `Code, planning, and automation` > `Models` > `Development` へアクセスし、GitHub Models を有効化してください。

### 24. AI CI Failure Explainer (CI 失敗のAI分析)

- **目的**: CI (Test, Lint, Docker Buildなど) が失敗した際に、エラーログを自動的に解析し、失敗の原因と修正案をPRコメントとして提示します。
- **設定ファイル**: `.github/workflows/ai-ci-failure-explainer.yml`
- **特徴**: `actions/ai-inference` アクションを使用します。推論には GitHub Models の推論 API を利用し、認証には組み込みの `GITHUB_TOKEN` を利用します。外部の有料 LLM API キーを必要とせず、完全無料でチェックを実現します。
- **事前設定**:
  1. GitHub Models が組織（Organization）またはエンタープライズレベルで有効化されている必要があります。
  2. 組織のオーナー権限で `Settings` > `Code, planning, and automation` > `Models` > `Development` へアクセスし、GitHub Models を有効化してください。

### 25. AI Issue Translator (AIによるIssue自動翻訳)

- **目的**: 投稿または更新された GitHub Issue が日本語以外（英語など）で記述されている場合に、AI を用いて自動的に日本語へ翻訳し、コメントとして投稿します。
- **設定ファイル**: `.github/workflows/ai-issue-translator.yml`
- **特徴**: `actions/ai-inference` アクションを使用し、GitHub Models の推論 API（本リポジトリでは `openai/gpt-4o-mini` を指定）を利用して言語判定および翻訳します。認証には組み込みの `GITHUB_TOKEN` を利用するため、外部の有料 LLM API キーを必要とせず、完全無料で Issue の多言語サポートを実現します。
- **事前設定**:
  1. GitHub Models が組織（Organization）またはエンタープライズレベルで有効化されている必要があります。
  2. 組織のオーナー権限で `Settings` > `Code, planning, and automation` > `Models` > `Development` へアクセスし、GitHub Models を有効化してください。

### 26. AI PR Translator (AIによるPR自動翻訳)

- **目的**: 投稿または更新された GitHub Pull Request のタイトルと本文が日本語以外（英語など）で記述されている場合に、AI を用いて自動的に日本語へ翻訳し、コメントとして投稿します。これにより、海外コントリビュータとのやり取りを円滑にします。
- **設定ファイル**: `.github/workflows/ai-pr-translator.yml`
- **特徴**: `actions/ai-inference` アクションを使用し、GitHub Models の推論 API（本リポジトリでは `openai/gpt-4o-mini` を指定）を利用して言語判定および翻訳します。認証には組み込みの `GITHUB_TOKEN` を利用するため、外部の有料 LLM API キーを必要とせず、完全無料で Pull Request の多言語サポートを実現します。Fork されたリポジトリからの PR にも対応するため、`pull_request_target` イベントを使用しています。翻訳指示は system prompt に分離し、PR タイトル・本文は翻訳対象データとして受け渡すことでプロンプトインジェクションのリスクを低減します。
- **事前設定**:
  1. GitHub Models が組織（Organization）またはエンタープライズレベルで有効化されている必要があります。
  2. 組織のオーナー権限で `Settings` > `Code, planning, and automation` > `Models` > `Development` へアクセスし、GitHub Models を有効化してください。

### 27. Dockle (コンテナイメージ Linter)

- **目的**: Dockerイメージに対して、CIS（Center for Internet Security）ベンチマークなどのベストプラクティスに基づいた静的解析し、セキュリティリスク（rootユーザーでの実行、不必要な権限、不要なポートの公開など）を検出します。
- **設定ファイル**: `.github/workflows/dockle.yml`
- **特徴**: HadolintがDockerfileの構文やベストプラクティスをチェックし、Trivyが脆弱性をスキャンするのに対して、Dockleはビルドされた「イメージそのもの」の構成やセキュリティベストプラクティスをチェックします。本体の [goodwithtech/dockle](https://github.com/goodwithtech/dockle)（Apache License 2.0）は公開OSSであり、外部のSaaSや有料APIキーを必要とせず、課金も発生しません。公式リリースのバイナリを SHA256 検証したうえで直接実行します（`.github/actions/setup-dockle`）。
- **事前設定**:
  1. 特に追加の設定は不要です。`.github/workflows/dockle.yml` を通じて GitHub Actions 上で自動実行されます。

### 28. actions/stale (Stale Issue/PRの自動クローズ)

- **目的**: 一定期間活動のない Issue および Pull Request を自動的に検出し、通知（ラベル付与）後、さらに動きがなければ自動でクローズします。これによりリポジトリの健全性を保ちます。
- **設定ファイル**: `.github/workflows/stale.yml`
- **特徴**: GitHub 公式が提供する `actions/stale` を利用しています。組み込みの `GITHUB_TOKEN` を用いて GitHub API 経由で Issue/PR のリスト取得・ラベル付与・クローズをするため、外部の有料 LLM API 等を利用せず、公開 OSS リポジトリで完全に無料で利用できます。
- **事前設定**:
  1. リポジトリで GitHub Actions が有効化されていることを確認してください。
  2. `.github/workflows/stale.yml` に Issues および Pull Requests への書き込み権限（`issues: write` / `pull-requests: write`）が付与されていることを確認してください。

### 29. AI Issue Responder (AIによるIssue自動応答)

- **目的**: 新規に作成された GitHub Issue に対して、AI を用いて自動的に挨拶や状況整理（バグ再現手順の追加依頼など）の初期応答をします。
- **設定ファイル**: `.github/workflows/ai-issue-responder.yml`
- **特徴**: `actions/ai-inference` アクションを使用し、GitHub Models の推論 API（本リポジトリでは `openai/gpt-4o-mini` を指定）を利用して、日本語で初回返信を生成しIssueコメントとして投稿します。認証には組み込みの `GITHUB_TOKEN` を利用するため、外部の有料 LLM API キーを必要とせず、完全無料でIssueの一次対応を自動化し、メンテナーの負担を軽減します。Issue タイトル・本文は `<issue_data>` タグでデータとして分離し、その内容に含まれる命令には従わないようプロンプトで明示することで、プロンプトインジェクションのリスクを低減します。
- **事前設定**:
  1. GitHub Models が組織（Organization）またはエンタープライズレベルで有効化されている必要があります。
  2. 組織のオーナー権限で `Settings` > `Code, planning, and automation` > `Models` > `Development` へアクセスし、GitHub Models を有効化してください。

### 30. editorconfig-checker (EditorConfig 検証)

- **目的**: プロジェクト全体のコードのインデント、改行コード、末尾の空白などのフォーマットが `.editorconfig` ファイルの定義に準拠しているかを自動的に検証します。
- **設定ファイル**: `.editorconfig`, `.github/workflows/lint.yml`, `.github/actions/setup-editorconfig-checker/action.yml`
- **特徴**: `editorconfig-checker` をローカルにダウンロードして実行し、結果を `reviewdog` を通じて PR にコメントとして通知します。外部 SaaS や API キーへの依存がなく、公開リポジトリで完全に無料で動作します。
- **事前設定**:
  1. 特に追加の設定は不要です。GitHub Actions 上で自動的に実行されます。

### 31. AI Issue Summarizer (AIによるIssue/PR議論の自動要約)

- **目的**: Issue や Pull Request で長く続いた議論を、`/summarize` というコメントをトリガーにして AI が自動的に要約し、概要・決定事項・未解決課題・Next Steps をまとめます。
- **設定ファイル**: `.github/workflows/ai-issue-summarizer.yml`
- **特徴**: `actions/ai-inference` アクションを使用し、GitHub Models の推論 API（本リポジトリでは `openai/gpt-4o-mini` を指定）を利用して、議論全体を解析します。認証には組み込みの `GITHUB_TOKEN` を利用するため、外部の有料 LLM API キーを必要とせず、完全無料で動作します。また、プロンプトインジェクションのリスクを低減するため、タイトル・本文・コメントデータは独立したファイル・セクションとして構築しています。
- **事前設定**:
  1. GitHub Models が組織（Organization）またはエンタープライズレベルで有効化されている必要があります。
  2. 組織のオーナー権限で `Settings` > `Code, planning, and automation` > `Models` > `Development` へアクセスし、GitHub Models を有効化してください。

### 32. AI Release Translator (AIによるReleaseノート自動翻訳)

- **目的**: GitHub Release が公開（published）または編集（edited）された際に、そのタイトルと本文が日本語以外（主に英語）で記述されている場合に、AI を用いて自動的に日本語へ翻訳・フォーマットし、リリースノートを更新します。これにより、日本語ユーザーにとって読みやすい更新履歴を提供します。
- **設定ファイル**: `.github/workflows/ai-release-translator.yml`
- **特徴**: `actions/ai-inference` アクションを使用し、GitHub Models の推論 API（本リポジトリでは `openai/gpt-4o-mini` を指定）を利用して言語判定および翻訳します。認証には組み込みの `GITHUB_TOKEN` を利用するため、外部の有料 LLM API キーを必要とせず、完全無料でリリースノートの日本語化を実現します。既に日本語の場合は翻訳をスキップするため、`edited` イベントで再実行されても重複翻訳は発生しません。
- **事前設定**:
  1. GitHub Models が組織（Organization）またはエンタープライズレベルで有効化されている必要があります。
  2. 組織のオーナー権限で `Settings` > `Code, planning, and automation` > `Models` > `Development` へアクセスし、GitHub Models を有効化してください。
