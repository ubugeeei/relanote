# CLI reference

`relanote` is one binary with a small set of subcommands. Run it
against a `.rela` file or feed source on stdin.

## Install

From source:

```bash
cargo install --path crates/relanote_cli
relanote --version
```

Or in the Nix dev shell, which always picks the right Rust:

```bash
nix develop
cargo install --path crates/relanote_cli
```

## Subcommands

| Command | What it does |
| --- | --- |
| `relanote parse <file>` | Parse and print the AST. |
| `relanote check <file>` | Type-check; exit non-zero on error. |
| `relanote run <file>` | Evaluate the program. Prints the top-level value. |
| `relanote fmt <file>` | Pretty-print the file to stdout. |
| `relanote render <file> -o out.mid` | Render to a standard MIDI file. |
| `relanote lsp` | Start the LSP server on stdio. |
| `relanote help` | Print usage. |

`<file>` defaults to stdin when omitted, so `cat foo.rela \| relanote check` works.

## Examples

```bash
# Run a file and print the result.
relanote run examples/tutorials/01_hello.rela

# Render to MIDI and open in any DAW.
relanote render examples/showcases/showcase_floating_points.rela -o fp.mid

# Type-check before committing.
relanote check src/main.rela

# Format in place.
relanote fmt src/main.rela > src/main.rela.tmp && mv src/main.rela.tmp src/main.rela
```

## Editor integration

`relanote lsp` reads JSON-RPC frames from stdin and writes diagnostics
+ completions to stdout. Configure your editor to launch
`relanote lsp` as a language server for `.rela` files and you get:

- Real-time parse errors.
- Hover-doc for builtins and presets.
- Symbol completion for names in scope.
- Go-to-definition for `let` / `scale` / `chord` / `synth` / `effect` declarations.

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success. |
| 1 | Error (parse, type, IO, or runtime). |
| 2 | Usage error (bad flags). |

## Status

The CLI surface above is locked in. Subcommands that the MoonBit port
hasn't finished — `run`, `render`, `lsp` — return early with an
informational diagnostic until the evaluator / renderer / LSP land.
The Rust crate (`crates/relanote_cli`) implements every subcommand
end-to-end today.
