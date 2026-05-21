# Rhythm: grooves and polyrhythm

[Blocks](./blocks) cover the simple half of rhythm — *how many notes
share a slot*. This page covers the other half: how a slot can be
**unevenly subdivided** (grooves) and how multiple lines can run at
**independent periods** (polyrhythm).

Both stay relative. A groove is a per-slot offset that applies to *any*
block; a polyrhythm is an operator that combines *any* two lines.

## Grooves

A perfectly-equal block sounds quantised. Real grooves nudge each slot
by some small amount: a hip-hop snare lands a few percent late, a
swing-feel pushes the offbeat. relanote captures that as a
`groove` declaration — a vector of fractional offsets that repeats
every `length` slots.

```rela
; Standard jazz 8th-note swing — the offbeat lands 17% late.
groove Swing67 = offsets {
  length: 2,
  steps: [0.0, 0.17]
}

; J Dilla's drunken hip-hop feel — snare drags, hat-hats jitter.
groove Dilla = offsets {
  length: 16,
  steps: [
     0.00,  0.04, -0.02,  0.05,
    -0.03,  0.06,  0.02,  0.07,
     0.00,  0.05, -0.02,  0.05,
    -0.04,  0.07,  0.02,  0.08
  ]
}
```

Activate one globally or per-track:

```rela
set groove = Dilla              ; everything from here on grooves

let beat = | R - R - | R R R - |
beat |> groove Swing67           ; only this passage swings
```

The stdlib ships a starter pack — `Straight`, `Swing67`, `Swing75`,
`Dilla`, `Bossa`, `Shuffle`, `HalfTimeLazy`, `Drunken` — in
[`grooves.rela`](https://github.com/ubugeeei/relanote/blob/main/src/stdlib/prelude/grooves.rela).

## Polyrhythm with `over`

`a over b` plays both sides at the same time, with `a` looped at its
own period and `b` looped at its. The combined figure repeats every
`lcm(slots(a), slots(b))` slots:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let three = | <1> <3> <5> |    ; period 3
let four  = | <1> <2> <4> <5> | ; period 4

three over four                 ; 3-against-4, resolves every 12 slots
```

A "3 against 2" hemiola — the rhythmic backbone of much African,
Brazilian and modern classical music — is one line:

```rela
| <1> <3> <5> | over | <1> <5> |
```

`over` composes:

```rela
let twelve_eight_clave =
  | R - R - R - |
  over
  | R R R R R R R R |
```

## Polymeter

A polyrhythm gives two lines different *subdivisions* of the same time.
A polymeter gives them different *bar lengths*. Same operator — relanote
doesn't draw the distinction at the syntax level:

```rela
let line_a = | <1> <2> <3> <4> <5> |:5     ; 5 beats long
let line_b = | <1> <3> |:4                 ; 4 beats long

line_a over line_b   ; 5 / 4 polymeter — bars realign every 20 beats
```

## Tuplets inside grooves

Tuplets (`{ ... }:n`) still work as before — they're a *local*
subdivision, separate from the groove or polyrhythm system. Mix them
freely:

```rela
set groove = Swing67

let phrase = | <5>~ { <6> <5> <4> }:2 <5>~ - |
phrase                                ; grooved sixteenths around a triplet turn
```

## Status

`Expr::Over`, `Item::GrooveDef` and the `groove` keyword are on the AST
([`src/ast/sound.mbt`](https://github.com/ubugeeei/relanote/blob/main/src/ast/sound.mbt));
preset grooves are in the stdlib. The parser and evaluator skeletons
recognise the shapes but don't yet apply them at render time — that
lands alongside the parser / evaluator ports.

## Listen-through example

This keeps the examples audible today: straight pulse, a 3-in-2 tuplet
and a denser answer phrase.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let pulse = | <1> - <5> - |:4
let trip  = | { <1> <3> <5> }:2 |
let push  = | <1> <2> <3> - <5> <6> - <5> |:4

pulse ++ trip ++ push
```
