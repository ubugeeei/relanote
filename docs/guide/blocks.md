# Blocks

A block — `| ... |` — is the unit of time in relanote. Everything
inside a block **shares its slot equally**: four notes split the slot
into quarters, two notes into halves, eight into eighths. The block
doesn't carry durations. It carries *how the slot is divided*.

That's the rhythmic half of "everything is relative". The same line
plays as 16th notes against a one-beat slot or as quarters against a
four-beat slot.

## Syntax

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

| R M3 P5 M3 |             ; intervals
let melody = | <1> <2> <3> <4> <5> |  ; scale-degree references
```

## Rests

`-` is a rest. It takes a share of the slot just like any pitched
note:

```rela
let with_breath = | <1> - <3> - <5> |
```

## Relative rhythm

A block defaults to one beat. The shape inside it is what changes:

```rela
| <1> <2> <3> <4> |                ; 4 share 1 beat   → 16th notes
| <1> <2> |                        ; 2 share 1 beat   → 8th  notes
| <1> |                            ; 1 fills 1 beat   → quarter note
| <1> <2> <3> <4> <5> <6> <7> <8> |; 8 share 1 beat   → 32nd notes
```

Pin the block's total time with `:n`:

```rela
| <1> <2> <3> |:2     ; 3 over 2 beats
| <1> <2> <3> <4> |:4 ; 4 over 4 beats → quarter notes
| <1> <2> |:0.5       ; 2 over half a beat
```

Pin an individual note's share with `:n` directly after it:

```rela
| <1>:2 <2> <3> |     ; first note holds 2 slot-positions, others 1
| <1>:4 |             ; one held note across 4 slot-positions
| <1> -:2 <3> |       ; rests carry durations too
```

## Articulations

After the note, before any duration:

```rela
| <1>* <3>* <5> |     ; staccato — short, detached
| <1>^ <3>^ <5> |     ; accent   — emphasised
| <1>~ <3>~ <5> |     ; portamento — connected / sliding
```

## Concatenation preserves shape

`++` glues blocks; **each side keeps the rhythm it was written in**:

```rela
let fast = | <1> <2> <3> <4> <5> <4> <3> <2> |   ; 8 share 1 beat
let slow = | <1> <5> |                            ; 2 share 1 beat
let held = | <1> |:2                              ; 1 over 2 beats

let phrase = fast ++ slow ++ held
```

This is what makes `++` more interesting than string concatenation —
you can splice different densities and tempos without recomputing any
durations.

## Tuplets

`{ ... }:n` fits its contents into *n* beats — a way to write a
triplet, septuplet or any odd grouping without breaking the surrounding
metre:

```rela
let triplet  = | { <1> <2> <3> }:2 |                 ; 3 in 2 beats
let turn     = | <5>~ { <6> <5> <4> }:2 <5>~ - |     ; ornamental turn
```

## Transformations on blocks

Blocks are values. Everything that's a function from a block to a block
works:

```rela
let pattern   = | <1> <3> <5> |
let repeated  = pattern |> repeat 4
let backwards = pattern |> reverse
let higher    = pattern |> transpose P5
let octave_up = pattern |> map (\n -> n + P8)
```

## Chords inside blocks

`[ ... ]` is a chord — multiple intervals played simultaneously. Drop
one into a slot and the slot plays the whole chord at once:

```rela
let triad        = | [R, M3, P5] |

let progression  = | [R, M3, P5]  [P4, M6, R]  [P5, M7, M2]  [R, M3, P5] |
```

A block of chords obeys the same relative-rhythm rules — four chords in
the slot are each played for a quarter of it.
