# Quick start

Five minutes from zero to a melody you can render.

## Write `hello.rela`

```rela
set key = C4
set tempo = 120

scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <3> <1> |
melody
```

Run it locally:

```bash
relanote run hello.rela
```

Or skip the install and open the [Studio](/playground/).

## What each line is doing

### Intervals

`R, M2, M3, P4, P5, M6, M7` are **intervals** — relationships between
two pitches, not pitches themselves. Quality first, degree second:

| Quality | Letter |
| --- | --- |
| Root / unison | `R` |
| Perfect | `P` |
| Major | `M` |
| Minor | `m` |
| Augmented | `A` |
| Diminished | `d` |

So `P5` is a perfect fifth, `m7` is a minor seventh, `M3` is a major
third.

### Scales

A `scale` declaration is a *set of intervals over an unspecified root*:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
```

`Major` doesn't know what key it's in. That's the point.

### Scale degrees

`<n>` is the *n*th degree of whatever scale is in scope. The same line
plays a different melody under a different scale:

```rela
| <1> <2> <3> <4> <5> |
```

### Relative rhythm

The number of slots in a block sets the rhythm. The block doesn't carry
durations — it carries *how the slot is divided*:

```rela
| <1> <2> <3> <4> |    ; 4 notes share the slot equally
| <1> <5> |            ; 2 notes share the same slot at half density
| <1> |                ; 1 note fills it
```

Pin the slot's length in beats with `:n`:

```rela
| <1> <2> <3> <4> |:4  ; 4 notes over 4 beats → quarter notes
```

### Concatenation

`++` glues blocks of any density together. Each block keeps its own
shape:

```rela
let fast = | <1> <2> <3> <4> |
let slow = | <1> <5> |
fast ++ slow
```

### Pipes

`|>` chains transformations from left to right:

```rela
melody |> repeat 2
melody |> transpose P5
melody |> reverse
```

Read it as "the value on the left, then this transformation, then this
one". Same shape as a Unix pipeline.

## Render to MIDI

```bash
relanote render hello.rela -o hello.mid
```

Open the resulting `.mid` in any DAW or playback tool.

## Key and tempo

`set` binds the runtime context. The default key is `C4`; the default
tempo is `120`:

```rela
set key = Bb3
set tempo = 140

scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> <3> <5> |
```

## Cheat sheet

| Syntax | Meaning |
| --- | --- |
| `R, M3, P5` | intervals |
| `C4, Bb3, F#4` | absolute pitches |
| `scale Name = { … }` | scale definition |
| `<n>` | nth scale degree of the active scale |
| `\| … \|` | block (one slot, equally divided) |
| `\| … \|:n` | block pinned to *n* beats |
| `-` | rest (still takes a share of the slot) |
| `++` | concatenate blocks |
| `\|>` | pipe |
| `[ … ]` | chord (intervals played together) |
| `set key = C4` | runtime root |
| `set tempo = 120` | runtime tempo |

## Where to go next

- [Intervals](/guide/intervals) — the full quality / degree story.
- [Blocks](/guide/blocks) — rhythm and density in detail.
- [Tutorial](/tutorial/getting-started) — a guided walk through a
  finished piece.

## Listen-through example

This is the whole quick-start vocabulary in one playable line:
scale-degree notes, rests, block duration and concatenation.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let hello  = | <1> <2> <3> <5> |:2
let breath = | <5> - <3> - |:2
let close  = | <1> |:2

hello ++ breath ++ close
```
