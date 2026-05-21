# Synthesizers

A *synth* in relanote is a record of how a note becomes sound:
oscillator(s), envelope, filter, optional modulation, optional inline
effects. Apply one to anything that produces notes — a block, a part,
a section — with `|> voice(Name)`.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <3> |
melody |> voice(Lead)
```

Everything below is a different *shape* the oscillator / envelope /
modulation triple can take.

## Subtractive — oscillator → filter → envelope

The classic analogue chain. Pick a waveform; pass it through a
filter; shape its amplitude with an envelope:

```rela
synth Subtractive = {
  osc: Saw,
  env: { A: 0.01, D: 0.2, S: 0.7, R: 0.3 },
  filter: LowPass(2500, 0.4)
}
```

Audition the basic contrast: a bright lead, a plucked transient and a
slow pad playing the same pitch material.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let motif = | <1> <3> <5> <8> <5> <3> |:3

let bright = motif |> voice(Lead)
let plucked = motif |> voice(Pluck)
let pad = motif |> voice(SoftPad)

bright ++ plucked ++ pad
```

Stack oscillators with `+` and detune them for thickness:

```rela
synth FatSaw = {
  osc: Saw(voices: 5) + Sine(level: 0.4, octave: -1),
  detune: 18,
  env: { A: 0.02, D: 0.3, S: 0.8, R: 0.4 },
  filter: LowPass(3500, 0.3)
}
```

Use the thicker saw family for bass and body. The preview keeps the
same notes but changes the oscillator/filter envelope for each voice.

```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

let line = | <1> - <1> <5> <7> <5> <3> - |:4

let round = line |> voice(FatBass)
let acid = line |> voice(AcidBass)
let moog = line |> voice(BassMoog)

round ++ acid ++ moog
```

See [`synths_basic.rela`](https://github.com/ubugeeei/relanote/blob/main/src/stdlib/prelude/synths_basic.rela)
and [`synths_modular.rela`](https://github.com/ubugeeei/relanote/blob/main/src/stdlib/prelude/synths_modular.rela)
for ready-to-use shapes.

## FM — operators modulating operators

FM (frequency modulation) is what Yamaha's DX series did so well. Two
sine oscillators is enough for a *lot* of timbres — bell, electric
piano, brass, kalimba, all from two `Sine`s and three numbers:

```rela
synth FMBell = {
  osc: FM(
    op1: Sine,         ; carrier — the listener hears this
    op2: Sine,         ; modulator
    op2_ratio: 3.5,    ; ratio of modulator to carrier frequency
    op2_level: 0.6,    ; modulation index (depth)
    feedback: 0.0      ; self-feedback on the carrier
  ),
  env: { A: 0.001, D: 1.6, S: 0.0, R: 1.2 },
  filter: LowPass(9000, 0.1)
}
```

FM voices are more percussive and glassy. Compare a bell, an electric
piano and a kalimba-style attack:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let arp = | <1> <3> <5> <8> <10> <8> <5> <3> |:4

let bell = arp |> voice(FMBell)
let rhodes = arp |> voice(FMRhodes)
let kalimba = arp |> voice(FMKalimba)

bell ++ rhodes ++ kalimba
```

The combinatorics are wide: low `op2_ratio` + high `op2_level` is an
electric piano, high `op2_ratio` + short envelope is a kalimba, saw
carrier + sine modulator + feedback is brass. The
[`synths_fm.rela`](https://github.com/ubugeeei/relanote/blob/main/src/stdlib/prelude/synths_fm.rela)
preset ships six.

## Wavetable — scan through single-cycle waves

A wavetable is a sequence of waveforms the oscillator scans through.
The position into the table is the *timbral* parameter; modulate it
and the patch *changes shape* over time:

```rela
synth WaveLead = {
  osc: Wavetable(table: "vapor"),
  wave_pos: 0.5,                              ; static position
  env: { A: 0.05, D: 0.2, S: 0.7, R: 0.3 },
  filter: LowPass(2500, 0.3),
  mod: [
    lfo(target: wave_pos, rate: 0.2, depth: 0.5, shape: Sine)
  ]
}
```

[`synths_wavetable.rela`](https://github.com/ubugeeei/relanote/blob/main/src/stdlib/prelude/synths_wavetable.rela)
ships six — `WaveVapor`, `WaveDriftPad`, `WaveFormant`, `WaveBellPad`,
`WaveAcid`, `WaveSupersaw`.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let hook = | <1> <2> <3> <5> <6> <5> <3> <2> |:4

let vapor = hook |> voice(WaveVapor)
let formant = hook |> voice(WaveFormant)
let supersaw = hook |> voice(WaveSupersaw)

vapor ++ formant ++ supersaw
```

## Granular — clouds of micro-grains

Granular oscillators chop a source into 5-100 ms grains and
rearrange them. Excellent for evolving textures, vocal chops and
"stuck-tape" stutters:

```rela
synth GrainDrift = {
  osc: Granular(
    source: "drone",         ; sample bank
    grain_size: 0.08,        ; seconds per grain
    density: 28,             ; grains per second
    spray: 0.4,              ; position jitter (0 locked → 1 scattered)
    pitch_jitter: 0          ; per-grain detune in cents
  ),
  env: { A: 1.5, D: 0.5, S: 1.0, R: 2.5 },
  filter: LowPass(4500, 0.2)
}
```

Floating Points-style pads, Flying Lotus-style vocal chops and
shimmer reverbs all live here.
See [`synths_granular.rela`](https://github.com/ubugeeei/relanote/blob/main/src/stdlib/prelude/synths_granular.rela)
and [`pads_floating.rela`](https://github.com/ubugeeei/relanote/blob/main/src/stdlib/prelude/pads_floating.rela).

```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

let cloud = | <1> <5> <7> <8> <7> <5> <3> <1> |:8

let drift = cloud |> voice(GrainDrift)
let vocal = cloud |> voice(GrainVocal)
let shimmer = cloud |> voice(GrainShimmer)

drift ++ vocal ++ shimmer
```

## Modulation matrix

`mod: [ ... ]` describes a list of routings — each entry connects a
source (LFO, envelope, sample-and-hold, …) to a destination
parameter:

```rela
synth Breathing = {
  osc: Saw(voices: 5),
  detune: 18,
  env: { A: 1.5, D: 0.5, S: 0.95, R: 3.0 },
  filter: LowPass(4000, 0.25),
  mod: [
    lfo(target: filter.cutoff, rate: 0.1, depth: 1800, shape: Sine),
    lfo(target: pitch,         rate: 5.0, depth: 8,    shape: Sine, delay: 0.4),
    env(target: filter.cutoff, attack: 2.0, depth: 2500)
  ]
}
```

Pad voices need longer attacks and releases, so they read better with
held chords:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let chords = | [R, M3, P5] [P4, M6, R] [P5, M7, M2] [R, M3, P5] |:8

let soft = chords |> voice(SoftPad)
let bloom = chords |> voice(FloatingBloom)
let glass = chords |> voice(FloatingGlass)

soft ++ bloom ++ glass
```

| Source | Description |
| --- | --- |
| `lfo(rate, depth, shape, sync?, delay?)` | low-frequency oscillator. `shape` ∈ `Sine` / `Triangle` / `Square` / `SampleHold`. |
| `env(attack, decay?, sustain?, release?, depth)` | dedicated envelope, independent of the amp envelope. |
| `keytrack(amount)` | scales by note pitch. |
| `velocity(amount)` | scales by note velocity. |

Common destinations: `filter.cutoff`, `filter.resonance`, `pitch`,
`wave_pos`, `amp`, `op2_level`, `detune`.

## Pitch envelope

Drums and other transient-led sounds usually need a pitch sweep at
the front:

```rela
synth Kick = {
  osc: Sine + Triangle(level: 0.35),
  pitch_env: { from: 220, to: 55, time: 0.06 },   ; Hz, down in 60 ms
  env: { A: 0.001, D: 0.18, S: 0.0, R: 0.18 },
  filter: LowPass(2200, 0.2)
}
```

For transient synths, keep the phrase sparse and let the attack do the
work:

```rela
let kick = | R - R - R - R - |:4 |> voice(LofiKick)
let snare = | - R - R - R - R |:4 |> voice(LofiSnare)
let hat = | R R R R R R R R |:4 |> voice(LofiHat)

kick ++ snare ++ hat
```

## Inline effects on a synth

Synths can declare per-voice effects. They run *inside* the synth,
before any per-track or per-bus effects in the [mix](./mixing):

```rela
synth Crush = {
  osc: Saw(voices: 5),
  detune: 16,
  env: { A: 0.05, D: 0.3, S: 0.9, R: 1.0 },
  filter: LowPass(3500, 0.25),
  bitcrush: { bits: 10, rate: 0.85 },
  saturate: 0.18
}
```

For shared effects (one reverb across the whole mix, glue
compression across a drum subgroup, …) reach for the [Mixing](./mixing)
guide instead.

## Applying a synth — `voice`, then parameters

`voice(X)` picks the synth. After that, pipe through one or more
parameter functions to tweak this *instance*:

```rela
melody
  |> voice(Lead)
  |> cutoff 800
  |> resonance 0.4
  |> detune 12
  |> volume 0.8
```

The parameter functions match the synth's surface — `cutoff`,
`resonance`, `detune`, `adsr a d s r`, `volume`, …. Anything declared
in the synth's record is reachable; anything else is not (the type
checker will tell you).

## Multi-part arrangements

A `section` groups parts; each `part` pins a block to a voice:

```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

section "Main" {
  part "Lead" {
    | <5> <6> <5> <3> | ++ | <1> <2> <3> <1> |
  } |> voice(ModularLead) |> volume 0.8

  part "Pad" {
    | [<1> m3 P5] | ++ | [<1> m3 P5] |
  } |> voice(FloatingBloom) |> volume 0.5

  part "Bass" {
    | <1> - <1> <5> | ++ | <4> - <4> <1> |
  } |> voice(BassMoog) |> volume 0.7

  part "Drums" {
    | R - R - | ++ | R - R R |
  } |> voice(LofiKick)
}
```

For the routing graph that ties all those parts together — buses,
sends, sidechain, master — see the [Mixing](./mixing) guide.

## MIDI output

When rendering to MIDI, synth parameters are translated to standard
CC messages so a DAW or external synth can respond:

| Parameter | CC | Range |
| --- | --- | --- |
| Cutoff | 74 | 0-127 |
| Resonance | 71 | 0-127 |
| Attack | 73 | 0-127 |
| Decay | 75 | 0-127 |
| Release | 72 | 0-127 |
| Modulation | 1 | 0-127 |

## Preset library

The stdlib ships a starter pack across every chapter above. See
[Presets](./presets) for the full catalogue, or grep
[`src/stdlib/prelude/`](https://github.com/ubugeeei/relanote/tree/main/src/stdlib/prelude)
directly. Every preset is plain `.rela` source — read one, copy it,
change three numbers, ship a new sound.

## Status

The browser preview has an intentionally small timbre model today: it
recognises the preset passed to `voice(...)` and maps it to a matching
WebAudio patch family. The full declaration parser / DSP evaluator will
make custom `synth { ... }` records audible later, but the guide examples
above are already playable and useful for choosing a sound direction.

## Listen-through example

Audition the musical material before choosing a synth: pluck-like
short notes, a sustained pad chord movement and a bass answer.

```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

let pluck = | <5>* <6>* <5>* <3>* |:2
let pad   = | [R, m3, P5] [P4, m6, R] |:4
let bass  = | <1> - <5> <1> |:4

let front = pluck |> voice(Pluck)
let bloom = pad |> voice(FloatingBloom)
let low = bass |> voice(BassMoog)

front ++ bloom ++ low
```
