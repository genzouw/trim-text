#!/usr/bin/env bats

# .github/scripts/check-pr-policy.sh に対するテスト。
# PR 本文・差分の組み合わせごとに、必須項目の判定と終了コードを検証する。

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../.github/scripts/check-pr-policy.sh"
  AGENTS_MD="${BATS_TEST_DIRNAME}/../AGENTS.md"
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
- [x] 追加した SaaS / GitHub App / Action は公開 OSS リポジトリで完全無料であり、その根拠 URL を本文に記載した（外部サービスを追加していない場合はチェック可）
- [x] リポジトリオーナーへ新規 Secret の登録を依頼していない
- [x] `AGENTS.md` のポリシーに違反していないことを確認した

### 新規ツールの採用 (AGENTS.md 4.1)

- [x] 本 PR では GitHub Actions / GitHub App / SaaS を新規に採用していない
EOF
}

# 新規ツールを採用する PR として 4.1 の確認結果と根拠 URL まで記入した本文を生成する。
write_adoption_body() {
  write_valid_body
  cat >>"${BODY}" <<'EOF'
- [x] 公式の料金ページで「公開 OSS リポジトリでは課金が一切発生しない」ことを確認した
- [x] OSS 無料枠に申請・審査・star 数などの条件がある場合、本リポジトリが現時点でその条件を満たしていることを確認した
- [x] 無料トライアルではなく恒久的に無料で利用できることを確認した
- [x] Action 本体が LLM の API キーを必須としないことを README / ドキュメントで確認した
- 根拠 URL: https://example.com/pricing
EOF
}

# 新規ワークフローを 1 本追加する差分を生成する。
write_new_workflow_diff() {
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/new-tool.yml b/.github/workflows/new-tool.yml
new file mode 100644
--- /dev/null
+++ b/.github/workflows/new-tool.yml
@@ -0,0 +1,2 @@
+name: New Tool
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
  [[ "${output}" == *"未チェックまたは欠落している項目"* ]]
  [[ "${output}" == *"リポジトリオーナーへ新規 Secret の登録を依頼していない"* ]]
}

@test "コスト方針の必須項目を全て削除し無関係な文章だけ残すと exit 1 になる" {
  cat >"${BODY}" <<'EOF'
## 概要 (Summary)

概要

## 変更内容 (Changes)

- 変更

## 検証手順 (Verification Steps)

手順

## コスト方針のセルフチェック (公開 OSS)

- [x] 関係のない文章だけ残した
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"未チェックまたは欠落している項目"* ]]
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

@test "差分で bracket notation (シングルクォート) の API キー参照を追加していると exit 1 になる" {
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/review.yml b/.github/workflows/review.yml
--- a/.github/workflows/review.yml
+++ b/.github/workflows/review.yml
@@ -1,3 +1,4 @@
         env:
+          GEMINI_API_KEY: ${{ secrets['GEMINI_API_KEY'] }}
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"検出: GEMINI_API_KEY"* ]]
}

@test "差分で bracket notation (ダブルクォート) の API キー参照を追加していると exit 1 になる" {
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/review.yml b/.github/workflows/review.yml
--- a/.github/workflows/review.yml
+++ b/.github/workflows/review.yml
@@ -1,3 +1,4 @@
         env:
+          OPENAI_API_KEY: ${{ secrets["OPENAI_API_KEY"] }}
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"検出: OPENAI_API_KEY"* ]]
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

@test "新規ワークフロー追加で 4.1 の確認が未記入だと exit 1 になる" {
  # 「新規に採用していない」と申告しただけでは通過させない (差分クロスチェック)。
  write_valid_body
  write_new_workflow_diff
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"新規追加: .github/workflows/new-tool.yml"* ]]
}

@test "新規 composite action 追加で 4.1 の確認が未記入だと exit 1 になる" {
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/actions/new-tool/action.yml b/.github/actions/new-tool/action.yml
new file mode 100644
--- /dev/null
+++ b/.github/actions/new-tool/action.yml
@@ -0,0 +1,2 @@
+name: New Tool
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"新規追加: .github/actions/new-tool/action.yml"* ]]
}

@test "既存ワークフローへ新規アクションの uses: を追加すると 4.1 未記入で exit 1 になる" {
  # 新規ファイルを伴わず、既存ワークフローに uses: を1行足すだけの採用経路も検出する。
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/lint.yml b/.github/workflows/lint.yml
--- a/.github/workflows/lint.yml
+++ b/.github/workflows/lint.yml
@@ -10,3 +10,4 @@
       - uses: actions/checkout@v4
+      - uses: some-org/new-tool-action@abcdef1
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"新規追加: some-org/new-tool-action"* ]]
}

@test "既存アクションのバージョン更新 (uses: の -/+ ペア) は新規採用として検出しない" {
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/lint.yml b/.github/workflows/lint.yml
--- a/.github/workflows/lint.yml
+++ b/.github/workflows/lint.yml
@@ -10,3 +10,3 @@
-      - uses: actions/checkout@v3
+      - uses: actions/checkout@v4
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
}

@test "既存ワークフローへ二重引用符付き \"uses\" キーで新規アクションを追加すると 4.1 未記入で exit 1 になる" {
  # uses キーは "uses": のように引用符付きでも有効な YAML キーのため検出できる必要がある。
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/lint.yml b/.github/workflows/lint.yml
--- a/.github/workflows/lint.yml
+++ b/.github/workflows/lint.yml
@@ -10,3 +10,4 @@
       - uses: actions/checkout@v4
+      - "uses": some-org/new-tool-action@abcdef1
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"新規追加: some-org/new-tool-action"* ]]
}

@test "既存ワークフローへ単引用符付き 'uses' キーで新規アクションを追加すると 4.1 未記入で exit 1 になる" {
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/lint.yml b/.github/workflows/lint.yml
--- a/.github/workflows/lint.yml
+++ b/.github/workflows/lint.yml
@@ -10,3 +10,4 @@
       - uses: actions/checkout@v4
+      - 'uses': some-org/new-tool-action@abcdef1
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"新規追加: some-org/new-tool-action"* ]]
}

@test "引用符付き uses キーでのバージョン更新は新規採用として検出しない" {
  write_valid_body
  cat >"${DIFF}" <<'EOF'
diff --git a/.github/workflows/lint.yml b/.github/workflows/lint.yml
--- a/.github/workflows/lint.yml
+++ b/.github/workflows/lint.yml
@@ -10,3 +10,3 @@
-      - "uses": actions/checkout@v3
+      - "uses": actions/checkout@v4
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
}

@test "新規ワークフロー追加でも 4.1 の確認と根拠 URL が揃っていれば通過する" {
  write_adoption_body
  write_new_workflow_diff
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"(警告 0 件)"* ]]
}

# ---------- AGENTS.md 4.1 の採用前確認 ----------

@test "4.1 の申告が一切ないと exit 1 になる" {
  write_valid_body
  grep -v '新規に採用していない' "${BODY}" >"${BODY}.tmp"
  mv "${BODY}.tmp" "${BODY}"
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"AGENTS.md 4.1 の採用前確認が記入済み"* ]]
}

@test "4.1 の 4 項目はどれか 1 つでも欠けると採用申告として認められない" {
  local patterns=(
    '公開 OSS リポジトリでは課金が一切発生しない'
    '現時点でその条件を満たしている'
    '無料トライアルではなく恒久的に無料'
    'LLM の API キーを必須としない'
  )
  local pattern
  for pattern in "${patterns[@]}"; do
    write_adoption_body
    # 「採用していない」も消したうえで 1 項目だけ削ると、どちらの経路も満たさない
    grep -v '新規に採用していない' "${BODY}" | grep -v "${pattern}" >"${BODY}.tmp"
    mv "${BODY}.tmp" "${BODY}"
    write_new_workflow_diff
    run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"${pattern}"* ]]
  done
}

@test "4.1 の 4 項目が未チェック (- [ ]) だと採用申告として認められない" {
  write_adoption_body
  perl -0777 -pi -e 's/^- \[x\] 公式の料金ページ/- [ ] 公式の料金ページ/m; s/^- \[x\] 本 PR では/- [ ] 本 PR では/m;' "${BODY}"
  write_new_workflow_diff
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"公開 OSS リポジトリでは課金が一切発生しない"* ]]
}

@test "根拠 URL が記入欄のまま空だと採用申告として認められない" {
  write_adoption_body
  perl -0777 -pi -e 's{^- 根拠 URL: .*$}{- 根拠 URL:}m; s/^- \[x\] 本 PR では/- [ ] 本 PR では/m;' "${BODY}"
  write_new_workflow_diff
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"根拠 URL"* ]]
}

@test "根拠 URL はコスト方針セクション内に無いと認められない" {
  # 概要欄などに無関係な URL が 1 つあるだけで通過してはならない。
  write_adoption_body
  perl -0777 -pi -e 's{^- 根拠 URL: .*$}{- 根拠 URL:}m; s/^- \[x\] 本 PR では/- [ ] 本 PR では/m;' "${BODY}"
  perl -0777 -pi -e 's{^(## 概要 \(Summary\))$}{$1\n\n参考: https://example.com/pricing}m' "${BODY}"
  write_new_workflow_diff
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"根拠 URL"* ]]
}

@test "新規ツールを追加しない PR は 4.1 の 4 項目が未チェックでも通過する" {
  # 形骸化を避けるため、採用しない PR には 4 項目のチェックを要求しない。
  write_valid_body
  cat >>"${BODY}" <<'EOF'
- [ ] 公式の料金ページで「公開 OSS リポジトリでは課金が一切発生しない」ことを確認した
- [ ] OSS 無料枠に申請・審査・star 数などの条件がある場合、本リポジトリが現時点でその条件を満たしていることを確認した
- [ ] 無料トライアルではなく恒久的に無料で利用できることを確認した
- [ ] Action 本体が LLM の API キーを必須としないことを README / ドキュメントで確認した
- 根拠 URL:
EOF
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
}

# ---------- forbidden_keys と AGENTS.md 5.1 の同期 ----------

@test "forbidden_keys が AGENTS.md 5.1 に列挙された API キーをすべてカバーしている" {
  local forbidden_keys
  forbidden_keys="$(grep -oE "^forbidden_keys='[^']*'" "${SCRIPT}" | sed -E "s/^forbidden_keys='//; s/'\$//")"
  [ -n "${forbidden_keys}" ]

  local agents_keys
  # バッククォートは Markdown コードスパンの区切り文字を抽出する正規表現であり、コマンド置換ではない
  # （ダブルクォートに変えると実際にコマンド置換されてしまうため、意図的に単一引用符のままにする）
  # shellcheck disable=SC2016
  agents_keys="$(awk '/^### 5\.1 /{flag=1; next} /^### 5\.2 /{flag=0} flag' "${AGENTS_MD}" |
    grep -oE '`[A-Z0-9_]+_API_KEY`' | tr -d '`' | sed 's/_API_KEY$//' | sort -u)"
  [ -n "${agents_keys}" ]

  while IFS= read -r key; do
    [[ "${forbidden_keys}" =~ (^|\|)${key}(\||$) ]]
  done <<<"${agents_keys}"
}

# ---------- PULL_REQUEST_TEMPLATE.md との同期 ----------

# cost_required_patterns はテンプレートの文言に対する部分一致で判定するため、
# 双方の文言がずれると「テンプレートどおりに記入しても必ず落ちる」状態になり、
# しかもフィクスチャだけを見ているテストでは検出できない。実物のテンプレートを
# 入力に使い、正しく記入した PR が確実に通過することを保証する。
@test "PULL_REQUEST_TEMPLATE.md をそのまま記入した本文が通過する" {
  local template="${BATS_TEST_DIRNAME}/../.github/PULL_REQUEST_TEMPLATE.md"
  [ -f "${template}" ]

  # 記入例の HTML コメントを除去し、各節に本文を補い、チェックボックスを全て付ける
  # = 「テンプレートに沿って正しく記入した PR 本文」を再現する。
  # 置換に改行を含むため sed は使わない (BSD sed は RHS の \n を改行として
  # 解釈せず、macOS と CI で結果が変わる)。
  perl -0777 -pe '
    s/<!--.*?-->//gs;
    s/^- \[ \]/- [x]/gm;
    s/^(## .*)$/$1\n\n記入済みの本文。/gm;
  ' "${template}" >"${BODY}"

  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"要件を満たしています"* ]]
}

# 「新規ツールを採用する」経路もテンプレートの文言で通過することを保証する。
# 4.1 の 4 項目のパターンがテンプレートとずれると、採用 PR が永久に通らなくなる。
@test "PULL_REQUEST_TEMPLATE.md の 4.1 を記入した本文が採用 PR として通過する" {
  local template="${BATS_TEST_DIRNAME}/../.github/PULL_REQUEST_TEMPLATE.md"
  [ -f "${template}" ]

  perl -0777 -pe '
    s/<!--.*?-->//gs;
    s/^- \[ \]/- [x]/gm;
    s/^- \[x\] 本 PR では/- [ ] 本 PR では/m;
    s{^- 根拠 URL:.*$}{- 根拠 URL: https://example.com/pricing}m;
    s/^(## .*)$/$1\n\n記入済みの本文。/gm;
  ' "${template}" >"${BODY}"

  write_new_workflow_diff
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"要件を満たしています"* ]]
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

@test "--body の値が末尾で欠落していると exit 2 になる (無限ループしない)" {
  run timeout 5 bash "${SCRIPT}" --body
  [ "${status}" -eq 2 ]
}

@test "--diff の値が末尾で欠落していると exit 2 になる (無限ループしない)" {
  write_valid_body
  run timeout 5 bash "${SCRIPT}" --body "${BODY}" --diff
  [ "${status}" -eq 2 ]
}

@test "--report の値が末尾で欠落していると exit 2 になる (無限ループしない)" {
  write_valid_body
  run timeout 5 bash "${SCRIPT}" --body "${BODY}" --report
  [ "${status}" -eq 2 ]
}

@test "--report で結果をファイルへ書き出せる" {
  write_valid_body
  run bash "${SCRIPT}" --body "${BODY}" --diff "${DIFF}" --report "${BATS_TEST_TMPDIR}/report.md"
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
  grep -q 'PR Policy Checker' "${BATS_TEST_TMPDIR}/report.md"
}
