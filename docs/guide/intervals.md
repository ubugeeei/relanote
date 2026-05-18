# Intervals

An interval is **the distance between two notes**, written without
committing to either of them. Intervals are the smallest "relative"
unit in the language; scales are sets of intervals, chords are sets of
intervals, melodies are sequences of scale-degree references that
resolve through intervals.

## Notation

Every interval is `<quality><degree>` with optional semitone modifiers:

```
P1   m2   M2   m3   M3   P4   A4   d5   P5   m6   M6   m7   M7   P8
```

| Quality | Letter |
| --- | --- |
| Root / unison | `R` (equivalent to `P1`) |
| Perfect | `P` (1, 4, 5, 8…) |
| Major | `M` (2, 3, 6, 7…) |
| Minor | `m` |
| Augmented | `A` |
| Diminished | `d` |

The number is the scale degree.

```rela
P1   ; perfect unison (0 semitones)
m2   ; minor second   (1)
M2   ; major second   (2)
m3   ; minor third    (3)
M3   ; major third    (4)
P4   ; perfect fourth (5)
A4   ; augmented 4th, a.k.a. tritone (6)
d5   ; diminished 5th, also 6 — enharmonic to A4
P5   ; perfect fifth  (7)
m6   ; minor sixth    (8)
M6   ; major sixth    (9)
m7   ; minor seventh  (10)
M7   ; major seventh  (11)
P8   ; perfect octave (12)
```

## Semitone modifiers

Append `+` to raise by a semitone, `-` to lower. Stack them for larger
shifts:

```rela
P5+   ; perfect fifth + 1 = 8 semitones (enharmonic to m6)
M3-   ; major third - 1 = 3 (enharmonic to m3)
P1++  ; +2 semitones = M2
P4--  ; -2 semitones = 3
```

## Cents and microtones

Internally relanote works in **cents** (100 cents per semitone), so
microtones and alternative tunings are first-class. MIDI output emits
pitch-bend messages for any fractional semitone.

### Chromatic passages

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let up   = | P1 P1+ M2 M2+ M3 P4 |
let down = | P5 P5- P4 P4- M3 M3- M2 |
```

### A full chromatic scale

```rela
let chromatic = |
  P1 P1+ M2 M2+ M3 P4
  P4+ P5 P5+ M6 M6+ M7
  P8
|
```

### Blue notes

```rela
let blues = | P1 m3 P4 P4+ P5 m7 P1 - |
```

### Neighbour tones

A common ornament — step away by a semitone, return:

```rela
let upper = | P5 P5+ P5 - |
let lower = | P5 P5- P5 - |
let both  = | P5 P5+ P5 - P5 P5- P5 - |
```

### Whole-tone

Only major seconds:

```rela
let whole_tone = | P1 M2 M3 A4 m6+ M7 |
```

## Arithmetic

Intervals add and subtract:

```rela
M3 + m3    ; = P5     (4 + 3)
P8 - P5    ; = P4     (12 - 7)
M2 + M2    ; = M3     (2 + 2)
```

## Common shapes built from intervals

```rela
[P1, M3, P5]            ; major triad
[P1, m3, P5]            ; minor triad
[P1, M3, P5, m7]        ; dominant 7th
[P1, M2, M3, P4, P5, M6, M7]    ; major scale
[P1, M2, m3, P4, P5, m6, m7]    ; natural minor
```

## Intervals as functions

Because intervals are values, you can build transformations out of
them:

```rela
let up_a_fifth = \i -> i + P5

P1 |> up_a_fifth    ; P5
M3 |> up_a_fifth    ; M7
```

## Enharmonic equality

Two intervals with the same semitone distance compare equal:

```rela
A4 == d5    ; both six semitones (tritone)
```
