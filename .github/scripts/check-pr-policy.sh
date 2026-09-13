#!/usr/bin/env bash
# Pull Request の本文と差分が .github/PULL_REQUEST_TEMPLATE.md および AGENTS.md の
# 必須項目を満たしているかを検査する。
#
# 判定はすべて文字列一致・正規表現による決定的な処理で行い、LLM 推論は使わない
# (AGENTS.md 4.1「CI の自動化は決定的な実装を優先する」)。
#
# Usage:
#   check-pr-policy.sh --body <file> [--diff <file>] [--report <file>]
#
# Exit status:
#   0  必須項目をすべて満たしている
#   1  必須項目に不足がある
#   2  引数の指定が誤っている
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: check-pr-policy.sh --body <file> [--diff <file>] [--report <file>]

  --body <file>    PR 本文を保存したファイル (必須)
  --diff <file>    PR の unified diff を保存したファイル (省略時は差分検査をスキップ)
  --report <file>  Markdown の検査結果の出力先 (省略時は標準出力)
EOF
}

body_file=""
diff_file=""
report_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --body)
      body_file="${2:-}"
      shift 2 || true
      ;;
    --diff)
      diff_file="${2:-}"
      shift 2 || true
      ;;
    --report)
      report_file="${2:-}"
      shift 2 || true
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "${body_file}" || ! -f "${body_file}" ]]; then
  printf '--body に既存のファイルを指定してください。\n' >&2
  usage
  exit 2
fi

if [[ -n "${diff_file}" && ! -f "${diff_file}" ]]; then
  printf '--diff に指定したファイルが存在しません: %s\n' "${diff_file}" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# 前処理: HTML コメント (テンプレートの記入例) を除去する
# ---------------------------------------------------------------------------
strip_html_comments() {
  awk '
    BEGIN { in_comment = 0 }
    {
      line = $0
      out = ""
      while (1) {
        if (in_comment) {
          idx = index(line, "-->")
          if (idx == 0) { line = ""; break }
          in_comment = 0
          line = substr(line, idx + 3)
        }
        idx = index(line, "<!--")
        if (idx == 0) { out = out line; break }
        out = out substr(line, 1, idx - 1)
        line = substr(line, idx + 4)
        in_comment = 1
      }
      print out
    }
  ' "$1"
}

body_stripped="$(mktemp)"
trap 'rm -f "${body_stripped}"' EXIT
strip_html_comments "${body_file}" >"${body_stripped}"

# 指定した見出しに属する行を取り出す。見出しは「## 」で始まる行を境界とする。
section_lines() {
  awk -v prefix="$1" '
    /^## / {
      inside = (index($0, prefix) == 1)
      next
    }
    inside { print }
  ' "${body_stripped}"
}

# 見出し配下に実体のある行 (空白のみでない行) が 1 行以上あるか。
section_has_content() {
  section_lines "$1" | grep -qE '[^[:space:]]'
}

# ---------------------------------------------------------------------------
# 検査
# ---------------------------------------------------------------------------
declare -a results=()
failures=0
warnings=0

record() {
  # $1: pass | fail | warn, $2: 項目名, $3: 補足
  local mark
  case "$1" in
    pass) mark='✅' ;;
    warn)
      mark='⚠️'
      warnings=$((warnings + 1))
      ;;
    *)
      mark='❌'
      failures=$((failures + 1))
      ;;
  esac
  results+=("| ${mark} | $2 | $3 |")
}

check_section() {
  # $1: 見出しの接頭辞, $2: 不足時の案内
  if section_has_content "$1"; then
    record pass "\`$1\` に記述がある" "-"
  else
    record fail "\`$1\` に記述がある" "$2"
  fi
}

check_section '## 概要 (Summary)' 'この変更で何を解決するかを記述してください。'
check_section '## 変更内容 (Changes)' '変更した箇所を箇条書きで列挙してください。'
check_section '## 検証手順 (Verification Steps)' 'レビュアーが変更を確認する手順を記述してください。'

# コスト方針のセルフチェックは全項目が [x] であること (AGENTS.md 11 章)。
cost_section='## コスト方針のセルフチェック'
if section_has_content "${cost_section}"; then
  unchecked="$(section_lines "${cost_section}" | grep -cE '^[[:space:]]*- \[[[:space:]]\]' || true)"
  if [[ "${unchecked}" -eq 0 ]]; then
    record pass "\`${cost_section}\` の全項目がチェック済み" "-"
  else
    record fail "\`${cost_section}\` の全項目がチェック済み" "未チェックの項目が ${unchecked} 件あります。"
  fi
else
  record fail "\`${cost_section}\` の全項目がチェック済み" 'セクションごと欠落しています。テンプレートを利用してください。'
fi

# ---------------------------------------------------------------------------
# 差分に対する検査
# ---------------------------------------------------------------------------
# AGENTS.md 5.1 で禁止されている LLM プロバイダの API キー。
# AGENTS.md 5.1 に列挙されている代表例をすべて含めること。5.1 の一覧を更新した
# 場合はここも合わせて更新し、tests/check-pr-policy.bats のカバレッジ確認テストで
# 追随漏れがないことを確認する。
forbidden_keys='GEMINI|OPENAI|ANTHROPIC|CLAUDE|MISTRAL|COHERE|GROQ|DEEPSEEK|PERPLEXITY|TAVILY|HUGGINGFACE|REPLICATE'

if [[ -n "${diff_file}" ]]; then
  # 禁止されているのは CI へ組み込むこと (AGENTS.md 5.1) なので、検査対象は
  # .github/workflows と .github/actions への追加行に限定する。テストの
  # フィクスチャやドキュメント中の記述を誤検知させないための絞り込み。
  added_keys="$(awk '
    /^\+\+\+ / {
      path = $2
      sub(/^b\//, "", path)
      in_target = (path ~ /^\.github\/(workflows|actions)\//)
      next
    }
    in_target && /^\+[^+]/ { print }
  ' "${diff_file}" |
    grep -oE "secrets\.(${forbidden_keys})[A-Z0-9_]*" |
    sed 's/^secrets\.//' | sort -u || true)"
  if [[ -z "${added_keys}" ]]; then
    record pass 'LLM プロバイダの API キー参照を追加していない' "-"
  else
    record fail 'LLM プロバイダの API キー参照を追加していない' \
      "検出: $(echo "${added_keys}" | tr '\n' ' ' | sed 's/ $//')"
  fi

  # 新規に追加されたワークフローファイルを抽出する。
  new_workflows="$(awk '
    /^--- \/dev\/null$/ { pending = 1; next }
    /^\+\+\+ b\// {
      if (pending && $2 ~ /^b\/\.github\/workflows\/.*\.ya?ml$/) {
        sub(/^b\//, "", $2)
        print $2
      }
      pending = 0
      next
    }
    { pending = 0 }
  ' "${diff_file}" | sort -u || true)"

  if [[ -n "${new_workflows}" ]]; then
    if grep -qE 'https://' "${body_stripped}"; then
      record pass '新規ワークフローに根拠 URL が添えられている' \
        "対象: $(echo "${new_workflows}" | tr '\n' ' ' | sed 's/ $//')"
    else
      record warn '新規ワークフローに根拠 URL が添えられている' \
        '公開 OSS で無料利用できる根拠 (料金プランや公式ドキュメントの URL) を本文に記載してください。'
    fi
  fi
else
  record warn 'LLM プロバイダの API キー参照を追加していない' '差分が指定されていないため検査をスキップしました。'
fi

# ---------------------------------------------------------------------------
# 結果の出力
# ---------------------------------------------------------------------------
{
  echo '### PR Policy Checker'
  echo
  if [[ "${failures}" -eq 0 ]]; then
    echo "プロジェクトの CI/CD ポリシー要件を満たしています。(警告 ${warnings} 件)"
  else
    echo "必須項目に ${failures} 件の不足があります。PR の説明文を修正してください。(警告 ${warnings} 件)"
  fi
  echo
  echo '| | 項目 | 補足 |'
  echo '| :-: | :--- | :--- |'
  printf '%s\n' "${results[@]}"
  echo
  echo '警告 (⚠️) はジョブを失敗させません。判定は文字列一致による決定的な検査です。'
  echo "詳細は \`AGENTS.md\` と \`.github/PULL_REQUEST_TEMPLATE.md\` を参照してください。"
} >"${report_file:-/dev/stdout}"

if [[ "${failures}" -ne 0 ]]; then
  exit 1
fi
exit 0
