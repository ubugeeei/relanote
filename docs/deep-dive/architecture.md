# Architecture Overview

This document explains the internal architecture of Relanote, from source code to audio output.

## System Architecture

<img src="/diagrams/architecture-overview.svg" alt="Relanote System Architecture" style="width: 100%; max-width: 800px; margin: 1rem 0;" />

## Package Structure

Relanote is organized as MoonBit packages:

| Package | Purpose |
|---------|---------|
| `core` | Source files, spans, diagnostics, reports |
| `lexer` | Tokenizes source code into tokens |
| `ast` | Defines AST (Abstract Syntax Tree) types |
| `parser` | Parses tokens into AST |
| `hir` | Holds the lowered representation |
| `resolver` | Resolves modules and names |
| `types` | Infers and checks types |
| `eval` | Evaluates AST and produces music values |
| `stdlib` | Standard library prelude, scales, chords, synth presets |
| `render` | Renders music values to MIDI bytes |
| `format` | Code formatter |
| `lsp` | Editor protocol framing and dispatch |
| `cmd` | Command-line interface |
| `studio` | Vapor Moon playground view and bridge |

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

### Studio

The Vapor Moon studio calls the same MoonBit bridge functions as the
CLI pipeline:
- Diagnostics and formatting share parser output
- Playback and export share evaluator and MIDI rendering
- The UI stays thin around the language packages

## File Types

| Extension | Purpose |
|-----------|---------|
| `.rela` | Relanote source files |
| `.mid` | Exported MIDI files |
| `.json` | Internal render format |
