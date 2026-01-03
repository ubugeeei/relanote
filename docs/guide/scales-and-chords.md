# Scales & Chords

Scales and chords are collections of intervals that define harmonic context.

## Defining Scales

A scale is an ordered collection of intervals from the root:

```rela
; Major scale
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Natural minor scale
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

; Pentatonic scale
scale Pentatonic = { R, M2, M3, P5, M6 }

; Blues scale
scale Blues = { R, m3, P4, A4, P5, m7 }
```

## Using Scale Degrees

Once you have a scale, use `<n>` to reference its degrees:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Create a melody using scale degrees
let melody = | <1> <3> <5> <3> <1> |

melody
```

Scale degrees wrap around with octaves:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let octave = | <1> <8> |     ; R, R+ (octave)
let ninth = | <1> <9> |      ; R, M2+ (9th = 2nd + octave)
```

## Defining Chords

Chords use square brackets and represent simultaneous notes:

```rela
; Major triad
chord MajorTriad = [ R, M3, P5 ]

; Minor triad
chord MinorTriad = [ R, m3, P5 ]

; Dominant 7th
chord Dom7 = [ R, M3, P5, m7 ]

; Major 7th
chord Maj7 = [ R, M3, P5, M7 ]
```

## Chord Progressions

Build progressions using scale degrees:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; I-IV-V-I progression
let progression = | <1> <4> <5> <1> |

progression
```

## Modes

Create modes by starting from different scale degrees:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Dorian mode (start from 2nd degree)
let Dorian = Major |> rotate 1

; Mixolydian mode (start from 5th degree)
let Mixolydian = Major |> rotate 4
```

## How Scales Are Applied

When you define a scale with `scale`, it becomes the **active scale context** for interpreting scale degrees (`<1>`, `<2>`, etc.).

### Same Melody, Different Scales

The same scale degree pattern produces different sounds depending on the active scale:

```rela
; Major scale - bright, happy
scale Major = { R, M2, M3, P4, P5, M6, M7 }
let major_melody = | <1> <2> <3> <4> <5> |

major_melody  ; Output: R, M2, M3, P4, P5
```

```rela
; Minor scale - darker, melancholic
scale Minor = { R, M2, m3, P4, P5, m6, m7 }
let minor_melody = | <1> <2> <3> <4> <5> |

minor_melody  ; Output: R, M2, m3, P4, P5
```

### Reusing Patterns Across Scales

Define a pattern once, apply it to different scales:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; A simple arpeggio pattern using scale degrees
let arpeggio = | <1> <3> <5> <8> |

; In Major: R, M3, P5, R+ (happy major chord)
arpeggio
```

```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

; Same pattern, minor context
let arpeggio = | <1> <3> <5> <8> |

; In Minor: R, m3, P5, R+ (sad minor chord)
arpeggio
```

### Modal Interchange

Switch scales mid-piece for modal color:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
let verse = | <1> <5> <3> <1> |

scale Minor = { R, M2, m3, P4, P5, m6, m7 }
let chorus = | <1> <5> <3> <1> |

; verse uses Major intervals, chorus uses Minor
verse ++ chorus
```

## Transposition

Transpose scales and chords easily:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> |

; Transpose by interval
let transposed = melody |> transpose P5

transposed
```

## Common Scales Reference

| Name | Intervals |
|------|-----------|
| Major | R, M2, M3, P4, P5, M6, M7 |
| Natural Minor | R, M2, m3, P4, P5, m6, m7 |
| Harmonic Minor | R, M2, m3, P4, P5, m6, M7 |
| Melodic Minor | R, M2, m3, P4, P5, M6, M7 |
| Pentatonic Major | R, M2, M3, P5, M6 |
| Pentatonic Minor | R, m3, P4, P5, m7 |
| Blues | R, m3, P4, A4, P5, m7 |
| Whole Tone | R, M2, M3, A4, A5, A6 |
