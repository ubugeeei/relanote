# Language Design Deep Dive

This document explores the design philosophy and implementation of the Relanote language.

## Design Philosophy

### "Everything is Relative"

The core principle of Relanote is that music should be expressed in relative terms:

```rela
; Traditional approach: absolute pitches
| C4 E4 G4 | → | D4 F#4 A4 |  ; Must rewrite everything to transpose

; Relanote approach: relative intervals
scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> <3> <5> | |> transpose M2  ; Just apply transformation
```

This makes music more portable and easier to manipulate.

### Functional Programming

Relanote embraces functional programming:

```
┌─────────────────────────────────────────────────────────────┐
│                    Functional Benefits                       │
├─────────────────────────────────────────────────────────────┤
│ Immutability   │ Values never change, safe composition      │
│ Pure Functions │ No side effects, predictable behavior      │
│ Composition    │ Build complex from simple with pipes       │
│ Declarative    │ Describe what, not how                     │
└─────────────────────────────────────────────────────────────┘
```

## Interval System

### Interval Names

Relanote uses standard music theory interval names:

| Symbol | Name | Semitones |
|--------|------|-----------|
| R | Root (Unison) | 0 |
| m2 | Minor 2nd | 1 |
| M2 | Major 2nd | 2 |
| m3 | Minor 3rd | 3 |
| M3 | Major 3rd | 4 |
| P4 | Perfect 4th | 5 |
| A4 / d5 | Tritone | 6 |
| P5 | Perfect 5th | 7 |
| m6 | Minor 6th | 8 |
| M6 | Major 6th | 9 |
| m7 | Minor 7th | 10 |
| M7 | Major 7th | 11 |
| P8 | Octave | 12 |

### Quality Prefixes

```
P = Perfect   (for unisons, 4ths, 5ths, octaves)
M = Major     (for 2nds, 3rds, 6ths, 7ths)
m = minor     (for 2nds, 3rds, 6ths, 7ths)
A = Augmented (raised by half step)
d = diminished (lowered by half step)
```

### Interval Arithmetic

Intervals can be modified with `+` and `-`:

```rela
M3+   ; Major 3rd raised by half step (= 5 semitones)
P5-   ; Perfect 5th lowered by half step (= 6 semitones)
M2++  ; Major 2nd raised twice (= 4 semitones)
```

## Scale Degrees

Scale degrees reference positions within a scale:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; In C Major:
<1> → C  (degree 1 = R = root)
<2> → D  (degree 2 = M2 = major 2nd from root)
<3> → E  (degree 3 = M3 = major 3rd from root)
<4> → F  (degree 4 = P4 = perfect 4th from root)
<5> → G  (degree 5 = P5 = perfect 5th from root)
<6> → A  (degree 6 = M6 = major 6th from root)
<7> → B  (degree 7 = M7 = major 7th from root)
<8> → C' (degree 8 = octave up from root)
```

### How Scale Resolution Works

```
Scale Resolution Process:

  scale Major = { R, M2, M3, P4, P5, M6, M7 }
                  ↑   ↑   ↑   ↑   ↑   ↑   ↑
                  1   2   3   4   5   6   7

  Note <3> in key of C:
  ┌─────────────────────────────────────────────────────────┐
  │ 1. Look up degree 3 in scale → M3 (Major 3rd)           │
  │ 2. Get current root note → C4 (MIDI 60)                 │
  │ 3. Apply interval → 60 + 4 semitones = 64 (E4)          │
  └─────────────────────────────────────────────────────────┘
```

## Type System

Relanote is statically typed with the following types:

### Primitive Types

| Type | Description | Example |
|------|-------------|---------|
| `Int` | Integer number | `42`, `-7` |
| `Float` | Floating point | `3.14`, `0.5` |
| `Bool` | Boolean | `true`, `false` |
| `String` | Text | `"hello"` |

### Music Types

| Type | Description | Example |
|------|-------------|---------|
| `Interval` | Relative pitch | `M3`, `P5`, `m7` |
| `Pitch` | Absolute pitch | `C4`, `F#5`, `Bb3` |
| `Duration` | Note length | `:4` (quarter), `:8` (eighth) |
| `Block` | Musical phrase | `\| C4 E4 G4 \|` |
| `Scale` | Set of intervals | `{ R, M2, M3, ... }` |
| `Chord` | Simultaneous notes | `[ R, M3, P5 ]` |
| `Synth` | Sound definition | `{ osc: Saw, ... }` |

### Compound Types

| Type | Description | Example |
|------|-------------|---------|
| `Array<T>` | List of values | `[1, 2, 3]` |
| `Tuple` | Fixed-size group | `(M3, P5)` |
| `Function` | Callable | `\x -> x + 1` |

## Block Syntax

Blocks are the fundamental unit of music:

```
┌───────────────────────────────────────────────────────────┐
│    Block Anatomy                                           │
├───────────────────────────────────────────────────────────┤
│                                                           │
│    | C4 E4:8 G4' - [C4 E4 G4] |                           │
│    ↑  ↑   ↑   ↑  ↑     ↑      ↑                          │
│    │  │   │   │  │     │      └─ Block end               │
│    │  │   │   │  │     └─ Chord (simultaneous)           │
│    │  │   │   │  └─ Rest                                 │
│    │  │   │   └─ Staccato articulation                   │
│    │  │   └─ Duration modifier (eighth note)             │
│    │  └─ Note                                            │
│    └─ Block start                                        │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### Note Modifiers

| Modifier | Syntax | Description |
|----------|--------|-------------|
| Duration | `:n` | Note length (1=whole, 4=quarter, 8=eighth) |
| Staccato | `'` | Short, detached |
| Accent | `^` | Emphasized |
| Octave up | `++` | Raise octave |
| Octave down | `--` | Lower octave |

## Pipe Operator

The pipe operator `|>` is central to Relanote's design:

```
┌─────────────────────────────────────────────────────────────┐
│    Pipe Operator Transformation                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│    melody |> transpose M3 |> voice Lead |> volume 0.8       │
│                                                             │
│    ┌───────┐    ┌────────────┐    ┌──────────┐    ┌──────┐ │
│    │ melody │ →  │ transpose  │ →  │  voice   │ →  │volume│ │
│    │       │    │    M3      │    │   Lead   │    │ 0.8  │ │
│    └───────┘    └────────────┘    └──────────┘    └──────┘ │
│        ↓              ↓                ↓              ↓     │
│    Original      +4 semitones      Synth set      Quieter  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Evaluation

`x |> f` is transformed to `f(x)` during evaluation:

```
melody |> transpose M3 |> voice Lead

; Desugars to:
voice(transpose(melody, M3), Lead)
```

## Parts and Sections

For organizing larger compositions:

```rela
let song = section "Verse" {
  part "Lead" {
    | <1> <3> <5> <8> |
  } |> voice Lead

  part "Bass" {
    | <1> - <5> - |
  } |> voice FatBass

  part "Drums" {
    | R - R R |
  } |> voice Kick
}
```

### Structure

```
┌─────────────────────────────────────────────────────────────┐
│  Section "Verse"                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Part "Lead"                                           │   │
│  │ ┌────────────────────────────────────────────────┐   │   │
│  │ │ Block: | <1> <3> <5> <8> |                      │   │   │
│  │ └────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Part "Bass"                                           │   │
│  │ ┌────────────────────────────────────────────────┐   │   │
│  │ │ Block: | <1> - <5> - |                         │   │   │
│  │ └────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Part "Drums"                                          │   │
│  │ ┌────────────────────────────────────────────────┐   │   │
│  │ │ Block: | R - R R |                             │   │   │
│  │ └────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Functions

### Built-in Functions

Relanote provides many built-in functions:

| Category | Functions |
|----------|-----------|
| Pitch | `transpose`, `invert`, `octave` |
| Time | `tempo`, `duration`, `stretch` |
| Synth | `voice`, `cutoff`, `resonance`, `adsr` |
| Mix | `volume`, `pan`, `reverb` |
| Structure | `repeat`, `reverse`, `concat` |

### User-Defined Functions

Lambda syntax for custom functions:

```rela
; Single parameter
let double = \x -> x * 2

; Multiple parameters
let add = \x y -> x + y

; With blocks
let harmonize = \melody -> melody ++ (melody |> transpose M3)
```

## Control Flow

### Conditional Expressions

```rela
let result = if condition then value1 else value2
```

### Pattern Matching

```rela
let describe = \interval ->
  match interval with
  | M3 -> "major third"
  | m3 -> "minor third"
  | P5 -> "perfect fifth"
  | _ -> "other interval"
```

## Evaluation Model

### Lazy vs Eager

Most operations are eager, but some constructs are lazy:

```
Eager: values evaluated immediately
  let x = 1 + 2  ; x = 3 immediately

Lazy: values evaluated when needed
  if condition then expensive_computation else default
  ; expensive_computation only evaluated if condition is true
```

### Environment and Scope

```
Global Scope
├── Prelude (scales, chords, synths)
├── User definitions
└── Current file definitions

Block Scope
├── let bindings
└── Function parameters

Closure Scope
└── Captured variables from enclosing scope
```

## Abstract Syntax Tree

The parser produces an AST that represents the program structure:

```
Program
├── Item::ScaleDef
│   ├── name: "Major"
│   └── intervals: [R, M2, M3, P4, P5, M6, M7]
├── Item::Let
│   ├── name: "melody"
│   └── value: Expr::Block
│             └── notes: [...]
└── Item::Expr
    └── Expr::Pipe
        ├── left: Expr::Var("melody")
        └── right: Expr::Call
                   ├── func: "voice"
                   └── args: [Expr::Var("Lead")]
```

## Error Handling

### Parse Errors

```
Error: Unexpected token at line 3, column 5
  |
3 | let x =
  |       ^ Expected expression after '='
```

### Type Errors

```
Error: Type mismatch at line 5
  Expected: Block
  Found: Int

5 | | C4 E4 G4 | |> transpose 3
                              ^ transpose expects an Interval, got Int
```

### Runtime Errors

```
Error: Scale degree out of range at line 7
  Scale has 7 degrees, but degree 9 was requested

7 | | <9> |
      ^^^ Invalid scale degree
```
