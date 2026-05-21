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

let intervals = | R M3 P5 M3 |
let melody = | <1> <2> <3> <4> <5> |

intervals ++ melody
```

## Rests

`-` is a rest. It takes a share of the slot just like any pitched
note:

```rela
let with_breath = | <1> - <3> - <5> |

with_breath
```

## Relative rhythm

A block defaults to one beat. The shape inside it is what changes:

```rela
let dense  = | <1> <2> <3> <4> |
let medium = | <1> <2> |
let held   = | <1> |
let ripple = | <1> <2> <3> <4> <5> <6> <7> <8> |

dense ++ medium ++ held ++ ripple
```

Pin the block's total time with `:n`:

```rela
let three_over_two = | <1> <2> <3> |:2
let quarters       = | <1> <2> <3> <4> |:4
let halfbeat       = | <1> <2> |:0.5

three_over_two ++ quarters ++ halfbeat
```

Pin an individual note's share with `:n` directly after it:

```rela
let held_first = | <1>:2 <2> <3> |
let long_root  = | <1>:4 |
let rest_hold  = | <1> -:2 <3> |

held_first ++ long_root ++ rest_hold
```

## Articulations

After the note, before any duration:

```rela
let staccato = | <1>* <3>* <5> |
let accent   = | <1>^ <3>^ <5> |
let glide    = | <1>~ <3>~ <5> |

staccato ++ accent ++ glide
```

## Concatenation preserves shape

`++` glues blocks; **each side keeps the rhythm it was written in**:

```rela
let fast = | <1> <2> <3> <4> <5> <4> <3> <2> |
let slow = | <1> <5> |
let held = | <1> |:2

fast ++ slow ++ held
```

This is what makes `++` more interesting than string concatenation —
you can splice different densities and tempos without recomputing any
durations.

## Tuplets

`{ ... }:n` fits its contents into *n* beats — a way to write a
triplet, septuplet or any odd grouping without breaking the surrounding
metre:

```rela
let triplet = | { <1> <2> <3> }:2 |
let turn    = | <5>~ { <6> <5> <4> }:2 <5>~ - |

triplet ++ turn
```

## Transformations on blocks

Blocks are values. Everything that's a function from a block to a block
works:

```rela
let pattern   = | <1> <3> <5> |
let repeated  = pattern |> repeat(4)
let backwards = pattern |> reverse
let faster    = pattern |> double_time

repeated ++ backwards ++ faster
```

## Chords inside blocks

`[ ... ]` is a chord — multiple intervals played simultaneously. Drop
one into a slot and the slot plays the whole chord at once:

```rela
let triad        = | [R, M3, P5] |

let progression  = | [R, M3, P5]  [P4, M6, R]  [P5, M7, M2]  [R, M3, P5] |

progression
```

A block of chords obeys the same relative-rhythm rules — four chords in
the slot are each played for a quarter of it.

## Listen-through example

This phrase uses the whole page: density changes, held slots, rests,
articulations, tuplets, concatenation and chord slots. The final line is
the value the preview plays.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let pulse  = | <1>:2 - <5> - |:4
let turn   = | <5>~ { <6> <5> <4> }:2 <3>* - |:4
let answer = | [R, M3, P5]^ [P4, M6, R] [P5, M7, M2] [R, M3, P5] |:4

pulse ++ turn ++ answer
```
