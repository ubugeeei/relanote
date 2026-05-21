# Functions

A relanote piece is a value. Functions are how you turn one value
into another — and the language treats them like every other value:
pass them around, store them, compose them, partially apply them.

## Lambdas

`\arg -> body` is an inline function. Stack arguments to take more
than one:

```rela
let up_an_octave = \b -> b |> transpose P8
let glue         = \a b -> a ++ b
```

Use a lambda directly inside a pipe when the transformation is
one-off:

```rela
| <1> <2> <3> | |> (\b -> b |> repeat 2)
```

## `let`

`let name = expr` binds a value (or a function — they're the same
thing):

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme       = | <1> <3> <5> |
let up_octave   = \b -> b |> transpose P8
let backwards   = \b -> b |> reverse
```

`let name = expr in body` is a local binding scoped to `body`:

```rela
let song =
  let theme     = | <1> <3> <5> | in
  let variation = theme |> reverse in
  theme ++ variation
```

## Builtin transformations

The shipped library is small and orthogonal — combine them to taste:

| Category | Function | What it does |
| --- | --- | --- |
| **Block shape** | `reverse b` | reverse slot order |
| | `repeat n b` | concatenate `b` with itself `n` times |
| | `transpose i b` | shift every pitch by interval `i` |
| | `map f b` | apply `f` to each note |
| | `in_scale s b` | reinterpret scale-degree references against `s` |
| | `in_tuning t b` | resolve pitches through tuning `t` |
| **Rhythm & feel** | `swing` | apply 8th-note swing |
| | `groove g b` | apply a `groove` template |
| | `double_time b` | halve durations |
| | `half_time b` | double durations |
| **Synth & FX** | `voice s b` | apply synth `s` |
| | `volume v b` | scale amplitude (0–1) |
| | `reverb amt b` | quick reverb send |
| | `effect e b` | apply a named `effect` |
| **Routing** | `send bus amt b` | route a fraction of `b`'s signal to a bus |
| **Layering** | `layer [...]` | run multiple lines concurrently |
| **Polyrhythm** | `over a b` | `a` and `b` play simultaneously at their own periods |

A complete reference lives in
[Built-in Functions](/reference/builtins).

## Composing with `>>`

`f >> g` is "first f, then g" — the same as a function that pipes its
argument through both:

```rela
let dub_style = transpose P5 >> swing >> reverb 0.4

melody1 |> dub_style
melody2 |> dub_style
```

`>>` and `|>` are duals: pick `>>` when you want a *named*
transformation; pick `|>` when you want a *value*.

## Partial application

A multi-argument builtin called with a missing argument returns a
function expecting the rest. That's why `transpose P5` is itself a
function:

```rela
let up_fifth = transpose P5
let louder   = volume 0.9

melody |> up_fifth |> louder
```

The point-free style isn't required, but it reads cleanly for the
common cases.

## Higher-order functions

Functions can take and return other functions. Useful when one
parameter governs the *shape* of the transformation:

```rela
let make_transposer = \interval -> (\b -> b |> transpose interval)

let up_fifth  = make_transposer P5
let up_octave = make_transposer P8
```

## A theme-and-variations sketch

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <3> <5> <3> <1>~ - - - |

; Four operations, each one a function from block to block.
let retrograde   = \b -> b |> reverse
let inversion    = \b -> b |> map (\n -> R - n) |> transpose P8
let augmentation = \b -> b |> half_time
let diminution   = \b -> b |> double_time

theme
  ++ retrograde   theme
  ++ inversion    theme
  ++ augmentation theme
  ++ diminution   theme
```

Variations are just function applications. The structure of the
piece is the structure of the code.

## Rules of thumb

- **Name the transformation, not the result.** `let jazz_style = ...`
  is reusable; `let jazzed_theme = ...` isn't.
- **Compose small functions.** A 6-step pipe is fine. A 12-step pipe
  needs a name (split it into two named compositions).
- **Pure stays pure.** Every builtin is pure — same input, same
  output. Stay there and the type checker remains useful.
- **Reach for `let ... in`** for true locals. Top-level `let`
  exports a name; `let ... in` keeps it private to one expression.

## Listen-through example

The transformations are values: original, reversed, repeated and
double-time versions of the same block.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme      = | <1> <3> <5> <3> |:2
let retrograde = theme |> reverse
let drive      = theme |> repeat(2) |> double_time

theme ++ retrograde ++ drive
```
