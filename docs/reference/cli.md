# CLI Reference

`relanote` is one MoonBit command with a small set of subcommands. Run
it against a `.rela` file from the repository root:

```bash
moon run src/cmd -- help
```

From the repository root you can also use the Vite Task alias:

```bash
vp run cli help
```

## Subcommands

| Command | What it does |
| --- | --- |
| `relanote parse <file>` | Parse and print diagnostics. |
| `relanote check <file>` | Parse and type-check the file. |
| `relanote run <file>` | Evaluate the program. |
| `relanote fmt <file>` | Pretty-print the file to stdout. |
| `relanote render <file> [output.mid]` | Render to a standard MIDI file. |
| `relanote lsp` | Start the LSP server on stdio. |
| `relanote help` | Print usage. |

## Examples

```bash
# Run a file and print the result.
moon run src/cmd -- run examples/tutorials/01_hello.rela

# Render to MIDI.
moon run src/cmd -- render examples/tutorials/01_hello.rela output.mid

# Type-check before committing.
moon run src/cmd -- check examples/tutorials/01_hello.rela

# Format and write through a temporary file.
moon run src/cmd -- fmt examples/tutorials/01_hello.rela > /tmp/hello.rela
```

## Editor Integration

`relanote lsp` reads JSON-RPC frames from stdin and writes responses to
stdout. Configure your editor to launch it as a language server for
`.rela` files.

## Exit Codes

| Code | Meaning |
| --- | --- |
| 0 | Success. |
| 1 | Error in a pipeline phase. |
| 2 | Usage error. |
