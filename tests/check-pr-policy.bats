#!/usr/bin/env bats

# .github/scripts/check-pr-policy.sh に対するテスト。
# PR 本文・差分の組み合わせごとに、必須項目の判定と終了コードを検証する。

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../.github/scripts/check-pr-policy.sh"
  BODY="${BATS_TEST_TMPDIR}/body.md"
  DIFF="${BATS_TEST_TMPDIR}/pr.diff"
  : >"${DIFF}"
}

# 必須項目をすべて満たす PR 本文を生成する。
write_valid_body() {
  cat >"${BODY}" <<'EOF'
## 概要 (Summary)

<!-- テンプレートの記入例コメント -->

不要なワークフローを削除します。

## 変更内容 (Changes)

- ワークフローを 1 本削除

## 検証手順 (Verification Steps)

`actionlint` がエラーなく終了すること。

## 手動設定・事前作業 (Manual Setup / Pre-requisites)

- [ ] （マージ前に必要な手動作業がある場合、ここに内容を記載してチェックしてください）

## チェックリスト (Checklist)

- [ ] `shellcheck` のエラーが解消されていること

## コスト方針のセルフチェック (公開 OSS)

- [x] LLM プロバイダや従量課金 API のキーを GitHub Secrets へ追加していない
- [x] 追加した SaaS / GitHub App / Action は公開 OSS リポジトリで完全無料である
- [x] リポジトリオーナーへ新規 Secret の登録を依頼していない
- [x] `AGENTS.md` のポリシーに違反していないことを確認した
EOF
}

# ---------- 正常系 ----------

@test "満たしている PR 本文は exit 0 で通過する" {
  write_valid_body
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"要件を満たしています"* ]]
}

@test "テンプレートの HTML コメントだけの節は未記入とみなす" {
  cat >"${BODY}" <<'EOF'
## 概要 (Summary)

<!--
このPull Requestが解決する問題を記述してください。
-->

## 変更内容 (Changes)

- 何かを変更

## 検証手順 (Verification Steps)

手順

## コスト方針のセルフチェック (公開 OSS)

- [x] 確認済み
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"概要 (Summary)"* ]]
}

# ---------- 必須セクションの欠落 ----------

@test "検証手順の節がないと exit 1 になる" {
  write_valid_body
  # 「## 検証手順」の節を丸ごと取り除く
  awk '/^## 検証手順/ { skip = 1 } /^## 手動設定/ { skip = 0 } !skip' "${BODY}" >"${BODY}.tmp"
  mv "${BODY}.tmp" "${BODY}"
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"検証手順 (Verification Steps)"* ]]
}

@test "コスト方針の節が丸ごと欠落していると exit 1 になる" {
  write_valid_body
  awk '/^## コスト方針/ { skip = 1 } !skip' "${BODY}" >"${BODY}.tmp"
  mv "${BODY}.tmp" "${BODY}"
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"セクションごと欠落"* ]]
}

@test "コスト方針に未チェック項目が残っていると exit 1 になる" {
  write_valid_body
  sed -i.bak 's/- \[x\] リポジトリオーナーへ/- [ ] リポジトリオーナーへ/' "${BODY}"
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"未チェックの項目が 1 件"* ]]
}

# ---------- 差分に対する検査 ----------

@test "差分で LLM の API キー参照を追加していると exit 1 になる" {
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/review.yml b/.github/workflows/review.yml
--- a/.github/workflows/review.yml
+++ b/.github/workflows/review.yml
@@ -1,3 +1,4 @@
         env:
+          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"検出: GEMINI_API_KEY"* ]]
}

@test "既存行の API キー参照 (削除行・文脈行) は検出しない" {
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/review.yml b/.github/workflows/review.yml
--- a/.github/workflows/review.yml
+++ b/.github/workflows/review.yml
@@ -1,4 +1,3 @@
         env:
-          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
}

@test "差分で .github/actions/ への LLM の API キー参照を追加していると exit 1 になる" {
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/actions/foo/action.yml b/.github/actions/foo/action.yml
--- a/.github/actions/foo/action.yml
+++ b/.github/actions/foo/action.yml
@@ -1,3 +1,4 @@
         env:
+          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"検出: GEMINI_API_KEY"* ]]
}

@test "ワークフロー以外のファイルへの追加行は検出しない" {
  write_valid_body
  # テストのフィクスチャやドキュメントに現れる API キー名は誤検知させない
  cat >"${DIFF}" <<'EOF'
diff --git a/tests/fixtures.bats b/tests/fixtures.bats
new file mode 100644
--- /dev/null
+++ b/tests/fixtures.bats
@@ -0,0 +1,2 @@
+# 検出されるべき例:
+-          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
}

@test "本文で API キー名に言及しただけでは失敗しない" {
  write_valid_body
  printf '\n本 PR は GEMINI_API_KEY を使わない方針を明文化します。\n' >>"${BODY}"
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
}

@test "新規ワークフロー追加で根拠 URL がないと警告になる (失敗はしない)" {
  write_valid_body
  # 本文から https:// を含む行を除く
  grep -v 'https://' "${BODY}" >"${BODY}.tmp"
  mv "${BODY}.tmp" "${BODY}"
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/new-tool.yml b/.github/workflows/new-tool.yml
new file mode 100644
--- /dev/null
+++ b/.github/workflows/new-tool.yml
@@ -0,0 +1,2 @@
+name: New Tool
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"(警告 1 件)"* ]]
  [[ "${output}" == *"根拠 URL"* ]]
}

@test "新規ワークフロー追加で根拠 URL があれば警告にならない" {
  write_valid_body
  printf '\n料金プラン: https://example.com/pricing\n' >>"${BODY}"
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/new-tool.yml b/.github/workflows/new-tool.yml
new file mode 100644
--- /dev/null
+++ b/.github/workflows/new-tool.yml
@@ -0,0 +1,2 @@
+name: New Tool
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"新規ワークフローに根拠 URL が添えられている"* ]]
  [[ "${output}" == *"(警告 0 件)"* ]]
}

# ---------- 引数の扱い ----------

@test "--body の指定がないと exit 2 になる" {
  run bash "${SCRIPT}"
  [ "${status}" -eq 2 ]
}

@test "存在しない --diff を指定すると exit 2 になる" {
  write_valid_body
  run bash "${SCRIPT}" --body "${BODY}" --diff "${BATS_TEST_TMPDIR}/missing.diff"
  [ "${status}" -eq 2 ]
}

@test "--report で結果をファイルへ書き出せる" {
  write_valid_body
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}" --report "${BATS_TEST_TMPDIR}/report.md"
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
  grep -q 'PR Policy Checker' "${BATS_TEST_TMPDIR}/report.md"
}
