# What is relanote?

**relanote** is a pure functional, statically-typed language for music.
It has a single big idea: **everything is relative**. Pitch is relative.
Rhythm is relative. Chords are intervals over a root, sections are
blocks over a beat-grid, parts are sections over an instrument, layers
are parts over time. A line is the relationship between its notes;
nothing in the language pins music to where it absolutely sits.

That's not a stylistic preference. It's the entire design.

## Pitch is relative

Conventional notation and most code-based approaches tie pitches to
absolute positions: `C4`, `D4`, `E4`. That's fine for engraving — and
the worst possible shape for software. Transpose a melody and every
pitch needs rewriting. Try a different mode and you start over. The
musical idea is hidden inside the encoding.

relanote describes lines by their **scale-degree references** instead:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Five degrees, in any key, in any mode.
let theme = | <1> <3> <5> <3> <1> |
```

`<1>` is the root, `<3>` is the third, `<5>` is the fifth — of whatever
scale is in scope. The same five symbols play `C-E-G-E-C` in C major,
`G-B-D-B-G` in G major and `D-F-A-F-D` in D minor. Switching key is one
edit. Switching mode is one edit. Transposing for a different instrument
is one function call:

```rela
theme |> transpose P5
```

## Rhythm is relative

Conventional notation pins rhythm to absolute durations too — quarter
notes, eighth notes, milliseconds. relanote's blocks share a slot
**equally** among the notes inside them:

```rela
; Four notes share the slot equally.
let fast = | <1> <3> <5> <3> |

; Two notes share the same slot — each at half the density of `fast`.
let slow = | <1> <5> |

; Both blocks take the same total time. Density is what changed.
fast ++ slow
```

Tempo changes the *length* of the slot, not the *shape* inside it.
Double the tempo and you don't rewrite anything.

## Everything else, recursively

Once pitch and rhythm are relative, the rest follows. A chord is
intervals over a root. A section is blocks over a beat-grid. A part is
a section played by an instrument. A layer is parts running in parallel.
The whole language is built out of relationships, and the runtime
unwinds them when it's time to produce sound.

## Functional, pure, typed

relanote is also a programming language, with the things you'd expect:

- **Immutable values.** Transformations return new values; the originals
  never change.
- **First-class functions.** Pass them, compose them, store them.
- **Pure functions.** No hidden state, no surprise side effects.
- **Hindley-Milner type inference.** The type checker rejects programs
  that would have produced nonsense at runtime.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Compile error: a Scale and an Interval don't add.
let wrong = Major + P5

; OK: transpose the scale by a perfect fifth.
let correct = Major |> transpose P5
```

## What you can build

- Melodies with scale-degree references and intervals.
- Chord progressions with functional harmony.
- Multi-part arrangements with parts, sections and layers.
- Algorithmic compositions using `map`, `filter`, `fold` and recursion.
- Standard MIDI files ready for any DAW.

Ready to write one? Start with the [Quick Start](./quick-start).

## Listen-through example

The first half is a relative pitch idea; the second half changes the
rhythmic density while keeping the same center.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let question = | <1> <3> <5> <3> |:2
let answer   = | <6> <5> <3> <1> - <1> |:4

question ++ answer
```
