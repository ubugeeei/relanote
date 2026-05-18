# Scales and chords

A scale and a chord are both **collections of intervals over a
root** — same primitive, different shape. A scale defines the
intervals a piece can pick from; a chord plays a subset of those
intervals at the same instant.

Everything else in the language — `<n>` references, modal interchange,
transposition, modulation — falls out of those two ideas.

## Defining scales

`scale Name = { ... }` declares an ordered set of intervals starting
from `R`:

```rela
scale Major          = { R, M2, M3, P4, P5, M6, M7 }
scale Minor          = { R, M2, m3, P4, P5, m6, m7 }
scale MajorPentatonic = { R, M2, M3, P5, M6 }
scale MinorPentatonic = { R, m3, P4, P5, m7 }
scale Blues          = { R, m3, P4, A4, P5, m7 }
scale Dorian         = { R, M2, m3, P4, P5, M6, m7 }
scale Lydian         = { R, M2, M3, A4, P5, M6, M7 }
```

The stdlib ships these (and more) — see
[`scales.rela`](https://github.com/ubugeeei/relanote/blob/main/moonbit/relanote_stdlib/prelude/scales.rela).

## Scale degrees

`<n>` is the *n*th degree of the active scale. The degrees wrap
naturally through octaves: `<8>` is the root one octave up, `<9>` is
the second, and so on.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let triad   = | <1> <3> <5> |
let octave  = | <1> <8> |
let ninth   = | <1> <9> |
```

Add a cents offset on the degree for microtonal moves:

```rela
| <3 +5c> <5 -7c> |
```

See [Microtones](./microtones) for the whole story.

## Defining chords

`chord Name = [ ... ]` declares simultaneous intervals over a root:

```rela
chord MajorTriad = [ R, M3, P5 ]
chord MinorTriad = [ R, m3, P5 ]
chord Maj7       = [ R, M3, P5, M7 ]
chord Min7       = [ R, m3, P5, m7 ]
chord Dom7       = [ R, M3, P5, m7 ]
chord Dim7       = [ R, m3, d5, d7 ]
```

A chord doesn't pick a root — it's a *shape*. Play it on the first
degree of the active scale to get the I chord; on the fourth to get
the IV; on the fifth to get the V:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
chord Maj7  = [ R, M3, P5, M7 ]

let I_chord = | Maj7 on <1> |
let IV_chord = | Maj7 on <4> |
```

## Progressions

A progression is a block of chord positions. The active scale picks
which intervals each `<n>` resolves to:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let I_IV_V_I = | <1> <4> <5> <1> |     ; the classic
let pop      = | <1> <5> <6> <4> |     ; "Don't Stop Believin'"
let jazz     = | <2> <5> <1> |         ; ii-V-I
```

The same progression sounds entirely different over a different
scale — switch `Major` to `Minor` and `I_IV_V_I` becomes i-iv-v-i.

## Modal interchange

Swap the scale mid-piece for "borrowed" colours:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

let verse  = | <1> <5> <3> <1> |
let bridge = verse |> in_scale Minor

verse ++ bridge        ; same line, second time in parallel minor
```

`in_scale` re-roots scale-degree references against a different scale
just for the duration of its argument. Use it for picardy thirds,
modal pop, jazz substitutions, anything that says "this passage is in
*this other* scale even though the rest isn't".

## Modes

Modes are scales rotated to start from a different degree. `rotate`
does the work:

```rela
scale Major     = { R, M2, M3, P4, P5, M6, M7 }
let Dorian      = Major |> rotate 1     ; start from the 2nd degree
let Phrygian    = Major |> rotate 2
let Lydian      = Major |> rotate 3
let Mixolydian  = Major |> rotate 4
let Aeolian     = Major |> rotate 5     ; same as natural minor
let Locrian     = Major |> rotate 6
```

The shape doesn't change — only the entry point does, which is what
gives each mode its colour.

## Transposing scales and chords

Scales and chords are values, so they transpose like everything else:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let in_g = Major |> transpose P5     ; G major
let in_d = Major |> transpose M2     ; D major
```

## Quick reference

| Scale | Intervals |
| --- | --- |
| Major | `R, M2, M3, P4, P5, M6, M7` |
| Natural Minor | `R, M2, m3, P4, P5, m6, m7` |
| Harmonic Minor | `R, M2, m3, P4, P5, m6, M7` |
| Melodic Minor | `R, M2, m3, P4, P5, M6, M7` |
| Major Pentatonic | `R, M2, M3, P5, M6` |
| Minor Pentatonic | `R, m3, P4, P5, m7` |
| Blues | `R, m3, P4, A4, P5, m7` |
| Dorian | `R, M2, m3, P4, P5, M6, m7` |
| Lydian | `R, M2, M3, A4, P5, M6, M7` |
| Mixolydian | `R, M2, M3, P4, P5, M6, m7` |
| Whole Tone | `R, M2, M3, A4, A5, A6` |
| Diminished (whole-half) | `R, M2, m3, P4, A4, m6, M6, M7` |
