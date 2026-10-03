#!/usr/bin/env bats

# .github/scripts/check-osv-ignores.sh に対するテスト。
# osv-scanner.toml の除外エントリごとに、理由と期限の判定と終了コードを検証する。

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../.github/scripts/check-osv-ignores.sh"
  ROOT="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${ROOT}/sub"
  TOML="${ROOT}/sub/osv-scanner.toml"
  export OSV_IGNORE_TODAY="2026-10-03"
}

@test "osv-scanner.toml が無ければ成功する" {
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"osv-scanner.toml はありません"* ]]
}

@test "理由と期限内の ignoreUntil があれば成功する" {
  cat >"${TOML}" <<'TOML'
[[IgnoredVulns]]
id = "GHSA-aaaa-bbbb-cccc"
ignoreUntil = 2027-01-03
reason = "修正版が無く、CI の lint でしか使わない"
TOML
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"検査した除外: 1 件"* ]]
}

@test "複数行文字列の reason を理由ありと扱う" {
  cat >"${TOML}" <<'TOML'
[[IgnoredVulns]]
id = "GHSA-aaaa-bbbb-cccc"
ignoreUntil = 2027-01-03
reason = """
修正版が無い。\
CI の lint でしか使わない。\
"""
TOML
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 0 ]
}

@test "ignoreUntil が無ければ失敗する" {
  cat >"${TOML}" <<'TOML'
[[IgnoredVulns]]
id = "GHSA-aaaa-bbbb-cccc"
reason = "修正版が無い"
TOML
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"ignoreUntil がありません"* ]]
}

@test "reason が無ければ失敗する" {
  cat >"${TOML}" <<'TOML'
[[IgnoredVulns]]
id = "GHSA-aaaa-bbbb-cccc"
ignoreUntil = 2027-01-03
TOML
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"reason がありません"* ]]
}

@test "reason が空文字なら失敗する" {
  cat >"${TOML}" <<'TOML'
[[IgnoredVulns]]
id = "GHSA-aaaa-bbbb-cccc"
ignoreUntil = 2027-01-03
reason = ""
TOML
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"reason がありません"* ]]
}

@test "ignoreUntil を過ぎていれば失敗する" {
  cat >"${TOML}" <<'TOML'
[[IgnoredVulns]]
id = "GHSA-aaaa-bbbb-cccc"
ignoreUntil = 2026-10-02
reason = "修正版が無い"
TOML
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"を過ぎています"* ]]
}

@test "ignoreUntil が当日なら成功する" {
  cat >"${TOML}" <<'TOML'
[[IgnoredVulns]]
id = "GHSA-aaaa-bbbb-cccc"
ignoreUntil = 2026-10-03
reason = "修正版が無い"
TOML
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 0 ]
}

@test "ignoreUntil が上限 (183 日) を超えていれば失敗する" {
  cat >"${TOML}" <<'TOML'
[[IgnoredVulns]]
id = "GHSA-aaaa-bbbb-cccc"
ignoreUntil = 2099-12-31
reason = "修正版が無い"
TOML
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"遠すぎます"* ]]
}

@test "複数エントリのうち 1 件でも不備があれば失敗し、不備のある id を示す" {
  cat >"${TOML}" <<'TOML'
[[IgnoredVulns]]
id = "GHSA-good-good-good"
ignoreUntil = 2027-01-03
reason = "修正版が無い"

[[IgnoredVulns]]
id = "GHSA-bad0-bad0-bad0"
reason = "修正版が無い"

[[PackageOverrides]]
name = "lib"
ignore = true
TOML
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 1 ]
  [[ "${output}" == *"ok: "*"GHSA-good-good-good"* ]]
  [[ "${output}" == *"GHSA-bad0-bad0-bad0: ignoreUntil がありません"* ]]
  [[ "${output}" == *"検査した除外: 2 件"* ]]
}

@test "node_modules 配下の osv-scanner.toml は対象にしない" {
  mkdir -p "${ROOT}/node_modules/pkg"
  cat >"${ROOT}/node_modules/pkg/osv-scanner.toml" <<'TOML'
[[IgnoredVulns]]
id = "GHSA-aaaa-bbbb-cccc"
TOML
  run "${SCRIPT}" "${ROOT}"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"osv-scanner.toml はありません"* ]]
}
