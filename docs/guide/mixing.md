# Mixing

Mixing is the routing graph that turns a stack of parts into a finished
piece. relanote describes it the same way it describes everything else:
a declaration, in source, with `mix { ... }`.

```rela
mix {
  ; Per-track effects.
  track "lead"  |> reverb 0.3 |> compress -10 4
  track "bass"  |> saturate 0.2
  track "drums" |> effect DrumBus

  ; Shared sends — every track can route a portion of its signal here.
  bus Verb   = effect PlateLarge
  bus Delay  = effect TapeEcho
  bus Glue   = effect BusGlue

  ; How much of each track to feed the buses.
  track "lead"  |> send Verb  0.35
  track "lead"  |> send Delay 0.20
  track "drums" |> send Glue  1.00

  ; Ducking: kick keys a -6dB duck on bass.
  sidechain track "kick" -> track "bass" 0.6

  ; Master chain after summing.
  master = effect MasterChain
}
```

That whole block is one **declaration** — `Item::MixDef` in the AST.
The pieces below explain each part.

## Tracks

A *track* is whatever part of the piece you want to address by name.
By convention, they correspond to your top-level `part` or `section`
declarations: `track "lead"` refers to the part named `"lead"`. Apply
effects directly with the pipe:

```rela
track "lead" |> reverb 0.3 |> compress -10 4
```

This works the same way as applying transformations to a melody — the
pipe operator is the only construct in play. There's no separate "mix
language".

## Buses and sends

A *bus* is a named effect chain. Tracks route a fraction of their
signal into the bus via `send`:

```rela
bus Verb = effect PlateLarge
bus Glue = effect BusGlue

track "lead"  |> send Verb 0.35   ; 35% of the lead's signal feeds Verb
track "drums" |> send Glue 1.0    ; 100% of the drums into the glue bus
```

Multiple tracks can feed the same bus — that's the point. A single
reverb tail glues a string section together; a single glue compressor
makes the drums sound like one kit.

## Sidechain

`sidechain source -> target amount` makes `source`'s envelope duck
`target`'s amplitude:

```rela
sidechain track "kick" -> track "bass" 0.6      ; pump bass under the kick
sidechain bus "Verb"   -> bus "Verb"  0.3       ; ducked reverb tail
```

The amount is the duck depth (0.0 = no change, 1.0 = full mute on each
trigger).

## Master

`master = ...` is the final effect chain applied to the summed mix:

```rela
master = effect MasterChain
```

`MasterChain` (from `effects_mix.rela`) is a typical "glue + EQ +
limiter" lockup. You can write your own — `master` accepts any
expression that evaluates to an effect.

## Effects out of the box

The stdlib ships two effect modules in
[`moonbit/relanote_stdlib/prelude/`](https://github.com/ubugeeei/relanote/tree/main/moonbit/relanote_stdlib/prelude):

| Module | What's in it |
| --- | --- |
| `effects_dub.rela` | Delay / reverb / phaser / freeze effects in a dub palette: `DubDelay`, `DottedDelay`, `TapeEcho`, `PlateLarge`, `SpringBright`, `DubRoom`, `PhaserSlow`, `Freeze`. |
| `effects_mix.rela` | Mix-stage processing: `BusGlue`, `DrumBus`, `ParallelSmash`, `MasterChain`, `DeEss`, `Tape`, `Drive`, `Vinyl`. |

Use them by name — `effect DubDelay`, `effect BusGlue` — or roll your
own with the `effect` keyword:

```rela
effect MyVerb = reverb {
  size: 0.8,
  decay: 4.0,
  damping: 0.6,
  mix: 0.4,
  pre_delay: 0.03
}
```

## A complete example

A small piece showing every mix construct in one place:

```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

part "lead"  { | <5> <6> <5> <3> | ++ | <1> <2> <3> <1> | } |> voice WaveVapor
part "bass"  { | <1> - <1> <5> | }                          |> voice BassMoog
part "kick"  { | R - - - |:2 |> repeat 4 }                  |> voice LofiKick
part "snare" { | - - R - |:2 |> repeat 4 }                  |> voice LofiSnare
part "hat"   { | R R R R |:2 |> repeat 4 }                  |> voice LofiHat

mix {
  track "lead"  |> compress -12 3
  track "bass"  |> saturate 0.2
  track "kick"  |> effect DrumBus

  bus Verb = effect DubRoom
  bus Glue = effect BusGlue

  track "lead"  |> send Verb 0.40
  track "snare" |> send Verb 0.25
  track "kick"  |> send Glue 1.00
  track "snare" |> send Glue 1.00
  track "hat"   |> send Glue 1.00

  sidechain track "kick" -> track "bass" 0.7

  master = effect MasterChain
}
```

## Status

`MixDef`, `BusDef`, `SendDef`, `SidechainDef` and `EffectDef` are on
the AST today
([`moonbit/relanote_ast/sound.mbt`](https://github.com/ubugeeei/relanote/blob/main/moonbit/relanote_ast/sound.mbt)).
The parser and evaluator skeletons accept the syntax but don't yet
route audio through it — the routing graph is built and walked once
the evaluator port lands.
