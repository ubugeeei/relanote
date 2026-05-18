# Synth sounds

Every block you've written so far played through the default tone.
relanote also ships a library of preset synths and lets you define your
own. The same relative composition surface drives all of it — `voice` is
just one more transformation in the pipe chain.

## Apply a preset with `voice`

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <3> |
melody |> voice Lead
```

`voice` is a function, so it composes with everything else:

```rela
melody |> voice Lead |> reverb 0.3 |> volume 0.8
```

## A tour of the preset library

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> |

melody |> voice Lead      ; bright sawtooth
melody |> voice SoftPad   ; warm sustained pad
melody |> voice FatBass   ; thick low end
melody |> voice Pluck     ; short percussive pluck
```

8-bit and chiptune flavours:

```rela
melody |> voice Chiptune
melody |> voice NES
melody |> voice GameBoy
```

Drums work the same way — the note is just a trigger, and the synth
shapes the hit:

```rela
let kick  = | R - - - | |> repeat 4 |> voice Kick
let snare = | - - R - | |> repeat 4 |> voice Snare
let hat   = | R R R R | |> repeat 4 |> voice HiHat |> volume 0.4
```

## Shape the sound with parameters

Each parameter is its own function. Stack them:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> |

melody
  |> voice Lead
  |> cutoff 800            ; darker
melody
  |> voice Lead
  |> cutoff 3000
  |> resonance 0.5         ; bright + resonant
melody
  |> voice Lead
  |> detune 15             ; thickened by detuning voices
melody
  |> voice Lead
  |> adsr 0.3 0.2 0.7 0.5  ; custom attack / decay / sustain / release
```

## A multi-part arrangement

Parts pin a block to an instrument; sections group parts that play
together:

```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

let main = section "Main" {
  part "Lead" {
    | <5> <6> <5> <3> | ++ | <1> <2> <3> <1> |
  } |> voice Lead |> volume 0.8

  part "Pad" {
    | [<1> <3> <5>] | ++ | [<1> <3> <5>] |
  } |> voice SoftPad |> volume 0.5

  part "Bass" {
    | <1> - <1> <5> | ++ | <4> - <4> <1> |
  } |> voice FatBass |> cutoff 300

  part "Kick" { | R - R - | ++ | R - R R | } |> voice Kick
  part "Hat"  { | R R R R | ++ | R R R R | } |> voice HiHat |> volume 0.3
}

compose([main])
```

## Custom synths

When the presets don't have what you want, declare your own. A synth is
a record of oscillator, envelope and filter:

```rela
synth MyLead = {
  osc: Saw,
  env: { A: 0.02, D: 0.15, S: 0.7, R: 0.2 },
  filter: LowPass(3000, 0.3)
}

synth PunchyBass = {
  osc: Square,
  detune: 5,
  env: { A: 0.01, D: 0.1, S: 0.5, R: 0.2 },
  filter: LowPass(200, 0.4)
}

scale Minor = { R, M2, m3, P4, P5, m6, m7 }

let lead = | <1> <3> <5> <8> | |> voice MyLead
let bass = | <1> - <1> <5> |   |> voice PunchyBass

section "Custom" { part "L" { lead } ; part "B" { bass } }
```

## A chiptune sketch

Three preset calls and the whole piece reads like a chiptune:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let lead  = | <1> <3> <5> <8> | |> voice Chiptune
let bass  = | <1> - <1> <5> |   |> voice Chiptune |> cutoff 400
let drums = | R - R - |          |> voice Kick

lead
```

## Where to go next

- [Synthesizers guide](/guide/synth) for full preset and parameter docs.
- [`examples/10_chiptune.rela`](https://github.com/ubugeeei/relanote/blob/main/examples/10_chiptune.rela) — a complete 8-bit piece.
- [`examples/11_synth_advanced.rela`](https://github.com/ubugeeei/relanote/blob/main/examples/11_synth_advanced.rela) — custom synth design.
