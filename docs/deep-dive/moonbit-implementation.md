# Relanote MoonBit workspace

The repository root is the Relanote implementation.

## Packages

| Package             | Responsibility                                      |
| ------------------- | --------------------------------------------------- |
| `core`     | source files, spans, diagnostics, reports           |
| `lexer`    | token kinds and tokenizer                           |
| `ast`      | program, item, expression, music, and sound nodes    |
| `stdlib`   | embedded prelude `.rela` modules                    |
| `types`    | type ADT, schemes, contexts, unification, checker    |
| `hir`      | lowered representation                              |
| `parser`   | parser API and parse diagnostics                    |
| `resolver` | module loading and name resolution                  |
| `eval`     | evaluator and runtime values                        |
| `format`   | formatter                                           |
| `render`   | MIDI renderer                                       |
| `lsp`      | LSP framing, dispatch, and server entry point       |
| `cmd`      | CLI entry point                                     |
| `studio`            | Vapor Moon view and playground bridge               |

Regenerate the stdlib embedding after editing the `.rela` sources:

```bash
bash scripts/gen_stdlib.sh
```

## Build

```bash
moon check
moon test
moon run src/cmd -- help
moon run .mooncakes/ubugeeei/vapor_moon/src/cmd/vapor_moon -- compile src/studio/App.mbtv
```
