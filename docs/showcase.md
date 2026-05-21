# Showcase

These sketches are built for listening, not just syntax scanning. Each
one gives the preview engine enough material to show register-aware
mixing: centered sub energy, controlled high percussion, moving
midrange, and stereo space from pads, grains, bells, and delays.

## Vector Bloom Breaks

Fast intelligent drum and bass with low sub pressure, shuffled hats,
wide harmonic fog, glassy high detail, and small negative spaces so the
mix keeps depth instead of turning into a flat wall.

```rela
set key = D2
set tempo = 172

let kick = |
  R - - - - - R - - - R - - - - -
  R - - - - - - R - - R - - - R -
  R - - - - - R - - R - - - - R -
  R - - - R - - - - - R - - - - -
|:16 |> repeat(2) |> voice(LofiKick)

let snare = |
  - - - - P8 - - - - - - - P8 - - -
  - - - - P8 - - - - - - - P8 - P8 -
  - - - - P8 - - - - - - - P8 - - -
  - - - - P8 - - P8 - - - - P8 - - -
|:16 |> repeat(2) |> voice(LofiSnare)

let hats = |
  P15 P15 - P15 P15 - P15 P15 P15 - P15 P15 - P15 - P15
  P15 - P15 P15 - P15 P15 - P15 P15 P15 - P15 - P15 P15
  P15 P15 - P15 - P15 P15 - P15 - P15 P15 - P15 P15 -
  P15 - P15 P15 P15 - P15 - P15 P15 - P15 - P15 - P15
|:16 |> repeat(2) |> voice(LofiHat)

let sub = |
  R~ - - - m7 - R - P5~ - - - m7 - R -
  R - P5 - m7~ - - - R - M3 - P5 - m7 -
|:32 |> repeat(2) |> voice(SubBass)

let reese = |
  P8 - m10 P8 - m7 P8 M10 P8 - P12 - m10 - m7 -
  P8 - - M10 - P12 - M14 P12 - M10 - P8 - m7 -
|:32 |> repeat(2) |> voice(AcidBass)

let bloom = |
  [P8, m10, P12, m14] - - [m7, M10, P12] - - [P5, m7, m10] -
  [P8, m10, P12, M17] - - [m7, M10, P12] - [P5, m7, m10] -
|:32 |> repeat(2) |> voice(FloatingBloom)

let glass = |
  - P15 - M17 - P19 - M17 - P22 - M17 - P19 -
  - M17 P19 - P22 - M17 - - P24 - P22 - P19 -
|:32 |> repeat(2) |> voice(FMKalimba)

let air = |
  - - P24 - - M21 - - P22 - - M17 - - P19 -
  - P19 - - P22 - - P24 - M21 - P19 - - M17 -
|:32 |> repeat(2) |> voice(GrainShimmer)

layer [kick, snare, hats, sub, reese, bloom, glass, air]
```

## Prism Rhodes Study

Electric piano and bell layers share the top end carefully while the
bass keeps the root motion clear. The repeated pass gives the preview
room tail and delay enough time to become audible.

```rela
set key = C3
set tempo = 108

let bass = |
  R - P5 - M6 - P5 - P4 - R - P5 - M3 -
  R - M7 - P5 - M6 - P5 - P4 - M3 - P5 -
|:16 |> repeat(2) |> voice(BassMoog)

let rhodes = |
  [R, M3, P5, M7] - [M2, P4, M6] - [P4, M6, P8, M10] - [P5, M7, M9] -
  [M6, P8, M10, M14] - [P5, M7, P9] - [P4, M6, P8] - [M2, P5, M7] -
|:16 |> repeat(2) |> voice(FMRhodes)

let bell = |
  P15 - M17 - P19 - M17 - M14 - P15 - M17 - P19 -
  P22 - M21 - P19 - M17 - P15 - M14 - M17 - P19 -
|:16 |> repeat(2) |> voice(FMBell)

let vapor = |
  - P8 M10 - P12 - M10 - - M9 P8 - M7 - P5 -
  - P12 M14 - P15 - M14 - - M10 P12 - M9 - P8 -
|:16 |> repeat(2) |> voice(WaveVapor)

let shimmer = |
  - - P24 - - P22 - - - M21 - P19 - - M17 -
  - P22 - - P24 - - M21 - - P19 - M17 - P15 -
|:16 |> repeat(2) |> voice(GrainShimmer)

layer [bass, rhodes, bell, vapor, shimmer]
```

## Dub Pressure Room

Sparse low end, offbeat hats, delayed formant chords, and grain vocals.
The arrangement leaves holes so the space processor has somewhere to
move instead of smearing every transient.

```rela
set key = A2
set tempo = 138

let kick = | R - - - R - - - - - R - - - - - |:4 |> repeat(8) |> voice(LofiKick)
let snare = | - - - - P8 - - - - - - - P8 - - - |:4 |> repeat(8) |> voice(LofiSnare)
let hat = | - P15 - P15 - P15 P15 - - P15 - P15 - - P15 - |:4 |> repeat(8) |> voice(LofiHat)

let sub = |
  R~ - - - P5 - - - m7~ - - - P5 - R -
  R - - - P4~ - - - P5 - m7 - P5 - R -
|:16 |> repeat(2) |> voice(SubBass)

let chords = |
  [P8, m10, P12] - - - [m7, M10, P12] - - -
  [P5, m7, m10] - - - [R, m3, P5] - - -
|:16 |> repeat(4) |> voice(WaveFormant)

let tape = |
  - - P15 - - M17 - P15 - P12 - m10 - P8 - -
  - P19 - - M17 - P15 - - P12 - m10 - P8 - -
|:16 |> repeat(2) |> voice(GrainVocal)

let dust = |
  - P22 - - - P19 - - - M17 - - P15 - - -
  - - P24 - - P22 - - - P19 - M17 - P15 - -
|:16 |> repeat(2) |> voice(FMBell)

layer [kick, snare, hat, sub, chords, tape, dust]
```

## Granular Iris

Slow material for hearing stereo depth: a grounded drone, two wide
clouds, quiet glass hits, and a high shimmer layer that lives above
the chords without taking over the mix.

```rela
set key = F2
set tempo = 68

let drone = |
  R~ - - - P5~ - - - m7~ - - - P5~ - - -
  R~ - - - M6~ - - - P5~ - - - P4~ - - -
|:32 |> repeat(2) |> voice(SubBass)

let cloud_a = |
  [P8, M10, P12] - - - [M9, P12, M14] - - -
  [P5, M7, P9] - - - [P8, M10, P12] - - -
|:32 |> repeat(2) |> voice(GrainDrift)

let cloud_b = |
  - - [P5, M7, P9] - - - [P4, M6, P8] -
  - - [M6, P8, M10] - - - [P5, M7, P9] -
|:32 |> repeat(2) |> voice(FloatingGlass)

let shimmer = |
  - P19 - - M17 - - P15 - - P22 - M17 - P19 -
  - - P24 - - M21 - P19 - - P22 - M17 - - P15
|:32 |> repeat(2) |> voice(GrainShimmer)

let stones = |
  P12 - - P15 - - M17 - - P19 - - P22 - - -
  - P15 - - M17 - P19 - - P24 - - P22 - M17 -
|:32 |> repeat(2) |> voice(FMKalimba)

layer [drone, cloud_a, cloud_b, shimmer, stones]
```

## Carbon Counterpoint

A modern counterpoint study instead of a retro chip sketch: low analog
weight, glass FM attacks, wavetable motion, and grain detail moving
around the upper register.

```rela
set key = E3
set tempo = 148

let pulse = | R - R - R - R - |:4 |> repeat(8) |> voice(LofiKick)
let snap = | - - P8 - - - P8 - |:4 |> repeat(8) |> voice(LofiSnare)
let ticks = | P15 - P15 P15 - P15 - P15 |:4 |> repeat(8) |> voice(LofiHat)

let bass = |
  R R P5 R M3 R P5 R P4 P4 R P4 P5 R M3 R
  R P5 M6 P5 R M3 P5 R P4 R M3 R P5 M6 P5 R
|:16 |> repeat(2) |> voice(BassMoog)

let lead = |
  P8 M9 M10 P12 M10 M9 P8 - P12 M14 P15 M14 P12 M10 M9 -
  P15 M17 P19 M17 P15 M14 P12 - P19 M21 P22 P19 M17 P15 M14 -
|:16 |> repeat(2) |> voice(WaveVapor)

let answer = |
  - P5 - M6 - M7 - P8 - M10 - P12 - M10 P8 -
  - P12 - M14 - P15 - M14 - P12 - M10 - P8 P5 -
|:16 |> repeat(2) |> voice(FMRhodes)

let stars = |
  - - P22 - - P24 - - - M21 - P19 - - P17 -
  - P19 - - P22 - - P24 - M21 - P19 - P17 - -
|:16 |> repeat(2) |> voice(FMBell)

let frost = |
  - - P24 - M21 - - P22 - - P19 - P17 - - P15 -
  - P22 - - P24 - - M21 - P19 - - P17 - M14 - -
|:16 |> repeat(2) |> voice(GrainShimmer)

layer [pulse, snap, ticks, bass, lead, answer, stars, frost]
```

## Broken Modal Machine

Odd-meter cells, but mixed as a band: dry low bass, centered kick,
snare pressure, animated hats, a wide pad, and a lead that jumps across
registers instead of sitting in one narrow strip.

```rela
set key = G2
set tempo = 126

let kick = | R - - R - - R - |:5 |> repeat(8) |> voice(LofiKick)
let snare = | - - P8 - - P8 - |:7 |> repeat(6) |> voice(LofiSnare)
let hats = | P15 P15 - P15 - P15 P15 - |:5 |> repeat(8) |> voice(LofiHat)

let bass = |
  R - P5 - m7 - P5 - R - M3 - P5 - m7 -
  R - P4 - M6 - P5 - m7 - P5 - M3 - R -
|:20 |> repeat(2) |> voice(FatBass)

let pad = |
  [P8, m10, P12] - [P5, m7, m10] - [M6, P8, M10] -
  [P4, M6, P8] - [P5, m7, M10] - [P8, m10, P12] -
|:20 |> repeat(2) |> voice(SoftPad)

let lead = |
  P12 - M14 P15 - M14 P12 - M10 - P12 M14 - P12 M10 -
  P15 - M17 P19 - M17 P15 - P12 - M14 P15 - M14 P12 -
|:20 |> repeat(2) |> voice(ModularLead)

let sparks = |
  - - P22 - - P19 - - - M17 - P15 - - M14 -
  - P24 - - P22 - P19 - - M17 - P15 - M14 - -
|:20 |> repeat(2) |> voice(FMKalimba)

layer [kick, snare, hats, bass, pad, lead, sparks]
```

## Airlock Arpeggio

Wavetable motion with a controlled low end. The high bell and formant
parts test whether the preview can stay bright without becoming cheap
or brittle.

```rela
set key = B2
set tempo = 132

let root = |
  R - P5 - M7 - P5 - R - M3 - P5 - M7 -
  R - P5 - M6 - P5 - P4 - R - P5 - M3 -
|:16 |> repeat(2) |> voice(SubBass)

let vapor = |
  P8 M10 P12 M14 P12 M10 P8 M10 P12 M14 P15 M14 P12 M10 P8 -
  P12 M14 P15 M17 P15 M14 P12 M10 P8 M10 P12 M14 P12 M10 P8 -
|:16 |> repeat(2) |> voice(WaveSupersaw)

let formant = |
  - P15 - M17 - P19 - M17 - M14 - P15 - M17 - P19
  - P19 - M21 - P22 - M21 - P19 - M17 - P15 - M14
|:16 |> repeat(2) |> voice(WaveFormant)

let bell = |
  P19 - - P22 - M21 - P19 - P22 - P24 - M21 - P19
  - P24 - - P26 - P24 - P22 - M21 - P19 - M17 -
|:16 |> repeat(2) |> voice(FMBell)

let cloud = |
  - - [P8, P12, M17] - - [M10, M14, P19] - -
  [P12, P15, P22] - - [M10, M14, M21] - - [P8, P12, M17] -
|:16 |> repeat(2) |> voice(FloatingBloom)

layer [root, vapor, formant, bell, cloud]
```
