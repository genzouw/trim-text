#!/usr/bin/env bash
# Verify that every SHA-pinned `uses:` in the workflows points to an actual
# commit SHA, not an annotated tag object SHA. The latter cannot be resolved
# by GitHub Actions and produces a `startup_failure`.
set -euo pipefail

WORKFLOW_DIR="${1:-.github/workflows}"

if ! command -v gh >/dev/null 2>&1; then
  echo "::error::gh CLI is required" >&2
  exit 1
fi

shopt -s nullglob
files=("${WORKFLOW_DIR}"/*.yml "${WORKFLOW_DIR}"/*.yaml)
shopt -u nullglob

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No workflow files under ${WORKFLOW_DIR}."
  exit 0
fi

pin_regex='^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*[A-Za-z0-9._/-]+@[0-9a-f]{40}([[:space:]]|$)'
mapfile -t entries < <(
  grep -hE "${pin_regex}" "${files[@]}" |
    sed -E 's|^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*([A-Za-z0-9._/-]+)@([0-9a-f]{40}).*|\1 \2|' |
    sort -u
)

if [[ ${#entries[@]} -eq 0 ]]; then
  echo "No SHA-pinned actions found in ${WORKFLOW_DIR}."
  exit 0
fi

fail=0
declare -A checked
for entry in "${entries[@]}"; do
  full_repo="${entry%% *}"
  sha="${entry##* }"
  owner="${full_repo%%/*}"
  rest="${full_repo#*/}"
  repo="${rest%%/*}"
  key="${owner}/${repo}@${sha}"
  [[ "${full_repo}" == ./* ]] && continue
  [[ -n "${checked[${key}]:-}" ]] && continue
  checked[${key}]=1
  if gh api "repos/${owner}/${repo}/commits/${sha}" --silent >/dev/null 2>&1; then
    printf '  [OK]   %s\n' "${key}"
  else
    printf '  [FAIL] %s\n' "${key}" >&2
    echo "::error::${key} is not a valid commit SHA (likely an annotated tag object SHA)." >&2
    fail=1
  fi
done

if [[ ${fail} -ne 0 ]]; then
  cat >&2 <<'EOF'

One or more action pins reference SHAs that are NOT commit SHAs.
GitHub Actions cannot resolve annotated tag object SHAs — the workflow will
fail with `startup_failure`. Replace each broken SHA with the underlying
commit SHA:

  gh api repos/<owner>/<repo>/git/refs/tags/<tag> --jq '.object | "\(.type) \(.sha)"'

If the result is `tag <SHA>`, dereference it:

  gh api repos/<owner>/<repo>/git/tags/<SHA> --jq '.object.sha'

Use the resulting commit SHA in your workflow file.
EOF
  exit 1
fi

echo "All action pins reference valid commit SHAs."
