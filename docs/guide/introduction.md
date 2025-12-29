# What is Relanote?

Relanote is a **pure functional**, **statically-typed** programming language designed specifically for describing music. Unlike traditional notation or MIDI programming, Relanote uses **relative intervals** as its foundation, making transposition, modulation, and musical transformations natural and effortless.

## Why Relative Intervals?

Traditional music notation and most programming approaches use absolute pitches (C4, D4, E4...). This creates problems:

- **Transposition requires rewriting** - Moving a melody up a step means changing every note
- **Modal thinking is awkward** - Scale degrees are fundamental to music theory but secondary in absolute systems
- **Patterns are obscured** - A "I-IV-V progression" looks different in every key

Relanote solves these by making intervals first-class:

```rela
-- Define a scale
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- This melody works in ANY key
let melody = | <1> <3> <5> <3> <1> |

-- Transform with builtins
let transformed = melody |> transpose(P5)

transformed
```

## Functional Approach

Relanote embraces functional programming principles:

### Immutability

Values never change. Transformations create new values:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let original = | <1> <2> <3> |
let reversed = original |> reverse  -- original unchanged
```

### First-Class Functions

Functions are values. Pass them around, compose them:

```rela
let transform = transpose(M3) >> reverse >> repeat(2)
melody |> transform
```

### Pure Functions

No side effects. Same input always produces same output:

```rela
let doubled = melody |> map(\n -> n + P8)
```

## Static Typing

Relanote catches errors before you hear them:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Type error: can't add a Scale to an Interval
let wrong = Major + P5  -- Compile error

-- Correct: transpose the scale
let correct = Major |> transpose(P5)
```

## What Can You Build?

- **Melodies** using scale degrees and intervals
- **Chord progressions** with functional harmony
- **Multi-part arrangements** with parts and sections
- **Algorithmic compositions** using map, filter, and recursion
- **MIDI files** for DAW integration
