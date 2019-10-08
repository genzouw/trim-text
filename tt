#!/usr/bin/env bash
set -o errexit   # エラーが発生した場合はシェルを終了
set -o nounset   # 未定義の変数を利用禁止
set -o noclobber # リダイレクトによる上書禁止

opts='t:b:l:r:'

usage() {
  echo -n "${0}"
  echo "${opts}" | sed 's/\([a-z]\)/ -\1/g' | sed 's/\-\([a-z]\):/-\1 \U\1\E/g'
  exit 1
}

while getopts ":${opts}" opt; do
  case "${opt}" in
    t)
      TRIM_TOP="${OPTARG}"
      ;;
    b)
      TRIM_BOTTOM="${OPTARG}"
      ;;
    l)
      TRIM_LEFT="${OPTARG}"
      ;;
    r)
      TRIM_RIGHT="${OPTARG}"
      ;;
    : | \?)
      usage
      ;;
  esac
done

shift $((OPTIND - 1))

cat \
  | sed "s/^.\{${TRIM_LEFT:-0}\}//; s/.\{${TRIM_RIGHT:-0}\}\$//;" \
  | tail -n +$((${TRIM_TOP:-0} + 1)) \
  | head -n -${TRIM_BOTTOM:-0} \
  ;
