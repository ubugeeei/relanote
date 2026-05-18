# Pipes and composition

A relanote piece is a value, and most transformations on it are
functions. The pipe `|>` is how you chain those functions so the code
reads in the order the music flows.

## `|>` is "then"

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <3> |

; Without pipes — read inside out.
reverse (transpose P5 melody)

; With pipes — read left to right.
melody |> transpose P5 |> reverse
```

## Chains

For multi-step transformations, put each step on its own line:

```rela
let result = melody
  |> transpose P5    ; up a fifth
  |> repeat 2        ; then twice
  |> reverb 0.3      ; with a little reverb
```

## Composing functions without applying them

`>>` glues functions; the result is a new function:

```rela
let style = transpose P5 >> reverse >> repeat 2

melody1 |> style
melody2 |> style
```

Same shape as a Unix pipeline, only the values flowing through are
musical phrases instead of bytes.

## Partial application

Most builtins take their non-input arguments first, so currying gives
you point-free names for free:

```rela
let up_fifth = transpose P5
let doubled  = repeat 2

melody |> up_fifth |> doubled
```

## Lambdas

`\arg -> body` defines an inline function. Used most often with `map`,
`filter`, `fold`:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <2> <3> |
melody |> map (\n -> n + P8)         ; everything up an octave
```

## Patterns

A handful of pipeline shapes show up over and over.

**Transform-then-combine** — develop a theme by piping a variation off
it, then concatenate:

```rela
let theme     = | <1> <3> <5> <3> |
let variation = theme |> transpose P4 |> reverse

theme ++ variation
```

**Branching on a flag** — pipes inside an `if`:

```rela
let mixed = if energetic then
  melody |> volume 1.0
else
  melody |> volume 0.4
```

## A few rules of thumb

- **Read top-to-bottom, left-to-right.** If a chain reads in any other
  direction it's too long; break it up with `let`.
- **Name intermediates when they have a meaning.** A `let variation =`
  documents intent better than a long unbroken pipe.
- **Keep transformations pure.** Pipes are at their best when each step
  is a function from value to value.
- **Compose for reuse.** When the same chain appears twice, give it a
  name with `>>`.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Named intermediates, single direction:
let melody     = | <1> <3> <5> |
let transposed = melody     |> transpose P5
let repeated   = transposed |> repeat 2
```
