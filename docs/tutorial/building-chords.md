# Building chords

A chord in relanote is **a set of intervals over a root** — the same
"relative" idea that runs through pitch and rhythm. Define it once with
`chord`, place it on any root, transpose it like any other value.

## Defining chords

`chord Name = [ ... ]` declares a reusable structure. The interior is
intervals, starting from `R`:

```rela
chord MajorTriad = [ R, M3, P5 ]
chord MinorTriad = [ R, m3, P5 ]
chord Dom7       = [ R, M3, P5, m7 ]
chord Maj7       = [ R, M3, P5, M7 ]
chord Min7       = [ R, m3, P5, m7 ]
```

There's nothing magic about the names — `MajorTriad` is just three
intervals. The shape is what's named. Play `MajorTriad` rooted on `C` to
get C major; root it on `G` to get G major. The chord doesn't change.

## Progressions are scale-degree blocks

A progression is the same block syntax as a melody, only each slot
resolves to a chord rooted on that scale degree:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let I_IV_V_I = | <1> <4> <5> <1> |
```

Swap the scale to `Minor` and the same line plays a i-iv-v-i. That's
the whole reason we kept everything relative.

## Arpeggios

Spell a chord out one note at a time and you have an arpeggio:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let up   = | <1> <3> <5> <8> |
let down = up |> reverse
```

Octaves are just another interval — `<8>` is the scale's eighth degree,
which is the root one octave up.

## Common shapes

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let pop  = | <1> <5> <6> <4> |             ; I-V-vi-IV
let jazz = | <2> <5> <1> |                 ; ii-V-I
```

A twelve-bar blues, in the relative-mode equivalent of every other
twelve-bar blues ever written:

```rela
scale Blues = { R, m3, P4, A4, P5, m7 }

let blues = | <1> <1> <1> <1>  <4> <4> <1> <1>  <5> <4> <1> <5> |
```

## Your turn

Pick a four-degree progression you like (vi-IV-I-V is a useful one to
try). Write it once, then transpose it by a few different intervals.
Notice that each transposition keeps the same *shape* — the chord
relationships don't change, only the absolute pitches do.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let progression = | <6> <4> <1> <5> |
progression ++ (progression |> transpose P5)
```

Next: arrange parts, sections and layers in
[Creating a song](/tutorial/creating-a-song).
