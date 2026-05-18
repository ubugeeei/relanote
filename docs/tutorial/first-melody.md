# Your first melody

Three things turn a block of scale degrees into a melody you'd actually
recognise: **slots**, **rests** and **transformations**. We'll touch each
one and end with the full *Twinkle Twinkle*.

## Slots are relative time

A block divides one slot equally among the notes inside it. The number
of notes is what sets the rhythm — not duration tags, not BPM:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; 4 notes share the slot equally.
let fast = | <1> <2> <3> <4> |

; 2 notes share the same slot — each at half the density of `fast`.
let slow = | <1> <5> |

; 1 note holds the full slot.
let whole = | <1> |
```

Append a `:n` to set how many beats the slot covers:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let quarters = | <1> <2> <3> <4> |:4   ; 4 notes over 4 beats → quarter notes
let eighths  = | <1> <2> <3> <4> |:2   ; 4 notes over 2 beats → eighths
let sixteenths = | <1> <2> <3> <4> |   ; default slot → sixteenths
```

## Rests are notes too

A `-` is a rest. It takes the same share of the slot as any pitched
note next to it:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let breath = | <1> - <3> - <5> - - - |
```

## Combine blocks of different densities

`++` concatenates blocks. Each block keeps the relative rhythm it was
written in, so you can splice fast passages into slow ones without
recomputing durations:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let run    = | <1> <2> <3> <4> <5> <4> <3> <2> |
let answer = | <1> <5> |
let ending = | <1> |:2

let phrase = run ++ answer ++ ending
```

## Transform what you already have

A melody is just a value, so the language's regular tools apply:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <3> <5> <3> |

let higher    = theme |> transpose P8
let backwards = theme |> reverse
let doubled   = theme |> repeat 2

let braided   = theme ++ higher ++ backwards
```

## Twinkle Twinkle

The first two phrases of *Twinkle Twinkle Little Star*, written in two
lines that don't care what key you're in:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let phrase1 = | <1> <1> <5> <5> <6> <6> <5> - |
let phrase2 = | <4> <4> <3> <3> <2> <2> <1> - |

phrase1 ++ phrase2
```

Switch the scale to `Minor` and the same lines play *Twinkle in a minor
key*. That's the win: the *shape* of the melody and its key are
independent variables.

## Expression

Articulations attach to individual notes:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; ^ = accent, * = staccato, ~ = portamento
let phrase = | <1>^ <1> <5>^ <5> <6>^ <6> <5>~ - |
```

## Your turn

Write a short phrase. Pick a scale, pick a block density, pick a few
rests. Try transposing it by an interval and concatenating the
transposed copy back onto the original — that's a one-line two-voice
imitation.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let phrase = | <1> <3> <5> - <5> <3> <1> - |
phrase ++ (phrase |> transpose P5)
```

When you're done, head into [Building chords](/tutorial/building-chords).
