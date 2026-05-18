#!/usr/bin/env bash
# Regenerate moonbit/relanote_stdlib/prelude_data.mbt from the prelude
# `.rela` files. Run from the repository root or from anywhere; the script
# always resolves paths relative to its own location.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stdlib_dir="$(cd "$script_dir/../relanote_stdlib" && pwd)"
prelude_dir="$stdlib_dir/prelude"
out="$stdlib_dir/prelude_data.mbt"

{
  echo "// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh."
  echo "// To regenerate after editing the .rela sources, run:"
  echo "//   bash moonbit/scripts/gen_stdlib.sh"
  echo "// Manual edits will be lost."
  echo
  for f in "$prelude_dir"/*.rela; do
    base=$(basename "$f" .rela)
    name=$(printf '%s' "$base" | tr '[:lower:]' '[:upper:]')
    echo "///|"
    echo "/// Embedded source of \`prelude/${base}.rela\`."
    printf 'pub const %s : String =\n' "$name"
    awk 'BEGIN{first=1} {
      if (first) { first=0; printf "  #|%s", $0 }
      else        { printf "\n  #|%s", $0 }
    } END { print "" }' "$f"
    echo
  done
} > "$out"

echo "wrote $out"
