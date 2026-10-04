1. **目的**:
Dockerイメージのメタデータやファイル権限などの構造的妥当性を自動検証し、CIパイプラインのコード品質と安全性をより強固に改善すること。

2. **導入する/変更するもの**:
- `tests/container-structure-test.yaml`: 新規作成。Dockerイメージの検証ルール（ENTRYPOINT、WORKDIR、実行権限など）を定義。
- `.github/actions/setup-container-structure-test/action.yml`: 新規作成。`container-structure-test` バイナリのダウンロード・検証（SHA256）・キャッシュを行うローカル composite action。
- `.github/workflows/docker-build.yml`: 変更。上記アクションを呼び出し、Dockle スキャンの直後に構造テストを実行するステップを追加。

3. **「公開 OSS で完全無料」の証明**:
`container-structure-test` は Google が提供するオープンソースの CLI ツール（Apache License 2.0）です。外部の SaaS や API は一切使用せず、CI ランナー上でスタンドアロンで動作するため完全無料です。
公式リポジトリ: [GoogleContainerTools/container-structure-test](https://github.com/GoogleContainerTools/container-structure-test)

4. **既存ツールとの重複がないことの確認**:
- **Trivy / Dockle**: これらは CVE 脆弱性のスキャンやベストプラクティス（root権限実行の防止など）をチェックするものであり、イメージの機能的な構成要素（メタデータや個別ファイルのパーミッション）を宣言的にテストする `container-structure-test` とは役割が異なります。

5. **マージ前に必要な手動セットアップ手順**:
SaaS や外部連携を使用しないローカル実行の CLI ツールの追加であるため、特別な手動セットアップや Secrets の登録は一切不要です。
1. マージ後、次回の CI 実行で自動的に `container-structure-test` が起動することを確認します。

6. **想定リスクとロールバック手順**:
- **想定リスク**: `container-structure-test` のダウンロード元URLが変更されたり、タグの更新によりハッシュ値が変わった場合、CI が失敗する可能性があります。
- **ロールバック手順**: もし CI が継続して失敗する場合は、該当 PR の `Revert` を実施し、`.github/workflows/docker-build.yml` から実行ステップを削除してください。
