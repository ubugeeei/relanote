# Types Reference

Relanote uses static typing with Hindley-Milner type inference.

## Primitive Types

| Type | Description | Example |
|------|-------------|---------|
| `Unit` | No value | `()` |
| `Bool` | Boolean | `true`, `false` |
| `Int` | Integer | `42` |
| `Float` | Floating point | `3.14` |
| `String` | Text | `"hello"` |

## Music Types

| Type | Description | Example |
|------|-------------|---------|
| `Interval` | Musical interval | `P5`, `M3`, `m7` |
| `Scale` | Collection of intervals | `scale { R, M2, M3... }` |
| `Chord` | Simultaneous intervals | `chord [ R, M3, P5 ]` |
| `Block` | Sequence of notes | `\| <1> <2> <3> \|` |
| `Part` | Instrument track | `part "Piano" [...]` |
| `Section` | Song section | `section "Verse" ...` |
| `Song` | Complete composition | `render ...` |

## Synth Types

| Type | Description | Example |
|------|-------------|---------|
| `Synth` | Synthesizer definition | `synth Lead = {...}` |
| `Oscillator` | Waveform type | `Sine`, `Square`, `Saw` |
| `Filter` | Filter type | `LowPass(1000, 0.5)` |
| `Envelope` | ADSR envelope | `{ A: 0.01, D: 0.1, S: 0.7, R: 0.2 }` |

## Compound Types

### Arrays

```rela
[1, 2, 3]           ; [Int]
["a", "b", "c"]     ; [String]
[R, M3, P5]         ; [Interval]
```

### Functions

```rela
Int -> Int              ; Function from Int to Int
(Int, Int) -> Int       ; Function with two Int parameters
Block -> Block          ; Block transformation
```

### Tuples

```rela
(Int, String)           ; Pair of Int and String
(Interval, Interval)    ; Pair of intervals
```

## Type Inference

Types are inferred automatically:

```rela
let x = 42              ; x: Int
let s = "hello"         ; s: String
let i = P5              ; i: Interval
let f = \n -> n + 1     ; f: Int -> Int
```

## Type Annotations

Explicit annotations are optional but sometimes helpful:

```rela
let x: Int = 42
let transpose: Interval -> Block -> Block = ...
```

## Type Errors

The type checker catches errors at compile time:

```rela
; Error: cannot add Scale to Interval
let wrong = Major + P5

; Error: type mismatch
let also_wrong: Int = "hello"

; Error: cannot apply Scale to Int
Major |> 42
```

## Type Classes (Traits)

Some operations work on multiple types:

### Eq (Equality)

```rela
P5 == P5    ; true
M3 != m3    ; true
```

### Add

```rela
; Intervals can be added
P5 + M3     ; M7

; Blocks can be concatenated
| <1> | ++ | <2> |   ; | <1> <2> |
```

### Show

All values can be displayed:

```rela
; In the REPL or debug output
P5          ; "P5 (7 semitones)"
Major       ; "Scale { R, M2, M3, P4, P5, M6, M7 }"
```

## Generic Functions

Some built-in functions are generic:

```rela
; map works on any Block content
map: (a -> b) -> [a] -> [b]

; repeat works on any Block
repeat: Int -> Block -> Block
```
