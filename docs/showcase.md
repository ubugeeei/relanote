# Showcase

These sketches are built for listening, not just syntax scanning. Each
one gives the preview engine enough material to show register-aware
mixing: centered sub energy, controlled high percussion, moving
midrange, and stereo space from pads, grains, bells, and delays.

Every example declares its synth palette in relanote before any notes
are written. Most parts are built as stacks: a bass part may have a
sine-like sub core, a Moog-style harmonic body, and a narrow acid edge.
Chords split into keys, pad wash, formant motion, and grain air rather
than asking one synth to do the whole job. Low voices are kept centered;
air, grains, formants, and bells carry the wider pan and reverb field.

## Composite Timbre Stack

A compact study in layered synthesis: every musical role is built from
several complementary synths instead of one preset carrying the whole
texture.

```rela
synth DeepKick = { osc: Sine, env: envelope(0.001, 0.12, 0.0, 0.08), filter: LowPass(55, 0.1) }
synth RoomSnare = { osc: Noise, env: envelope(0.001, 0.11, 0.0, 0.18), filter: BandPass(1900, 0.55), detune: 8 }
synth WideHat = { osc: Noise, env: envelope(0.001, 0.045, 0.0, 0.08), filter: HighPass(8200, 0.7), detune: 18 }
synth DeepSub = { osc: Sine, env: envelope(0.01, 0.22, 0.95, 0.35), filter: LowPass(54, 0.0) }
synth BassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.82, 0.25), filter: LowPass(640, 0.65), detune: 14 }
synth AcidEdge = { osc: Saw, env: envelope(0.004, 0.12, 0.7, 0.18), filter: LowPass(1180, 0.92), detune: 9 }
synth RhodesBody = { osc: FM(Sine, 2.98, 0.33), env: envelope(0.006, 0.24, 0.58, 0.8), filter: LowPass(7600, 0.25) }
synth PadBloom = { osc: Saw, env: envelope(0.34, 0.4, 0.82, 1.4), filter: LowPass(2300, 0.32), detune: 22 }
synth GlassPad = { osc: Triangle, env: envelope(0.28, 0.35, 0.76, 1.2), filter: LowPass(3400, 0.2), detune: 18 }
synth WaveFormantPan = { osc: Wavetable(Formant), env: envelope(0.02, 0.22, 0.62, 0.45), filter: BandPass(3600, 0.7), detune: 20 }
synth WaveVaporPan = { osc: Wavetable(Vapor), env: envelope(0.02, 0.18, 0.65, 0.4), filter: BandPass(4200, 0.56), detune: 24 }
synth WaveSupersawPan = { osc: Saw, env: envelope(0.02, 0.25, 0.7, 0.5), filter: BandPass(3900, 0.5), detune: 34 }
synth GrainFarShimmer = { osc: Granular(Shimmer), env: envelope(0.08, 0.25, 0.55, 0.95), filter: BandPass(5200, 0.75), detune: 28 }
synth GrainFarDrift = { osc: Granular(Drift), env: envelope(0.18, 0.4, 0.68, 1.3), filter: BandPass(2600, 0.55), detune: 24 }
synth GrainFarVocal = { osc: Granular(Vocal), env: envelope(0.06, 0.3, 0.6, 0.9), filter: BandPass(2100, 0.8), detune: 16 }
synth BellGlass = { osc: FM(Sine, 3.97, 0.58), env: envelope(0.003, 0.28, 0.18, 0.8), filter: LowPass(10400, 0.2) }
synth KalimbaBell = { osc: FM(Sine, 4.2, 0.5), env: envelope(0.003, 0.2, 0.22, 0.62), filter: LowPass(9800, 0.18) }
synth FatBassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.84, 0.28), filter: LowPass(520, 0.72), detune: 18 }
synth SoftPadAir = { osc: Triangle, env: envelope(0.38, 0.35, 0.8, 1.5), filter: LowPass(2100, 0.28), detune: 16 }
synth ModularLeadPan = { osc: Saw, env: envelope(0.01, 0.16, 0.55, 0.35), filter: BandPass(4200, 0.78), detune: 21 }

set key = F1
set tempo = 124

let kick = | R - - - R - - - - - R - - R - - |:4 |> repeat(8) |> voice(DeepKick)
let snare = | - - - - P8 - - - - - - - P8 - - - |:4 |> repeat(8) |> voice(RoomSnare)
let hat = | P15 - P15 P15 - P15 - P15 P15 - - P15 - P15 P15 - |:4 |> repeat(8) |> voice(WideHat)

let sub_core = |
  R~ - - - P5 - R - m7~ - - - P5 - R -
  R - P5 - M6~ - - - P5 - P4 - M3 - R -
|:16 |> repeat(2) |> voice(DeepSub)

let bass_body = |
  P8 - P5 P8 - m7 P8 M10 P8 - P12 - M10 - P8 -
  P8 - M10 - P12 - M14 P12 - M10 - P8 - P5 -
|:16 |> repeat(2) |> voice(BassBody)

let bass_edge = |
  - P8 - m10 - P8 - M10 - P12 - M10 - P8 - -
  - M10 - P12 - M14 - P12 - M10 - P8 - P5 -
|:16 |> repeat(2) |> voice(AcidEdge)

let chord_keys = |
  [P8, M10, P12, M14] - - [P5, M7, P9, P12] -
  [M6, P8, M10, P15] - - [P4, M6, P8, M14] -
|:16 |> repeat(2) |> voice(RhodesBody)

let chord_air = |
  [P12, M14, P15, M17] - - - [M10, P12, M14, P19] - - -
  [P8, M10, P12, P17] - - - [M6, P8, M10, M14] - - -
|:16 |> repeat(2) |> voice(PadBloom)

let formant_motion = |
  - P15 - M17 - P19 - M17 - M14 - P15 - M17 - P19
  - P22 - M21 - P19 - M17 - P15 - M14 - P12 -
|:16 |> repeat(2) |> voice(WaveFormantPan)

let grain_air = |
  - - P24 - - M21 - - P22 - - P19 - - M17 -
  - P22 - - P24 - - M21 - P19 - - M17 - P15 -
|:16 |> repeat(2) |> voice(GrainFarShimmer)

layer [kick, snare, hat, sub_core, bass_body, bass_edge, chord_keys, chord_air, formant_motion, grain_air]
```

## Vector Bloom Breaks

Fast intelligent drum and bass with low sub pressure, shuffled hats,
wide harmonic fog, glassy high detail, and small negative spaces so the
mix keeps depth instead of turning into a flat wall.

```rela
synth DeepKick = { osc: Sine, env: envelope(0.001, 0.12, 0.0, 0.08), filter: LowPass(55, 0.1) }
synth RoomSnare = { osc: Noise, env: envelope(0.001, 0.11, 0.0, 0.18), filter: BandPass(1900, 0.55), detune: 8 }
synth WideHat = { osc: Noise, env: envelope(0.001, 0.045, 0.0, 0.08), filter: HighPass(8200, 0.7), detune: 18 }
synth DeepSub = { osc: Sine, env: envelope(0.01, 0.22, 0.95, 0.35), filter: LowPass(54, 0.0) }
synth BassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.82, 0.25), filter: LowPass(640, 0.65), detune: 14 }
synth AcidEdge = { osc: Saw, env: envelope(0.004, 0.12, 0.7, 0.18), filter: LowPass(1180, 0.92), detune: 9 }
synth RhodesBody = { osc: FM(Sine, 2.98, 0.33), env: envelope(0.006, 0.24, 0.58, 0.8), filter: LowPass(7600, 0.25) }
synth PadBloom = { osc: Saw, env: envelope(0.34, 0.4, 0.82, 1.4), filter: LowPass(2300, 0.32), detune: 22 }
synth GlassPad = { osc: Triangle, env: envelope(0.28, 0.35, 0.76, 1.2), filter: LowPass(3400, 0.2), detune: 18 }
synth WaveFormantPan = { osc: Wavetable(Formant), env: envelope(0.02, 0.22, 0.62, 0.45), filter: BandPass(3600, 0.7), detune: 20 }
synth WaveVaporPan = { osc: Wavetable(Vapor), env: envelope(0.02, 0.18, 0.65, 0.4), filter: BandPass(4200, 0.56), detune: 24 }
synth WaveSupersawPan = { osc: Saw, env: envelope(0.02, 0.25, 0.7, 0.5), filter: BandPass(3900, 0.5), detune: 34 }
synth GrainFarShimmer = { osc: Granular(Shimmer), env: envelope(0.08, 0.25, 0.55, 0.95), filter: BandPass(5200, 0.75), detune: 28 }
synth GrainFarDrift = { osc: Granular(Drift), env: envelope(0.18, 0.4, 0.68, 1.3), filter: BandPass(2600, 0.55), detune: 24 }
synth GrainFarVocal = { osc: Granular(Vocal), env: envelope(0.06, 0.3, 0.6, 0.9), filter: BandPass(2100, 0.8), detune: 16 }
synth BellGlass = { osc: FM(Sine, 3.97, 0.58), env: envelope(0.003, 0.28, 0.18, 0.8), filter: LowPass(10400, 0.2) }
synth KalimbaBell = { osc: FM(Sine, 4.2, 0.5), env: envelope(0.003, 0.2, 0.22, 0.62), filter: LowPass(9800, 0.18) }
synth FatBassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.84, 0.28), filter: LowPass(520, 0.72), detune: 18 }
synth SoftPadAir = { osc: Triangle, env: envelope(0.38, 0.35, 0.8, 1.5), filter: LowPass(2100, 0.28), detune: 16 }
synth ModularLeadPan = { osc: Saw, env: envelope(0.01, 0.16, 0.55, 0.35), filter: BandPass(4200, 0.78), detune: 21 }

set key = D1
set tempo = 172

let kick = |
  R - - - - - R - - - R - - - - -
  R - - - - - - R - - R - - - R -
  R - - - - - R - - R - - - - R -
  R - - - R - - - - - R - - - - -
|:16 |> repeat(2) |> voice(DeepKick)

let snare = |
  - - - - P8 - - - - - - - P8 - - -
  - - - - P8 - - - - - - - P8 - P8 -
  - - - - P8 - - - - - - - P8 - - -
  - - - - P8 - - P8 - - - - P8 - - -
|:16 |> repeat(2) |> voice(RoomSnare)

let hats = |
  P15 P15 - P15 P15 - P15 P15 P15 - P15 P15 - P15 - P15
  P15 - P15 P15 - P15 P15 - P15 P15 P15 - P15 - P15 P15
  P15 P15 - P15 - P15 P15 - P15 - P15 P15 - P15 P15 -
  P15 - P15 P15 P15 - P15 - P15 P15 - P15 - P15 - P15
|:16 |> repeat(2) |> voice(WideHat)

let sub = |
  R~ - - - m7 - R - P5~ - - - m7 - R -
  R - P5 - m7~ - - - R - M3 - P5 - m7 -
|:32 |> repeat(2) |> voice(DeepSub)

let sub_body = |
  - P8 - - m7 - P8 - P12 - - - m7 - P8 -
  P8 - P12 - m10 - - - P8 - M10 - P12 - m10 -
|:32 |> repeat(2) |> voice(BassBody)

let reese = |
  P8 - m10 P8 - m7 P8 M10 P8 - P12 - m10 - m7 -
  P8 - - M10 - P12 - M14 P12 - M10 - P8 - m7 -
|:32 |> repeat(2) |> voice(AcidEdge)

let reese_skin = |
  - - P12 - - M14 - P12 - M10 - P8 - m7 - -
  - P8 - M10 - P12 - M14 - P12 - M10 - P8 -
|:32 |> repeat(2) |> voice(WaveFormantPan)

let bloom = |
  [P8, m10, P12, m14] - - [m7, M10, P12] - - [P5, m7, m10] -
  [P8, m10, P12, M17] - - [m7, M10, P12] - [P5, m7, m10] -
|:32 |> repeat(2) |> voice(PadBloom)

let bloom_keys = |
  [P8, m10, P12] - - - [m7, M10, P12] - - -
  [P5, m7, m10] - - - [P8, m10, M17] - - -
|:32 |> repeat(2) |> voice(RhodesBody)

let glass = |
  - P15 - M17 - P19 - M17 - P22 - M17 - P19 -
  - M17 P19 - P22 - M17 - - P24 - P22 - P19 -
|:32 |> repeat(2) |> voice(KalimbaBell)

let air = |
  - - P24 - - M21 - - P22 - - M17 - - P19 -
  - P19 - - P22 - - P24 - M21 - P19 - - M17 -
|:32 |> repeat(2) |> voice(GrainFarShimmer)

layer [kick, snare, hats, sub, sub_body, reese, reese_skin, bloom, bloom_keys, glass, air]
```

## Prism Rhodes Study

Electric piano and bell layers share the top end carefully while the
bass keeps the root motion clear. The repeated pass gives the preview
room tail and delay enough time to become audible.

```rela
synth DeepKick = { osc: Sine, env: envelope(0.001, 0.12, 0.0, 0.08), filter: LowPass(55, 0.1) }
synth RoomSnare = { osc: Noise, env: envelope(0.001, 0.11, 0.0, 0.18), filter: BandPass(1900, 0.55), detune: 8 }
synth WideHat = { osc: Noise, env: envelope(0.001, 0.045, 0.0, 0.08), filter: HighPass(8200, 0.7), detune: 18 }
synth DeepSub = { osc: Sine, env: envelope(0.01, 0.22, 0.95, 0.35), filter: LowPass(54, 0.0) }
synth BassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.82, 0.25), filter: LowPass(640, 0.65), detune: 14 }
synth AcidEdge = { osc: Saw, env: envelope(0.004, 0.12, 0.7, 0.18), filter: LowPass(1180, 0.92), detune: 9 }
synth RhodesBody = { osc: FM(Sine, 2.98, 0.33), env: envelope(0.006, 0.24, 0.58, 0.8), filter: LowPass(7600, 0.25) }
synth PadBloom = { osc: Saw, env: envelope(0.34, 0.4, 0.82, 1.4), filter: LowPass(2300, 0.32), detune: 22 }
synth GlassPad = { osc: Triangle, env: envelope(0.28, 0.35, 0.76, 1.2), filter: LowPass(3400, 0.2), detune: 18 }
synth WaveFormantPan = { osc: Wavetable(Formant), env: envelope(0.02, 0.22, 0.62, 0.45), filter: BandPass(3600, 0.7), detune: 20 }
synth WaveVaporPan = { osc: Wavetable(Vapor), env: envelope(0.02, 0.18, 0.65, 0.4), filter: BandPass(4200, 0.56), detune: 24 }
synth WaveSupersawPan = { osc: Saw, env: envelope(0.02, 0.25, 0.7, 0.5), filter: BandPass(3900, 0.5), detune: 34 }
synth GrainFarShimmer = { osc: Granular(Shimmer), env: envelope(0.08, 0.25, 0.55, 0.95), filter: BandPass(5200, 0.75), detune: 28 }
synth GrainFarDrift = { osc: Granular(Drift), env: envelope(0.18, 0.4, 0.68, 1.3), filter: BandPass(2600, 0.55), detune: 24 }
synth GrainFarVocal = { osc: Granular(Vocal), env: envelope(0.06, 0.3, 0.6, 0.9), filter: BandPass(2100, 0.8), detune: 16 }
synth BellGlass = { osc: FM(Sine, 3.97, 0.58), env: envelope(0.003, 0.28, 0.18, 0.8), filter: LowPass(10400, 0.2) }
synth KalimbaBell = { osc: FM(Sine, 4.2, 0.5), env: envelope(0.003, 0.2, 0.22, 0.62), filter: LowPass(9800, 0.18) }
synth FatBassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.84, 0.28), filter: LowPass(520, 0.72), detune: 18 }
synth SoftPadAir = { osc: Triangle, env: envelope(0.38, 0.35, 0.8, 1.5), filter: LowPass(2100, 0.28), detune: 16 }
synth ModularLeadPan = { osc: Saw, env: envelope(0.01, 0.16, 0.55, 0.35), filter: BandPass(4200, 0.78), detune: 21 }

set key = C2
set tempo = 108

let bass = |
  R - P5 - M6 - P5 - P4 - R - P5 - M3 -
  R - M7 - P5 - M6 - P5 - P4 - M3 - P5 -
|:16 |> repeat(2) |> voice(BassBody)

let bass_floor = |
  R~ - - - P5 - - - P4~ - - - P5 - M3 -
  R~ - - - M7 - - - M6~ - - - P5 - R -
|:16 |> repeat(2) |> voice(DeepSub)

let rhodes = |
  [R, M3, P5, M7] - [M2, P4, M6] - [P4, M6, P8, M10] - [P5, M7, M9] -
  [M6, P8, M10, M14] - [P5, M7, P9] - [P4, M6, P8] - [M2, P5, M7] -
|:16 |> repeat(2) |> voice(RhodesBody)

let rhodes_wash = |
  [P8, M10, P12] - - [M7, P9, P12] - - [M6, P8, M10] -
  [P12, M14, P15] - - [P9, P12, M14] - [P8, M10, P12] -
|:16 |> repeat(2) |> voice(GlassPad)

let bell = |
  P15 - M17 - P19 - M17 - M14 - P15 - M17 - P19 -
  P22 - M21 - P19 - M17 - P15 - M14 - M17 - P19 -
|:16 |> repeat(2) |> voice(BellGlass)

let vapor = |
  - P8 M10 - P12 - M10 - - M9 P8 - M7 - P5 -
  - P12 M14 - P15 - M14 - - M10 P12 - M9 - P8 -
|:16 |> repeat(2) |> voice(WaveVaporPan)

let shimmer = |
  - - P24 - - P22 - - - M21 - P19 - - M17 -
  - P22 - - P24 - - M21 - - P19 - M17 - P15 -
|:16 |> repeat(2) |> voice(GrainFarShimmer)

layer [bass_floor, bass, rhodes, rhodes_wash, bell, vapor, shimmer]
```

## Dub Pressure Room

Sparse low end, offbeat hats, delayed formant chords, and grain vocals.
The arrangement leaves holes so the space processor has somewhere to
move instead of smearing every transient.

```rela
synth DeepKick = { osc: Sine, env: envelope(0.001, 0.12, 0.0, 0.08), filter: LowPass(55, 0.1) }
synth RoomSnare = { osc: Noise, env: envelope(0.001, 0.11, 0.0, 0.18), filter: BandPass(1900, 0.55), detune: 8 }
synth WideHat = { osc: Noise, env: envelope(0.001, 0.045, 0.0, 0.08), filter: HighPass(8200, 0.7), detune: 18 }
synth DeepSub = { osc: Sine, env: envelope(0.01, 0.22, 0.95, 0.35), filter: LowPass(54, 0.0) }
synth BassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.82, 0.25), filter: LowPass(640, 0.65), detune: 14 }
synth AcidEdge = { osc: Saw, env: envelope(0.004, 0.12, 0.7, 0.18), filter: LowPass(1180, 0.92), detune: 9 }
synth RhodesBody = { osc: FM(Sine, 2.98, 0.33), env: envelope(0.006, 0.24, 0.58, 0.8), filter: LowPass(7600, 0.25) }
synth PadBloom = { osc: Saw, env: envelope(0.34, 0.4, 0.82, 1.4), filter: LowPass(2300, 0.32), detune: 22 }
synth GlassPad = { osc: Triangle, env: envelope(0.28, 0.35, 0.76, 1.2), filter: LowPass(3400, 0.2), detune: 18 }
synth WaveFormantPan = { osc: Wavetable(Formant), env: envelope(0.02, 0.22, 0.62, 0.45), filter: BandPass(3600, 0.7), detune: 20 }
synth WaveVaporPan = { osc: Wavetable(Vapor), env: envelope(0.02, 0.18, 0.65, 0.4), filter: BandPass(4200, 0.56), detune: 24 }
synth WaveSupersawPan = { osc: Saw, env: envelope(0.02, 0.25, 0.7, 0.5), filter: BandPass(3900, 0.5), detune: 34 }
synth GrainFarShimmer = { osc: Granular(Shimmer), env: envelope(0.08, 0.25, 0.55, 0.95), filter: BandPass(5200, 0.75), detune: 28 }
synth GrainFarDrift = { osc: Granular(Drift), env: envelope(0.18, 0.4, 0.68, 1.3), filter: BandPass(2600, 0.55), detune: 24 }
synth GrainFarVocal = { osc: Granular(Vocal), env: envelope(0.06, 0.3, 0.6, 0.9), filter: BandPass(2100, 0.8), detune: 16 }
synth BellGlass = { osc: FM(Sine, 3.97, 0.58), env: envelope(0.003, 0.28, 0.18, 0.8), filter: LowPass(10400, 0.2) }
synth KalimbaBell = { osc: FM(Sine, 4.2, 0.5), env: envelope(0.003, 0.2, 0.22, 0.62), filter: LowPass(9800, 0.18) }
synth FatBassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.84, 0.28), filter: LowPass(520, 0.72), detune: 18 }
synth SoftPadAir = { osc: Triangle, env: envelope(0.38, 0.35, 0.8, 1.5), filter: LowPass(2100, 0.28), detune: 16 }
synth ModularLeadPan = { osc: Saw, env: envelope(0.01, 0.16, 0.55, 0.35), filter: BandPass(4200, 0.78), detune: 21 }

set key = A1
set tempo = 138

let kick = | R - - - R - - - - - R - - - - - |:4 |> repeat(8) |> voice(DeepKick)
let snare = | - - - - P8 - - - - - - - P8 - - - |:4 |> repeat(8) |> voice(RoomSnare)
let hat = | - P15 - P15 - P15 P15 - - P15 - P15 - - P15 - |:4 |> repeat(8) |> voice(WideHat)

let sub = |
  R~ - - - P5 - - - m7~ - - - P5 - R -
  R - - - P4~ - - - P5 - m7 - P5 - R -
|:16 |> repeat(2) |> voice(DeepSub)

let chords = |
  [P8, m10, P12] - - - [m7, M10, P12] - - -
  [P5, m7, m10] - - - [R, m3, P5] - - -
|:16 |> repeat(4) |> voice(WaveFormantPan)

let tape = |
  - - P15 - - M17 - P15 - P12 - m10 - P8 - -
  - P19 - - M17 - P15 - - P12 - m10 - P8 - -
|:16 |> repeat(2) |> voice(GrainFarVocal)

let dust = |
  - P22 - - - P19 - - - M17 - - P15 - - -
  - - P24 - - P22 - - - P19 - M17 - P15 - -
|:16 |> repeat(2) |> voice(BellGlass)

layer [kick, snare, hat, sub, chords, tape, dust]
```

## Granular Iris

Slow material for hearing stereo depth: a grounded drone, two wide
clouds, quiet glass hits, and a high shimmer layer that lives above
the chords without taking over the mix.

```rela
synth DeepKick = { osc: Sine, env: envelope(0.001, 0.12, 0.0, 0.08), filter: LowPass(55, 0.1) }
synth RoomSnare = { osc: Noise, env: envelope(0.001, 0.11, 0.0, 0.18), filter: BandPass(1900, 0.55), detune: 8 }
synth WideHat = { osc: Noise, env: envelope(0.001, 0.045, 0.0, 0.08), filter: HighPass(8200, 0.7), detune: 18 }
synth DeepSub = { osc: Sine, env: envelope(0.01, 0.22, 0.95, 0.35), filter: LowPass(54, 0.0) }
synth BassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.82, 0.25), filter: LowPass(640, 0.65), detune: 14 }
synth AcidEdge = { osc: Saw, env: envelope(0.004, 0.12, 0.7, 0.18), filter: LowPass(1180, 0.92), detune: 9 }
synth RhodesBody = { osc: FM(Sine, 2.98, 0.33), env: envelope(0.006, 0.24, 0.58, 0.8), filter: LowPass(7600, 0.25) }
synth PadBloom = { osc: Saw, env: envelope(0.34, 0.4, 0.82, 1.4), filter: LowPass(2300, 0.32), detune: 22 }
synth GlassPad = { osc: Triangle, env: envelope(0.28, 0.35, 0.76, 1.2), filter: LowPass(3400, 0.2), detune: 18 }
synth WaveFormantPan = { osc: Wavetable(Formant), env: envelope(0.02, 0.22, 0.62, 0.45), filter: BandPass(3600, 0.7), detune: 20 }
synth WaveVaporPan = { osc: Wavetable(Vapor), env: envelope(0.02, 0.18, 0.65, 0.4), filter: BandPass(4200, 0.56), detune: 24 }
synth WaveSupersawPan = { osc: Saw, env: envelope(0.02, 0.25, 0.7, 0.5), filter: BandPass(3900, 0.5), detune: 34 }
synth GrainFarShimmer = { osc: Granular(Shimmer), env: envelope(0.08, 0.25, 0.55, 0.95), filter: BandPass(5200, 0.75), detune: 28 }
synth GrainFarDrift = { osc: Granular(Drift), env: envelope(0.18, 0.4, 0.68, 1.3), filter: BandPass(2600, 0.55), detune: 24 }
synth GrainFarVocal = { osc: Granular(Vocal), env: envelope(0.06, 0.3, 0.6, 0.9), filter: BandPass(2100, 0.8), detune: 16 }
synth BellGlass = { osc: FM(Sine, 3.97, 0.58), env: envelope(0.003, 0.28, 0.18, 0.8), filter: LowPass(10400, 0.2) }
synth KalimbaBell = { osc: FM(Sine, 4.2, 0.5), env: envelope(0.003, 0.2, 0.22, 0.62), filter: LowPass(9800, 0.18) }
synth FatBassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.84, 0.28), filter: LowPass(520, 0.72), detune: 18 }
synth SoftPadAir = { osc: Triangle, env: envelope(0.38, 0.35, 0.8, 1.5), filter: LowPass(2100, 0.28), detune: 16 }
synth ModularLeadPan = { osc: Saw, env: envelope(0.01, 0.16, 0.55, 0.35), filter: BandPass(4200, 0.78), detune: 21 }

set key = F1
set tempo = 68

let drone = |
  R~ - - - P5~ - - - m7~ - - - P5~ - - -
  R~ - - - M6~ - - - P5~ - - - P4~ - - -
|:32 |> repeat(2) |> voice(DeepSub)

let cloud_a = |
  [P8, M10, P12] - - - [M9, P12, M14] - - -
  [P5, M7, P9] - - - [P8, M10, P12] - - -
|:32 |> repeat(2) |> voice(GrainFarDrift)

let cloud_b = |
  - - [P5, M7, P9] - - - [P4, M6, P8] -
  - - [M6, P8, M10] - - - [P5, M7, P9] -
|:32 |> repeat(2) |> voice(GlassPad)

let shimmer = |
  - P19 - - M17 - - P15 - - P22 - M17 - P19 -
  - - P24 - - M21 - P19 - - P22 - M17 - - P15
|:32 |> repeat(2) |> voice(GrainFarShimmer)

let stones = |
  P12 - - P15 - - M17 - - P19 - - P22 - - -
  - P15 - - M17 - P19 - - P24 - - P22 - M17 -
|:32 |> repeat(2) |> voice(KalimbaBell)

layer [drone, cloud_a, cloud_b, shimmer, stones]
```

## Carbon Counterpoint

A modern counterpoint study instead of a retro chip sketch: low analog
weight, glass FM attacks, wavetable motion, and grain detail moving
around the upper register.

```rela
synth DeepKick = { osc: Sine, env: envelope(0.001, 0.12, 0.0, 0.08), filter: LowPass(55, 0.1) }
synth RoomSnare = { osc: Noise, env: envelope(0.001, 0.11, 0.0, 0.18), filter: BandPass(1900, 0.55), detune: 8 }
synth WideHat = { osc: Noise, env: envelope(0.001, 0.045, 0.0, 0.08), filter: HighPass(8200, 0.7), detune: 18 }
synth DeepSub = { osc: Sine, env: envelope(0.01, 0.22, 0.95, 0.35), filter: LowPass(54, 0.0) }
synth BassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.82, 0.25), filter: LowPass(640, 0.65), detune: 14 }
synth AcidEdge = { osc: Saw, env: envelope(0.004, 0.12, 0.7, 0.18), filter: LowPass(1180, 0.92), detune: 9 }
synth RhodesBody = { osc: FM(Sine, 2.98, 0.33), env: envelope(0.006, 0.24, 0.58, 0.8), filter: LowPass(7600, 0.25) }
synth PadBloom = { osc: Saw, env: envelope(0.34, 0.4, 0.82, 1.4), filter: LowPass(2300, 0.32), detune: 22 }
synth GlassPad = { osc: Triangle, env: envelope(0.28, 0.35, 0.76, 1.2), filter: LowPass(3400, 0.2), detune: 18 }
synth WaveFormantPan = { osc: Wavetable(Formant), env: envelope(0.02, 0.22, 0.62, 0.45), filter: BandPass(3600, 0.7), detune: 20 }
synth WaveVaporPan = { osc: Wavetable(Vapor), env: envelope(0.02, 0.18, 0.65, 0.4), filter: BandPass(4200, 0.56), detune: 24 }
synth WaveSupersawPan = { osc: Saw, env: envelope(0.02, 0.25, 0.7, 0.5), filter: BandPass(3900, 0.5), detune: 34 }
synth GrainFarShimmer = { osc: Granular(Shimmer), env: envelope(0.08, 0.25, 0.55, 0.95), filter: BandPass(5200, 0.75), detune: 28 }
synth GrainFarDrift = { osc: Granular(Drift), env: envelope(0.18, 0.4, 0.68, 1.3), filter: BandPass(2600, 0.55), detune: 24 }
synth GrainFarVocal = { osc: Granular(Vocal), env: envelope(0.06, 0.3, 0.6, 0.9), filter: BandPass(2100, 0.8), detune: 16 }
synth BellGlass = { osc: FM(Sine, 3.97, 0.58), env: envelope(0.003, 0.28, 0.18, 0.8), filter: LowPass(10400, 0.2) }
synth KalimbaBell = { osc: FM(Sine, 4.2, 0.5), env: envelope(0.003, 0.2, 0.22, 0.62), filter: LowPass(9800, 0.18) }
synth FatBassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.84, 0.28), filter: LowPass(520, 0.72), detune: 18 }
synth SoftPadAir = { osc: Triangle, env: envelope(0.38, 0.35, 0.8, 1.5), filter: LowPass(2100, 0.28), detune: 16 }
synth ModularLeadPan = { osc: Saw, env: envelope(0.01, 0.16, 0.55, 0.35), filter: BandPass(4200, 0.78), detune: 21 }

set key = E2
set tempo = 148

let pulse = | R - R - R - R - |:4 |> repeat(8) |> voice(DeepKick)
let snap = | - - P8 - - - P8 - |:4 |> repeat(8) |> voice(RoomSnare)
let ticks = | P15 - P15 P15 - P15 - P15 |:4 |> repeat(8) |> voice(WideHat)

let bass = |
  R R P5 R M3 R P5 R P4 P4 R P4 P5 R M3 R
  R P5 M6 P5 R M3 P5 R P4 R M3 R P5 M6 P5 R
|:16 |> repeat(2) |> voice(BassBody)

let bass_core = |
  R~ - P5 - M3 - P5 - P4~ - R - P5 - M3 -
  R - P5 - M6~ - P5 - P4 - R - P5 - R -
|:16 |> repeat(2) |> voice(DeepSub)

let lead = |
  P8 M9 M10 P12 M10 M9 P8 - P12 M14 P15 M14 P12 M10 M9 -
  P15 M17 P19 M17 P15 M14 P12 - P19 M21 P22 P19 M17 P15 M14 -
|:16 |> repeat(2) |> voice(WaveVaporPan)

let lead_edge = |
  - P12 - M14 - P15 - M17 - P15 - M14 - P12 -
  - P15 - M17 - P19 - M17 - P15 - M14 - P12 -
|:16 |> repeat(2) |> voice(ModularLeadPan)

let answer = |
  - P5 - M6 - M7 - P8 - M10 - P12 - M10 P8 -
  - P12 - M14 - P15 - M14 - P12 - M10 - P8 P5 -
|:16 |> repeat(2) |> voice(RhodesBody)

let answer_glass = |
  - - P17 - - P19 - - P15 - - M14 - - P12 -
  - P19 - - P22 - - P19 - M17 - - P15 - P12 -
|:16 |> repeat(2) |> voice(KalimbaBell)

let stars = |
  - - P22 - - P24 - - - M21 - P19 - - P17 -
  - P19 - - P22 - - P24 - M21 - P19 - P17 - -
|:16 |> repeat(2) |> voice(BellGlass)

let frost = |
  - - P24 - M21 - - P22 - - P19 - P17 - - P15 -
  - P22 - - P24 - - M21 - P19 - - P17 - M14 - -
|:16 |> repeat(2) |> voice(GrainFarShimmer)

layer [pulse, snap, ticks, bass_core, bass, lead, lead_edge, answer, answer_glass, stars, frost]
```

## Broken Modal Machine

Odd-meter cells, but mixed as a band: dry low bass, centered kick,
snare pressure, animated hats, a wide pad, and a lead that jumps across
registers instead of sitting in one narrow strip.

```rela
synth DeepKick = { osc: Sine, env: envelope(0.001, 0.12, 0.0, 0.08), filter: LowPass(55, 0.1) }
synth RoomSnare = { osc: Noise, env: envelope(0.001, 0.11, 0.0, 0.18), filter: BandPass(1900, 0.55), detune: 8 }
synth WideHat = { osc: Noise, env: envelope(0.001, 0.045, 0.0, 0.08), filter: HighPass(8200, 0.7), detune: 18 }
synth DeepSub = { osc: Sine, env: envelope(0.01, 0.22, 0.95, 0.35), filter: LowPass(54, 0.0) }
synth BassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.82, 0.25), filter: LowPass(640, 0.65), detune: 14 }
synth AcidEdge = { osc: Saw, env: envelope(0.004, 0.12, 0.7, 0.18), filter: LowPass(1180, 0.92), detune: 9 }
synth RhodesBody = { osc: FM(Sine, 2.98, 0.33), env: envelope(0.006, 0.24, 0.58, 0.8), filter: LowPass(7600, 0.25) }
synth PadBloom = { osc: Saw, env: envelope(0.34, 0.4, 0.82, 1.4), filter: LowPass(2300, 0.32), detune: 22 }
synth GlassPad = { osc: Triangle, env: envelope(0.28, 0.35, 0.76, 1.2), filter: LowPass(3400, 0.2), detune: 18 }
synth WaveFormantPan = { osc: Wavetable(Formant), env: envelope(0.02, 0.22, 0.62, 0.45), filter: BandPass(3600, 0.7), detune: 20 }
synth WaveVaporPan = { osc: Wavetable(Vapor), env: envelope(0.02, 0.18, 0.65, 0.4), filter: BandPass(4200, 0.56), detune: 24 }
synth WaveSupersawPan = { osc: Saw, env: envelope(0.02, 0.25, 0.7, 0.5), filter: BandPass(3900, 0.5), detune: 34 }
synth GrainFarShimmer = { osc: Granular(Shimmer), env: envelope(0.08, 0.25, 0.55, 0.95), filter: BandPass(5200, 0.75), detune: 28 }
synth GrainFarDrift = { osc: Granular(Drift), env: envelope(0.18, 0.4, 0.68, 1.3), filter: BandPass(2600, 0.55), detune: 24 }
synth GrainFarVocal = { osc: Granular(Vocal), env: envelope(0.06, 0.3, 0.6, 0.9), filter: BandPass(2100, 0.8), detune: 16 }
synth BellGlass = { osc: FM(Sine, 3.97, 0.58), env: envelope(0.003, 0.28, 0.18, 0.8), filter: LowPass(10400, 0.2) }
synth KalimbaBell = { osc: FM(Sine, 4.2, 0.5), env: envelope(0.003, 0.2, 0.22, 0.62), filter: LowPass(9800, 0.18) }
synth FatBassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.84, 0.28), filter: LowPass(520, 0.72), detune: 18 }
synth SoftPadAir = { osc: Triangle, env: envelope(0.38, 0.35, 0.8, 1.5), filter: LowPass(2100, 0.28), detune: 16 }
synth ModularLeadPan = { osc: Saw, env: envelope(0.01, 0.16, 0.55, 0.35), filter: BandPass(4200, 0.78), detune: 21 }

set key = G1
set tempo = 126

let kick = | R - - R - - R - |:5 |> repeat(8) |> voice(DeepKick)
let snare = | - - P8 - - P8 - |:7 |> repeat(6) |> voice(RoomSnare)
let hats = | P15 P15 - P15 - P15 P15 - |:5 |> repeat(8) |> voice(WideHat)

let bass = |
  R - P5 - m7 - P5 - R - M3 - P5 - m7 -
  R - P4 - M6 - P5 - m7 - P5 - M3 - R -
|:20 |> repeat(2) |> voice(FatBassBody)

let pad = |
  [P8, m10, P12] - [P5, m7, m10] - [M6, P8, M10] -
  [P4, M6, P8] - [P5, m7, M10] - [P8, m10, P12] -
|:20 |> repeat(2) |> voice(SoftPadAir)

let lead = |
  P12 - M14 P15 - M14 P12 - M10 - P12 M14 - P12 M10 -
  P15 - M17 P19 - M17 P15 - P12 - M14 P15 - M14 P12 -
|:20 |> repeat(2) |> voice(ModularLeadPan)

let sparks = |
  - - P22 - - P19 - - - M17 - P15 - - M14 -
  - P24 - - P22 - P19 - - M17 - P15 - M14 - -
|:20 |> repeat(2) |> voice(KalimbaBell)

layer [kick, snare, hats, bass, pad, lead, sparks]
```

## Airlock Arpeggio

Wavetable motion with a controlled low end. The high bell and formant
parts test whether the preview can stay bright without becoming cheap
or brittle.

```rela
synth DeepKick = { osc: Sine, env: envelope(0.001, 0.12, 0.0, 0.08), filter: LowPass(55, 0.1) }
synth RoomSnare = { osc: Noise, env: envelope(0.001, 0.11, 0.0, 0.18), filter: BandPass(1900, 0.55), detune: 8 }
synth WideHat = { osc: Noise, env: envelope(0.001, 0.045, 0.0, 0.08), filter: HighPass(8200, 0.7), detune: 18 }
synth DeepSub = { osc: Sine, env: envelope(0.01, 0.22, 0.95, 0.35), filter: LowPass(54, 0.0) }
synth BassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.82, 0.25), filter: LowPass(640, 0.65), detune: 14 }
synth AcidEdge = { osc: Saw, env: envelope(0.004, 0.12, 0.7, 0.18), filter: LowPass(1180, 0.92), detune: 9 }
synth RhodesBody = { osc: FM(Sine, 2.98, 0.33), env: envelope(0.006, 0.24, 0.58, 0.8), filter: LowPass(7600, 0.25) }
synth PadBloom = { osc: Saw, env: envelope(0.34, 0.4, 0.82, 1.4), filter: LowPass(2300, 0.32), detune: 22 }
synth GlassPad = { osc: Triangle, env: envelope(0.28, 0.35, 0.76, 1.2), filter: LowPass(3400, 0.2), detune: 18 }
synth WaveFormantPan = { osc: Wavetable(Formant), env: envelope(0.02, 0.22, 0.62, 0.45), filter: BandPass(3600, 0.7), detune: 20 }
synth WaveVaporPan = { osc: Wavetable(Vapor), env: envelope(0.02, 0.18, 0.65, 0.4), filter: BandPass(4200, 0.56), detune: 24 }
synth WaveSupersawPan = { osc: Saw, env: envelope(0.02, 0.25, 0.7, 0.5), filter: BandPass(3900, 0.5), detune: 34 }
synth GrainFarShimmer = { osc: Granular(Shimmer), env: envelope(0.08, 0.25, 0.55, 0.95), filter: BandPass(5200, 0.75), detune: 28 }
synth GrainFarDrift = { osc: Granular(Drift), env: envelope(0.18, 0.4, 0.68, 1.3), filter: BandPass(2600, 0.55), detune: 24 }
synth GrainFarVocal = { osc: Granular(Vocal), env: envelope(0.06, 0.3, 0.6, 0.9), filter: BandPass(2100, 0.8), detune: 16 }
synth BellGlass = { osc: FM(Sine, 3.97, 0.58), env: envelope(0.003, 0.28, 0.18, 0.8), filter: LowPass(10400, 0.2) }
synth KalimbaBell = { osc: FM(Sine, 4.2, 0.5), env: envelope(0.003, 0.2, 0.22, 0.62), filter: LowPass(9800, 0.18) }
synth FatBassBody = { osc: Saw, env: envelope(0.006, 0.18, 0.84, 0.28), filter: LowPass(520, 0.72), detune: 18 }
synth SoftPadAir = { osc: Triangle, env: envelope(0.38, 0.35, 0.8, 1.5), filter: LowPass(2100, 0.28), detune: 16 }
synth ModularLeadPan = { osc: Saw, env: envelope(0.01, 0.16, 0.55, 0.35), filter: BandPass(4200, 0.78), detune: 21 }

set key = B1
set tempo = 132

let root = |
  R - P5 - M7 - P5 - R - M3 - P5 - M7 -
  R - P5 - M6 - P5 - P4 - R - P5 - M3 -
|:16 |> repeat(2) |> voice(DeepSub)

let root_harm = |
  P8 - P12 - M14 - P12 - P8 - M10 - P12 - M14 -
  P8 - P12 - M13 - P12 - P8 - M10 - P12 - M10 -
|:16 |> repeat(2) |> voice(FatBassBody)

let vapor = |
  P8 M10 P12 M14 P12 M10 P8 M10 P12 M14 P15 M14 P12 M10 P8 -
  P12 M14 P15 M17 P15 M14 P12 M10 P8 M10 P12 M14 P12 M10 P8 -
|:16 |> repeat(2) |> voice(WaveSupersawPan)

let vapor_keys = |
  [P8, P12, M14] - - [M10, M14, P15] - - [P12, P15, M17] -
  [M10, P12, M14] - - [P8, M10, P12] - [P5, M7, P9] -
|:16 |> repeat(2) |> voice(RhodesBody)

let formant = |
  - P15 - M17 - P19 - M17 - M14 - P15 - M17 - P19
  - P19 - M21 - P22 - M21 - P19 - M17 - P15 - M14
|:16 |> repeat(2) |> voice(WaveFormantPan)

let bell = |
  P19 - - P22 - M21 - P19 - P22 - P24 - M21 - P19
  - P24 - - P26 - P24 - P22 - M21 - P19 - M17 -
|:16 |> repeat(2) |> voice(BellGlass)

let cloud = |
  - - [P8, P12, M17] - - [M10, M14, P19] - -
  [P12, P15, P22] - - [M10, M14, M21] - - [P8, P12, M17] -
|:16 |> repeat(2) |> voice(PadBloom)

let cloud_grain = |
  - P22 - - P24 - - M21 - P19 - - M17 - P15 - -
  - - P24 - M21 - - P22 - - P19 - M17 - P15 -
|:16 |> repeat(2) |> voice(GrainFarDrift)

layer [root, root_harm, vapor, vapor_keys, formant, bell, cloud, cloud_grain]
```
