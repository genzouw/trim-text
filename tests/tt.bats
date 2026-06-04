#!/usr/bin/env bats

# tt スクリプトに対する境界値・ランダム入力テスト。
# Scorecard の fuzzing チェックは bash を直接サポートしないが、
# 想定外入力に対するクラッシュ・コマンドインジェクションを早期検知する。

setup() {
  TT="${BATS_TEST_DIRNAME}/../tt"
}

# ---------- 正常系（仕様の代表例）----------

@test "no options: stdin is passed through unchanged" {
  run bash -c "printf '1****\n*2***\n**3**\n***4*\n****5\n' | '${TT}'"
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '1****\n*2***\n**3**\n***4*\n****5')" ]
}

@test "-t1 -b1 -l1 -r1 trims one char/line from each side" {
  run bash -c "printf '1****\n*2***\n**3**\n***4*\n****5\n' | '${TT}' -t1 -b1 -l1 -r1"
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf '2**\n*3*\n**4')" ]
}

@test "-t0 -b0 -l0 -r0 is identity" {
  run bash -c "printf 'a\nb\nc\n' | '${TT}' -t0 -b0 -l0 -r0"
  [ "${status}" -eq 0 ]
  [ "${output}" = "$(printf 'a\nb\nc')" ]
}

# ---------- 境界値 ----------

@test "trimming more lines than available produces empty output" {
  run bash -c "printf 'a\nb\n' | '${TT}' -t10"
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "trimming more columns than available produces blank lines" {
  run bash -c "printf 'abc\nde\n' | '${TT}' -l100"
  [ "${status}" -eq 0 ]
  # 各行が空文字列になり、行数は維持される
  line_count=$(printf '%s' "${output}" | wc -l | tr -d ' ')
  [ "${line_count}" = "1" ] # printf '%s' は末尾改行を付けないため、2 行のうち最後の \n のみカウントされる
}

@test "empty stdin yields empty output" {
  run bash -c ": | '${TT}' -t1 -b1 -l1 -r1"
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

# ---------- 不正入力（コマンドインジェクション耐性）----------

@test "non-numeric -t is rejected" {
  run bash -c "printf 'x\n' | '${TT}' -tabc"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"must be a non-negative integer"* ]]
}

@test "negative -b is rejected" {
  run bash -c "printf 'x\n' | '${TT}' -b-3"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"must be a non-negative integer"* ]]
}

@test "shell metacharacter in -l is rejected (injection guard)" {
  # サニタイズが効かないと sed コマンド文字列へ展開され任意コード実行のリスクがある
  run bash -c "printf 'x\n' | '${TT}' '-l;id'"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"must be a non-negative integer"* ]]
}

@test "backtick in -r is rejected (injection guard)" {
  run bash -c "printf 'x\n' | '${TT}' '-r\`id\`'"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"must be a non-negative integer"* ]]
}

@test "leading-zero numeric -t is treated as decimal (no octal interpretation)" {
  # 08 は 8 進数では不正だが tail/awk へは 10 進数として渡る必要がある
  run bash -c "printf '%s\n' {1..20} | '${TT}' -t08"
  [ "${status}" -eq 0 ]
  # 先頭 8 行スキップ → 9..20 (12 行) が出力される
  line_count=$(printf '%s\n' "${output}" | wc -l | tr -d ' ')
  [ "${line_count}" = "12" ]
  first_line=$(printf '%s\n' "${output}" | head -n 1)
  [ "${first_line}" = "9" ]
}

# ---------- ランダム入力（クラッシュ検知の簡易ファジング）----------

@test "random byte input does not crash with valid integer options" {
  # /dev/urandom から少量の入力を流し、想定入力以外でも非ゼロ終了しないことを確認
  for _ in 1 2 3 4 5; do
    run bash -c "LC_ALL=C tr -dc 'A-Za-z0-9\n' </dev/urandom | head -c 200 | '${TT}' -t1 -b1 -l1 -r1"
    [ "${status}" -eq 0 ]
  done
}

@test "random valid integer combinations do not crash" {
  for _ in 1 2 3 4 5 6 7 8; do
    t=$((RANDOM % 5))
    b=$((RANDOM % 5))
    l=$((RANDOM % 5))
    r=$((RANDOM % 5))
    run bash -c "printf '%s\n' {1..30} | '${TT}' -t${t} -b${b} -l${l} -r${r}"
    [ "${status}" -eq 0 ]
  done
}
