# Architecture Overview

This document explains the internal architecture of Relanote, from source code to audio output.

## System Architecture

<img src="/diagrams/architecture-overview.svg" alt="Relanote System Architecture" style="width: 100%; max-width: 800px; margin: 1rem 0;" />

## Crate Structure

Relanote is organized as a Cargo workspace with the following crates:

| Crate | Purpose |
|-------|---------|
| `relanote_lexer` | Tokenizes source code into tokens |
| `relanote_ast` | Defines AST (Abstract Syntax Tree) types |
| `relanote_parser` | Parses tokens into AST |
| `relanote_eval` | Evaluates AST and produces music values |
| `relanote_stdlib` | Standard library (prelude, scales, chords, synth presets) |
| `relanote_render` | Renders music values to MIDI/JSON formats |
| `relanote_format` | Code formatter (pretty printer) |
| `relanote_wasm` | WebAssembly bindings for browser use |
| `relanote_cli` | Command-line interface |

## Compilation Pipeline

### 1. Lexical Analysis (Lexer)

The lexer transforms source code into tokens:

```
Source: "let melody = | C4 E4 G4 |"

Tokens:
  ├─ Keyword(Let)
  ├─ Identifier("melody")
  ├─ Operator(Eq)
  ├─ Pipe
  ├─ Pitch(C4)
  ├─ Pitch(E4)
  ├─ Pitch(G4)
  └─ Pipe
```

### 2. Parsing (Parser)

The parser constructs an Abstract Syntax Tree:

```
AST:
  └─ LetBinding
       ├─ name: "melody"
       └─ value: Block
                   └─ notes: [C4, E4, G4]
```

### 3. Evaluation (Evaluator)

The evaluator transforms AST into concrete music values:

```
Value:
  └─ Block {
       notes: [
         Note { pitch: 60, duration: 1.0, velocity: 80 },
         Note { pitch: 64, duration: 1.0, velocity: 80 },
         Note { pitch: 67, duration: 1.0, velocity: 80 },
       ],
       synth: None,
       tempo: 120,
     }
```

### 4. Rendering (Render)

The renderer converts music values to playable formats:

- **JSON** - For WebAudio playback in browser
- **MIDI** - For DAW integration and hardware synths

## Data Flow Example

Here's how a simple melody flows through the system:

```rela
; Input .rela file
scale Major = { R, M2, M3, P4, P5, M6, M7 }
let melody = | <1> <3> <5> | |> voice Lead
melody
```

```
┌────────────────────────────────────────────────────────────────┐
│ 1. Parser reads scale definition and melody                    │
└────────────────────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────────┐
│ 2. Evaluator resolves <1> <3> <5> to actual pitches            │
│    using the Major scale intervals                              │
│    <1> → R   → root pitch (e.g., C4 = MIDI 60)                 │
│    <3> → M3  → root + 4 semitones (e.g., E4 = MIDI 64)         │
│    <5> → P5  → root + 7 semitones (e.g., G4 = MIDI 67)         │
└────────────────────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────────┐
│ 3. Evaluator applies "Lead" synth to the block                 │
│    Block.synth = SynthValue { osc: Saw, env: ..., ... }        │
└────────────────────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────────┐
│ 4. Renderer produces JSON for WebAudio                         │
│    { notes: [...], synth: { osc: "saw", ... }, tempo: 120 }    │
└────────────────────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────────┐
│ 5. WebAudio creates OscillatorNode and plays the sound         │
└────────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### Pure Functional Design

Relanote is designed as a pure functional language:
- All values are immutable
- Functions have no side effects
- Music is expressed as data transformations

### Relative Intervals

Music is expressed using relative intervals rather than absolute pitches:
- `<1>`, `<3>`, `<5>` - Scale degrees
- `M3`, `P5`, `m7` - Interval names
- This allows easy transposition and key changes

### Pipe-Based Composition

The pipe operator `|>` enables fluent composition:

```rela
melody |> transpose M3 |> voice Lead |> volume 0.8
```

This is equivalent to nested function calls:
```
volume(voice(transpose(melody, M3), Lead), 0.8)
```

### WebAssembly for Browser

The entire Rust backend compiles to WebAssembly, enabling:
- Full evaluation in the browser
- No server required for playback
- Consistent behavior across platforms

## File Types

| Extension | Purpose |
|-----------|---------|
| `.rela` | Relanote source files |
| `.mid` | Exported MIDI files |
| `.json` | Internal render format |
