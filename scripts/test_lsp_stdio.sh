#!/usr/bin/env bash
set -euo pipefail

frame() {
  local body="$1"
  local size
  size=$(printf '%s' "$body" | wc -c | tr -d ' ')
  printf 'Content-Length: %s\r\n\r\n%s' "$size" "$body"
}

uri='file:///tmp/relanote-lsp-smoke.rela'
source='let x 1'
init='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'
open='{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"'"$uri"'","languageId":"relanote","version":1,"text":"'"$source"'"}}}'
diag='{"jsonrpc":"2.0","id":2,"method":"textDocument/diagnostic","params":{"textDocument":{"uri":"'"$uri"'"}}}'
fmt='{"jsonrpc":"2.0","id":3,"method":"textDocument/formatting","params":{"textDocument":{"uri":"'"$uri"'"}}}'
shutdown='{"jsonrpc":"2.0","id":4,"method":"shutdown"}'
exit_note='{"jsonrpc":"2.0","method":"exit"}'

out=$(
  {
    frame "$init"
    frame "$open"
    frame "$diag"
    frame "$fmt"
    frame "$shutdown"
    frame "$exit_note"
  } | moon run cmd/relanote -- lsp
)

[[ "$out" == *'"id":1'*'"capabilities"'* ]]
[[ "$out" == *'"method":"textDocument/publishDiagnostics"'* ]]
[[ "$out" == *'"id":2'*'"kind":"full"'* ]]
[[ "$out" == *'"id":3'*'"newText"'* ]]
[[ "$out" == *'"id":4'*'"result":null'* ]]
