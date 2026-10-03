#!/usr/bin/env bash
# osv-scanner.toml の [[IgnoredVulns]] が「理由つき・期限つき」であることを検査する。
#
# 修正版の無い脆弱性は除外するしかないが、期限の無い除外は見直されないまま残り、
# 修正版が出たあとも検知を止め続ける。そのため、すべての除外に次を要求する。
#
#   - id          : 空でないこと
#   - reason      : 空でないこと
#   - ignoreUntil : YYYY-MM-DD 形式で、今日以降かつ今日から MAX_DAYS 日以内であること
#
# 判定は正規表現だけで行う (AGENTS.md §4.2)。TOML の完全なパーサではないため、
# キーは行頭から `key = value` の形で書くこと。
#
# 使い方: check-osv-ignores.sh [走査するディレクトリ]
# 環境変数 OSV_IGNORE_TODAY (YYYY-MM-DD) で「今日」を差し替えられる (テスト用)。
set -euo pipefail

ROOT="${1:-.}"
MAX_DAYS=183

today="${OSV_IGNORE_TODAY:-$(date -u +%Y-%m-%d)}"
if ! [[ "${today}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "::error::OSV_IGNORE_TODAY の形式が不正です: ${today}" >&2
  exit 2
fi

# today から MAX_DAYS 日後の日付を求める。GNU date と BSD date (macOS) の両方に対応する。
if limit="$(date -u -d "${today} +${MAX_DAYS} days" +%Y-%m-%d 2>/dev/null)"; then
  :
elif limit="$(date -u -j -v "+${MAX_DAYS}d" -f %Y-%m-%d "${today}" +%Y-%m-%d 2>/dev/null)"; then
  :
else
  echo "::error::日付の計算に失敗しました (date コマンドが GNU / BSD のどちらの書式も受け付けません)" >&2
  exit 2
fi

# mapfile は bash 4 以降の機能で、macOS 標準の bash 3.2 には無いため使わない。
files=()
while IFS= read -r found; do
  files+=("${found}")
done < <(
  find "${ROOT}" -type d \( -name node_modules -o -name .git \) -prune -o \
    -type f -name 'osv-scanner.toml' -print | sort
)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "osv-scanner.toml はありません。検査する除外はありません。"
  exit 0
fi

status=0
total=0

# 1 エントリぶんの検査。日付は YYYY-MM-DD 形式なので文字列比較で前後を判定できる。
check_entry() { # <file> <line> <id> <reason の有無> <ignoreUntil>
  local file="$1" line="$2" id="$3" has_reason="$4" until="$5"
  local label="${id:-(id なし)}"
  total=$((total + 1))

  if [[ -z "${id}" ]]; then
    echo "::error file=${file},line=${line}::id がありません"
    status=1
  fi
  if [[ "${has_reason}" != 1 ]]; then
    echo "::error file=${file},line=${line}::${label}: reason がありません。除外してよいと判断した根拠を書いてください"
    status=1
  fi
  if [[ -z "${until}" ]]; then
    echo "::error file=${file},line=${line}::${label}: ignoreUntil がありません。期限の無い除外は禁止です"
    status=1
  elif [[ "${until}" < "${today}" ]]; then
    echo "::error file=${file},line=${line}::${label}: ignoreUntil (${until}) を過ぎています。修正版があれば更新して除外を削除し、無ければ影響を再評価して期限を延ばしてください"
    status=1
  elif [[ "${until}" > "${limit}" ]]; then
    echo "::error file=${file},line=${line}::${label}: ignoreUntil (${until}) が遠すぎます。${MAX_DAYS} 日以内 (${limit} まで) にしてください"
    status=1
  else
    echo "ok: ${file}: ${label} (ignoreUntil ${until})"
  fi
}

for file in "${files[@]}"; do
  in_entry=0
  entry_line=0
  id=""
  has_reason=0
  until=""
  n=0

  # check_entry は file をメッセージに埋め込むだけで書き込まない (SC2094 は誤検知)。
  # shellcheck disable=SC2094
  while IFS= read -r text || [[ -n "${text}" ]]; do
    n=$((n + 1))
    if [[ "${text}" =~ ^[[:space:]]*\[ ]]; then
      # 新しいテーブルの開始。直前の IgnoredVulns エントリを確定する。
      if [[ "${in_entry}" == 1 ]]; then
        check_entry "${file}" "${entry_line}" "${id}" "${has_reason}" "${until}"
      fi
      in_entry=0
      if [[ "${text}" =~ ^[[:space:]]*\[\[[[:space:]]*IgnoredVulns[[:space:]]*\]\] ]]; then
        in_entry=1
        entry_line="${n}"
        id=""
        has_reason=0
        until=""
      fi
      continue
    fi
    [[ "${in_entry}" == 1 ]] || continue

    if [[ "${text}" =~ ^[[:space:]]*id[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
      id="${BASH_REMATCH[1]}"
    elif [[ "${text}" =~ ^[[:space:]]*ignoreUntil[[:space:]]*=[[:space:]]*\"?([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
      until="${BASH_REMATCH[1]}"
    elif [[ "${text}" =~ ^[[:space:]]*reason[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      # `reason = ""` と `reason = ''` だけを空とみなす。複数行文字列 (""" / ''') は
      # 開始行に本文が無くても、続く行に本文がある前提で理由ありと扱う。
      value="${BASH_REMATCH[1]}"
      if [[ ! "${value}" =~ ^(\"\"|\'\')[[:space:]]*(#.*)?$ ]]; then
        has_reason=1
      fi
    fi
  done <"${file}"

  if [[ "${in_entry}" == 1 ]]; then
    check_entry "${file}" "${entry_line}" "${id}" "${has_reason}" "${until}"
  fi
done

echo "検査した除外: ${total} 件 (基準日 ${today}、期限の上限 ${limit})"
exit "${status}"
