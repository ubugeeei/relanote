<p align="center">
  <img src="assets/og-image.svg" alt="relanote — music as a function">
</p>

<p align="center">
  <a href="https://github.com/ubugeeei/relanote/actions"><img src="https://github.com/ubugeeei/relanote/workflows/CI/badge.svg" alt="CI"></a>
  <a href="https://github.com/ubugeeei/relanote/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
</p>

<p align="center">
  <a href="#what-is-relanote">What</a> •
  <a href="#example">Example</a> •
  <a href="#quick-start">Quick start</a> •
  <a href="#playground">Playground</a> •
  <a href="#documentation">Docs</a>
</p>

---

## What is relanote?

**relanote** is a pure functional, statically-typed language for music
where **everything is relative**. Pitch is relative: a melody is made
from scale-degree references, not absolute note names. Rhythm is
relative: a block divides its slot among the notes inside it. Chords are
intervals over a root, sections are blocks over a beat-grid, and parts
are sections over instruments. Change the key, scale, or tempo, and the
shape stays intact.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <3> <5> <3> <1> |

theme |> transpose P5 |> repeat 2
```

## Features

- **Pitch is relative.** `<1> <3> <5>` works in every key, every mode,
  and every scale.
- **Rhythm is relative.** `| a b c d |` shares its slot equally among
  four notes; `| a b |` gives two notes the same slot at half the
  density.
- **Pure and typed.** Immutable values, first-class functions, and
  Hindley-Milner inference keep musical transformations predictable.
- **Pipes for composition.** `theme |> transpose P5 |> repeat 2 |> reverb 0.3`
  builds pieces by composing small functions.
- **MoonBit end to end.** The compiler pipeline, CLI, MIDI renderer, LSP
  entry point, and playground bridge live in `moonbit/`.

## Quick Start

Install MoonBit once:

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
export PATH="$HOME/.moon/bin:$PATH"
```

Then build and test the workspace:

```bash
git clone https://github.com/ubugeeei/relanote.git
cd relanote
cd moonbit

moon check
moon test
moon run cmd/relanote -- help
```

The root `package.json` is a thin task alias layer around MoonBit:

```bash
pnpm check
pnpm test
pnpm cli -- run examples/tutorials/01_hello.rela
pnpm web:build
```

If you use Nix, `nix develop` provides Node, pnpm, and helper tools. The
MoonBit installer above is still the source for the compiler toolchain.

## Example

### Simple Melody

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let twinkle = | <1> <1> <5> <5> <6> <6> <5> - <4> <4> <3> <3> <2> <2> <1> - |

twinkle
```

### Chord Progression

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

chord Tonic = [ R, M3, P5 ]

let progression = | <1> <4> <5> <1> |

progression
```

### Transformations

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <2> <3> <4> |

let repeated = melody |> repeat 2
let reversed = melody |> reverse
let higher = melody |> transpose P5

repeated
```

## Documentation

- [Introduction](docs/guide/introduction.md)
- [Installation](docs/guide/installation.md)
- [Quick Start](docs/guide/quick-start.md)
- [Tutorial](docs/tutorial/getting-started.md)
- [CLI Reference](docs/reference/cli.md)

## Playground

The playground view is authored with
[Vapor Moon](https://github.com/ubugeeei/vapor-moon) as
`moonbit/web/App.mbtv`. The callable bridge functions for diagnostics,
formatting, evaluation, and MIDI rendering live in `moonbit/web/playground.mbt`.

Build the component snapshot with:

```bash
pnpm web:build
```

## Project Structure

```text
relanote/
├── moonbit/
│   ├── cmd/relanote/        # CLI entry point
│   ├── relanote_core/       # source, spans, diagnostics
│   ├── relanote_lexer/      # tokenizer
│   ├── relanote_ast/        # AST data types
│   ├── relanote_parser/     # parser
│   ├── relanote_hir/        # high-level IR
│   ├── relanote_resolver/   # module resolution
│   ├── relanote_types/      # type system
│   ├── relanote_eval/       # evaluator
│   ├── relanote_stdlib/     # embedded prelude
│   ├── relanote_format/     # formatter
│   ├── relanote_lsp/        # LSP entry point
│   ├── relanote_render/     # MIDI rendering
│   └── web/                 # Vapor Moon view + playground bridge
├── docs/                    # Markdown documentation
├── editors/vscode/          # VS Code extension package
└── examples/                # Example programs
```

## Development

```bash
pnpm check
pnpm test
pnpm fmt
pnpm web:build
```

`pnpm tasks` lists every root task.

## License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ♪ by <a href="https://github.com/ubugeeei">ubugeeei</a>
</p>
