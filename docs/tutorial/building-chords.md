# Building Chords

Learn to create chord progressions and harmonic structures.

## Basic Chords

A chord is multiple notes played simultaneously. Define them with the `chord` keyword:

```rela
; Major triad
chord MajorTriad = [ R, M3, P5 ]

; Minor triad
chord MinorTriad = [ R, m3, P5 ]

MajorTriad
```

## Chord Definitions

Define reusable chord structures:

```rela
; Major triad
chord MajorTriad = [ R, M3, P5 ]

; Minor triad
chord MinorTriad = [ R, m3, P5 ]

; Dominant 7th
chord Dom7 = [ R, M3, P5, m7 ]

; Major 7th
chord Maj7 = [ R, M3, P5, M7 ]

; Minor 7th
chord Min7 = [ R, m3, P5, m7 ]
```

## Chord Progressions

Create progressions using scale degrees:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; I-IV-V-I (the classic progression)
let progression = | <1> <4> <5> <1> |

progression
```

## Arpeggios

Play chord notes sequentially:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Chord as arpeggio
let arpeggio = | <1> <3> <5> <8> |

; Descending arpeggio
let descArp = arpeggio |> reverse

arpeggio
```

## Common Progressions

### I-V-vi-IV (Pop progression)

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let popProgression = | <1> <5> <6> <4> |

popProgression
```

### ii-V-I (Jazz progression)

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let jazzProgression = | <2> <5> <1> |

jazzProgression
```

### 12-Bar Blues

```rela
scale Blues = { R, m3, P4, A4, P5, m7 }

; Simplified 12-bar blues
let bluesProgression = | <1> <1> <1> <1> <4> <4> <1> <1> <5> <4> <1> <5> |

bluesProgression
```

## Exercise

Create your own chord progression:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Try: vi-IV-I-V (another popular progression)
let myProgression = | <6> <4> <1> <5> |

myProgression
```

## Next Steps

Now let's put it all together in [Creating a Song](/tutorial/creating-a-song).
