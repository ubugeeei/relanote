# Relanote MoonBit workspace

This directory is the Relanote implementation.

## Packages

| Package             | Responsibility                                      |
| ------------------- | --------------------------------------------------- |
| `relanote_core`     | source files, spans, diagnostics, reports           |
| `relanote_lexer`    | token kinds and tokenizer                           |
| `relanote_ast`      | program, item, expression, music, and sound nodes    |
| `relanote_stdlib`   | embedded prelude `.rela` modules                    |
| `relanote_types`    | type ADT, schemes, contexts, unification, checker    |
| `relanote_hir`      | lowered representation                              |
| `relanote_parser`   | parser API and parse diagnostics                    |
| `relanote_resolver` | module loading and name resolution                  |
| `relanote_eval`     | evaluator and runtime values                        |
| `relanote_format`   | formatter                                           |
| `relanote_render`   | MIDI renderer                                       |
| `relanote_lsp`      | LSP framing, dispatch, and server entry point       |
| `cmd/relanote`      | CLI entry point                                     |
| `web`               | Vapor Moon view and playground bridge               |

Regenerate the stdlib embedding after editing the `.rela` sources:

```bash
bash scripts/gen_stdlib.sh
```

## Build

```bash
moon check
moon test
moon run cmd/relanote -- help
moon run .mooncakes/ubugeeei/vapor_moon/src/cmd/vapor_moon -- compile web/App.mbtv
```
