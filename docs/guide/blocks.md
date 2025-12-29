# Blocks

Blocks are sequences of musical events - notes, rests, and chords - that form the basic unit of composition.

## Basic Block Syntax

A block is enclosed in pipe delimiters `| |`:

```rela
; A simple melody using intervals
| R M3 P5 M3 |

; Using scale degrees
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <2> <3> <4> <5> |

melody
```

## Rests

Use `-` for rests:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> - <3> - <5> |    ; Note, rest, note, rest, note

melody
```

## Relative Rhythm

Relanote uses **relative rhythm**: all slots within a block are equally divided.
By default, a block lasts 1 beat.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

| <1> <2> <3> <4> |    ; 4 notes in 1 beat (each 1/4 beat = 16th notes)
| <1> <2> |            ; 2 notes in 1 beat (each 1/2 beat = 8th notes)
| <1> |                ; 1 note in 1 beat (quarter note)
| <1> <2> <3> <4> <5> <6> <7> <8> |  ; 8 notes in 1 beat (32nd notes)
```

This means **the number of slots determines the rhythm**, not explicit duration values.

### Note Duration

Individual notes can have explicit durations using `:n` after the note:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Half note followed by two quarter notes
let melody = | <1>:2 <2> <3> |

; Whole note (takes 4 slot positions)
let held = | <1>:4 |

; Rests can also have durations
let with_pause = | <1> -:2 <3> |

melody
```

The `:n` syntax means the note occupies `n` slot positions worth of time.

### Specifying Block Duration

Use `:n` after a block to specify its duration in beats:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

| <1> <2> <3> |:2      ; 3 notes in 2 beats (each 2/3 beat)
| <1> <2> <3> <4> |:4  ; 4 notes in 4 beats (each 1 beat = quarter notes)
| <1> <2> |:0.5        ; 2 notes in half a beat (each 1/4 beat)
```

## Articulations

Add articulations after notes:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let staccato = | <1>* <3>* <5> |      ; Staccato (*) - short, detached
let accented = | <1>^ <3>^ <5> |      ; Accent (^) - emphasized
let legato = | <1>~ <3>~ <5> |        ; Portamento (~) - connected
```

## Block Concatenation

### Basic Concatenation

Use `++` to join blocks:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let a = | <1> <3> |
let b = | <5> <8> |
let combined = a ++ b    ; | <1> <3> <5> <8> |

combined
```

### Preserving Rhythm Across Concatenation

**Important:** When concatenating blocks, each block's original rhythm is preserved!

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Fast: 8 notes in 1 beat (each 0.125 beats)
let fast = | <1> <2> <3> <4> <5> <4> <3> <2> |

; Slow: 2 notes in 1 beat (each 0.5 beats)
let slow = | <1> <5> |

; Held: 1 note in 2 beats
let held = | <1> |:2

; Combined: each block keeps its original note durations!
let melody = fast ++ slow ++ held

melody
```

This is crucial for creating varied rhythmic patterns. The `fast` notes remain quick, `slow` notes remain longer, and `held` note stays for 2 beats.

## Tuplets

Use `{ }:n` for tuplets (fitting notes into a specific number of beats):

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Triplet: 3 notes in 2 beats
let triplet = | { <1> <2> <3> }:2 |

; Ornamental turn
let ornament = | <5>~ { <6> <5> <4> }:2 <5>~ - |

ornament
```

## Block Transformations

### Repetition

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let pattern = | <1> <3> <5> |
let repeated = pattern |> repeat(4)    ; Play 4 times

repeated
```

### Transformation

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <3> |

; Reverse
let backwards = melody |> reverse

; Transpose
let higher = melody |> transpose(P5)

backwards
```

### Mapping

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <2> <3> |

; Add octave to each note
let octaveUp = melody |> map(\n -> n + P8)

octaveUp
```

## Chords

Use `[ ]` to play multiple notes simultaneously:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Major triad
let triad = | [R, M3, P5] |

; Chord progression
let progression = | [R, M3, P5] [P4, M6, R] [P5, M7, M2] [R, M3, P5] |

progression
```
