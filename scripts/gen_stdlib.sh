#!/usr/bin/env bash
# Regenerate src/stdlib/prelude_data_*.mbt from the prelude
# `.rela` files. Run from the repository root or from anywhere; the script
# always resolves paths relative to its own location.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stdlib_dir="$(cd "$script_dir/../src/stdlib" && pwd)"
prelude_dir="$stdlib_dir/prelude"
rm -f "$stdlib_dir"/prelude_data_*.mbt "$stdlib_dir/prelude_data.mbt"

for f in "$prelude_dir"/*.rela; do
  base=$(basename "$f" .rela)
  name=$(printf '%s' "$base" | tr '[:lower:]' '[:upper:]')
  out="$stdlib_dir/prelude_data_${base}.mbt"
  {
  echo "// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh."
  echo "// To regenerate after editing the .rela sources, run:"
  echo "//   bash scripts/gen_stdlib.sh"
  echo "// Manual edits will be lost."
  echo
  echo "///|"
  echo "/// Embedded source of \`prelude/${base}.rela\`."
  printf 'pub const %s : String =\n' "$name"
  awk 'BEGIN{first=1} {
    if (first) { first=0; printf "  #|%s", $0 }
    else        { printf "\n  #|%s", $0 }
  } END { print "" }' "$f"
  } > "$out"
  echo "wrote $out"
done

oversized=$(wc -l "$stdlib_dir"/prelude_data_*.mbt | awk '$2 != "total" && $1 > 250 { print $2 }')
if [ -n "$oversized" ]; then
  echo "generated prelude chunk exceeds 250 lines:" >&2
  echo "$oversized" >&2
  exit 1
fi
