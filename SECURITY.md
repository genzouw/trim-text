# Security Policy

## サポート対象バージョン

本プロジェクトでは、`main` ブランチおよび最新の GitHub Release タグでのみセキュリティ修正を提供します。
過去バージョンに対してはバックポートを行いません。

| バージョン     | サポート           |
| -------------- | ------------------ |
| latest release | :white_check_mark: |
| それ以前       | :x:                |

## 脆弱性の報告方法

セキュリティ上の問題を見つけた場合は、**公開 Issue を作成せず**、GitHub の **Private vulnerability reporting** から非公開に連絡してください。

- リポジトリの `Security` タブ → `Report a vulnerability` から非公開レポートを作成する
- 参考: <https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability>

報告には以下の情報を可能な範囲で含めてください。

- 影響を受けるバージョン / コミット
- 再現手順 (PoC があれば添付)
- 想定される影響範囲
- 既知の回避策があればその内容

## 対応プロセス

- 初回応答: **7 日以内** を目標
- 状況更新: 進捗があり次第、少なくとも 14 日ごとに連絡
- 修正リリース: 影響度と再現性を確認のうえ、可能な限り速やかに修正版をリリース
- 公表: 修正リリース後、必要に応じて GitHub Security Advisory として公開

報告者の希望に応じて、リリースノートや advisory にクレジットを記載します。

## 対象範囲外

以下は本ポリシーの脆弱性報告の対象外です。通常の Issue としてご報告ください。

- 機能要望・改善提案
- ドキュメントの誤記
- 依存ライブラリの古さそのもの (Dependabot で自動追従しています)
