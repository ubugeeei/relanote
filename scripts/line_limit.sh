#!/usr/bin/env bash
set -euo pipefail

fail=0
while IFS= read -r file; do
  case "$file" in
    pnpm-lock.yaml) continue ;;
  esac
  [ -f "$file" ] || continue
  lines="$(wc -l < "$file")"
  if [ "$lines" -gt 250 ]; then
    echo "$lines $file"
    fail=1
  fi
done < <(
  git ls-files \
    '*.mbt' '*.mbtv' '*.sh' '*.json' '*.yml' '*.yaml' \
    '*.js' '*.mjs' '*.css' '*.html'
)

exit "$fail"
