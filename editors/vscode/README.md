# Relanote for Visual Studio Code

Language support for [Relanote](https://github.com/ubugeeei/relanote) - a pure functional music notation language.

## Features

- **Syntax Highlighting**: Full TextMate grammar for `.rela` files
- **IntelliSense**: Code completion for keywords, intervals, and built-in functions
- **Diagnostics**: Real-time error checking for syntax and type errors
- **Formatting**: Document formatting support
- **Hover Information**: Documentation on hover for keywords and intervals
- **Code Snippets**: Quick templates for common patterns

## Requirements

- Relanote CLI installed and available in PATH
- Run `cargo install --path crates/relanote_cli` from the relanote repository or install from crates.io when available

## Extension Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `relanote.lsp.enabled` | `true` | Enable/disable the language server |
| `relanote.lsp.path` | `"relanote"` | Path to the relanote CLI executable |

## Commands

| Command | Description |
|---------|-------------|
| `Relanote: Restart Language Server` | Restart the LSP server |

## Syntax Examples

```rela
-- Define a scale
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Define a chord
chord Tonic = [ R, M3, P5 ]

-- Create a melody with articulations
let melody = | <1>^ <2> <3>* <4> <5>~ |

-- Transform and compose
let phrase = melody |> repeat(2) |> transpose(P5)
```

## Development

```bash
# Install dependencies
npm install

# Compile
npm run compile

# Watch mode
npm run watch

# Package extension
npm run package
```

## Links

- [Relanote Repository](https://github.com/ubugeeei/relanote)
- [Report Issues](https://github.com/ubugeeei/relanote/issues)

## License

MIT
