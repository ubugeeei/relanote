# Showcase

These are not tiny syntax samples. Each sketch is arranged as a small
record: drums, bass, midrange motion, air, and a playable preview. The
browser instrument now treats `layer [ ... ]` as simultaneous voices,
so the examples are closer to listening than reading.

The mixes are intentionally register-aware: subs stay low and centered,
pads avoid eating the bass, bells and hats are quieter in the top end,
and dense examples leave gaps so the preview does not collapse into one
flat smear.

## Vector Bloom Breaks

Intelligent drum and bass: fast break pressure, a disciplined sub,
glass fragments, and soft harmonic bloom around the body of the track.

```rela
set key = D2
set tempo = 172

let kick = |
  R - - - - - R - - - R - - - - -
  R - - - - - - R - - R - - - R -
|:8 |> voice(LofiKick)

let snare = |
  - - - - P8 - - - - - - - P8 - - -
  - - - - P8 - - - - - - - P8 - P8 -
|:8 |> voice(LofiSnare)

let hats = |
  P15 P15 - P15 P15 - P15 P15 P15 - P15 P15 - P15 - P15
  P15 - P15 P15 - P15 P15 - P15 P15 P15 - P15 - P15 P15
|:8 |> voice(LofiHat)

let sub = |
  R~ - - m7 R - M3 -
  R - P5 - m7~ - R -
|:16 |> voice(SubBass)

let reese = |
  P8 - m10 P8 - m7 P8 M10
  P8 - P12 - m10 - m7 -
|:16 |> voice(AcidBass)

let pad = |
  [P8, m10, P12, m14] - - [m7, M10, P12] - - [P5, m7, m10] -
  [P8, m10, P12, M17] - - [m7, M10, P12] - [P5, m7, m10] -
|:16 |> voice(FloatingBloom)

let glass = |
  - P15 - M17 - P19 - M17
  - M17 P19 - P22 - M17 -
|:16 |> voice(FMKalimba)

layer [kick, snare, hats, sub, reese, pad, glass]
```

## Prism Rhodes Study

Electric-piano weight in the mids, bell harmonics above it, and a soft
round bass below. The chord voicings leave enough room for the attack
of the FM layer to stay readable.

```rela
set key = C3
set tempo = 108

let bass = |
  R - P5 - M6 - P5 -
  P4 - R - P5 - M3 -
|:8 |> voice(BassMoog)

let rhodes = |
  [R, M3, P5, M7] - [M2, P4, M6] -
  [P4, M6, P8, M10] - [P5, M7, M9] -
|:8 |> voice(FMRhodes)

let bell = |
  P15 - M17 - P19 - M17 -
  M14 - P15 - M17 - P19 -
|:8 |> voice(FMBell)

let counter = |
  - P8 M10 - P12 - M10 -
  - M9 P8 - M7 - P5 -
|:8 |> voice(WaveVapor)

layer [bass, rhodes, bell, counter]
```

## Dub Pressure Room

The sub is sparse, the chord stabs sit in the low-mid range, and the
top line behaves like tape feedback without needing an effect block.

```rela
set key = A2
set tempo = 138

let kick = | R - - - R - - - - - R - - - - - |:4 |> voice(LofiKick)
let snare = | - - - - P8 - - - - - - - P8 - - - |:4 |> voice(LofiSnare)
let hat = | - P15 - P15 - P15 P15 - - P15 - P15 - - P15 - |:4 |> voice(LofiHat)

let sub = |
  R~ - - - P5 - - -
  m7~ - - - P5 - R -
|:8 |> voice(SubBass)

let chords = |
  [P8, m10, P12] - - - [m7, M10, P12] - - -
  [P5, m7, m10] - - - [R, m3, P5] - - -
|:8 |> voice(WaveFormant)

let tape = |
  - - P15 - - M17 - P15
  - P12 - m10 - P8 - -
|:8 |> voice(GrainVocal)

layer [kick, snare, hat, sub, chords, tape]
```

## Granular Iris

Slow material for hearing the high-quality side of the preview engine:
a low drone, two moving cloud voices, and tiny glass hits that stay
quiet enough not to shred the mix.

```rela
set key = F2
set tempo = 68

let drone = | R~ - - - P5~ - - - |:16 |> voice(SubBass)

let cloud_a = |
  [P8, M10, P12] - - - [M9, P12, M14] - - -
|:16 |> voice(GrainDrift)

let cloud_b = |
  - - [P5, M7, P9] - - - [P4, M6, P8] -
|:16 |> voice(FloatingGlass)

let shimmer = |
  - P19 - - M17 - - P15
  - - P22 - M17 - P19 -
|:16 |> voice(GrainShimmer)

layer [drone, cloud_a, cloud_b, shimmer]
```

## Pixel Counterpoint

Chiptune does not need to mean small. This one uses a centered bass,
two square-wave lines in different registers, and percussion that keeps
the high band controlled.

```rela
set key = E3
set tempo = 148

let pulse = | R - R - R - R - |:4 |> voice(LofiKick)
let snap = | - - P8 - - - P8 - |:4 |> voice(LofiSnare)
let bass = | R R P5 R M3 R P5 R |:4 |> voice(GameBoy)

let lead = |
  P8 M9 M10 P12 M10 M9 P8 -
  P12 M14 P15 M14 P12 M10 M9 -
|:8 |> voice(NES)

let answer = |
  - P5 - M6 - M7 - P8
  - M10 - P12 - M10 P8 -
|:8 |> voice(Chiptune)

layer [pulse, snap, bass, lead, answer]
```

## Broken Modal Machine

An odd-meter machine made from repeating cells. The bass is low and
dry, the lead lives in the presence range, and the pad fills the middle
without masking either.

```rela
set key = G2
set tempo = 126

let kick = | R - - R - - R - |:5 |> repeat(3) |> voice(LofiKick)
let snare = | - - P8 - - P8 - |:7 |> repeat(2) |> voice(LofiSnare)
let hats = | P15 P15 - P15 - P15 P15 - |:5 |> repeat(3) |> voice(LofiHat)

let bass = |
  R - P5 - m7 - P5 -
  R - M3 - P5 - m7 -
|:10 |> voice(FatBass)

let pad = |
  [P8, m10, P12] - [P5, m7, m10] - [M6, P8, M10] -
|:10 |> voice(SoftPad)

let lead = |
  P12 - M14 P15 - M14 P12 -
  M10 - P12 M14 - P12 M10 -
|:10 |> voice(ModularLead)

layer [kick, snare, hats, bass, pad, lead]
```

## Airlock Arpeggio

Wavetable motion with a controlled low end. This is a compact example
for hearing how the same relative material changes when the register
and voice allocation change.

```rela
set key = B2
set tempo = 132

let root = | R - P5 - M7 - P5 - |:8 |> voice(SubBass)

let vapor = |
  P8 M10 P12 M14 P12 M10 P8 M10
  P12 M14 P15 M14 P12 M10 P8 -
|:8 |> voice(WaveSupersaw)

let formant = |
  - P15 - M17 - P19 - M17
  - M14 - P15 - M17 - P19
|:8 |> voice(WaveFormant)

let bell = |
  P19 - - P22 - M21 - P19
  - P22 - P24 - M21 - P19
|:8 |> voice(FMBell)

layer [root, vapor, formant, bell]
```
