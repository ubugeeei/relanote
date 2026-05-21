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

The first sketch is a synthetic session sample: piano, drums, upright
bass, guitar, and sax are split into attack, body, resonance, air, and
overtone layers. It is still synthesis, but the palette leans toward
the acoustic cues that make real instruments feel alive.

## Micro Detail Maximal Mix

A dense, high-tempo mix study where the arrangement is intentionally
too large to feel like a single preset. The parts are split into close
transients, body layers, ghost reflections, orbiting leads, delayed bell
throws, grain dust, and far-room pads so the preview engine can turn
small named details into spatial motion.

```rela
synth KickSubCenter = {
  osc: (Sine |> mix 0.86) +
       (Triangle |> mix 0.14),
  env: envelope(0.001, 0.18, 0.0, 0.14),
  filter: LowPass(92, 0.08),
  pitch_env: (165, 38, 0.07)
}

synth KickClickNear = {
  osc: (Noise |> mix 0.22) +
       (Triangle |> mix 0.5) +
       (Sine |> mix 0.28 |> octave 1),
  env: envelope(0.001, 0.055, 0.0, 0.05),
  filter: BandPass(3400, 0.46)
}

synth SnareBodyNear = {
  osc: (Noise |> mix 0.52) +
       (Triangle |> mix 0.34) +
       (Sine |> mix 0.14),
  env: envelope(0.001, 0.13, 0.0, 0.24),
  filter: BandPass(2100, 0.52),
  detune: 7
}

synth SnareGhostFar = {
  osc: (Noise |> mix 0.72) +
       (Triangle |> mix 0.18) +
       (Sine |> mix 0.1 |> octave 1),
  env: envelope(0.004, 0.28, 0.0, 0.45),
  filter: BandPass(3100, 0.42),
  detune: 13
}

synth HatTickLeft = {
  osc: Noise,
  env: envelope(0.001, 0.035, 0.0, 0.05),
  filter: HighPass(8200, 0.42)
}

synth HatTickRight = {
  osc: Noise,
  env: envelope(0.001, 0.035, 0.0, 0.05),
  filter: HighPass(9000, 0.36)
}

synth HatAirScatter = {
  osc: (Noise |> mix 0.8) +
       (Triangle |> mix 0.2 |> octave 2),
  env: envelope(0.001, 0.07, 0.0, 0.12),
  filter: HighPass(7200, 0.28),
  detune: 21
}

synth DustTickScatter = {
  osc: (Noise |> mix 0.64) +
       (FM(Sine, 7.01, 0.16) |> mix 0.36),
  env: envelope(0.001, 0.045, 0.0, 0.12),
  filter: HighPass(6400, 0.5),
  detune: 24
}

synth SubCenter = {
  osc: (Sine |> mix 0.78) +
       (Triangle |> mix 0.22 |> octave (-1)),
  env: envelope(0.008, 0.24, 0.9, 0.38),
  filter: LowPass(120, 0.06)
}

synth BassGrowlCenter = {
  osc: (Saw |> mix 0.42) +
       (Triangle |> mix 0.32) +
       (Sine |> mix 0.26 |> octave (-1)),
  env: envelope(0.01, 0.2, 0.72, 0.28),
  filter: LowPass(680, 0.7),
  detune: 12
}

synth BassFingerMicro = {
  osc: (Triangle |> mix 0.42) +
       (Noise |> mix 0.2) +
       (Sine |> mix 0.38 |> octave 1),
  env: envelope(0.004, 0.12, 0.22, 0.18),
  filter: BandPass(1600, 0.42),
  detune: 5
}

synth FeltPianoNear = {
  osc: (Triangle |> mix 0.38) +
       (Sine |> mix 0.28) +
       (Noise |> mix 0.14) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.004, 0.42, 0.26, 1.0),
  filter: LowPass(5600, 0.2),
  detune: 2
}

synth FeltPianoRoom = {
  osc: (Triangle |> mix 0.4) +
       (Sine |> mix 0.34 |> octave (-1)) +
       (Sine |> mix 0.26 |> octave 1),
  env: envelope(0.03, 0.8, 0.5, 1.6),
  filter: LowPass(3800, 0.16),
  detune: 5
}

synth EPianoTineOrbit = {
  osc: (FM(Sine, 2.98, 0.36) |> mix 0.48) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.18 |> octave 1) +
       (Sine |> mix 0.12 |> octave 2),
  env: envelope(0.006, 0.72, 0.34, 1.2),
  filter: LowPass(6600, 0.18),
  detune: 4
}

synth EPianoBarkRight = {
  osc: (FM(Sine, 1.99, 0.52) |> mix 0.34) +
       (Saw |> mix 0.26) +
       (Triangle |> mix 0.22) +
       (Noise |> mix 0.18),
  env: envelope(0.004, 0.2, 0.24, 0.5),
  filter: BandPass(2800, 0.36),
  detune: 8
}

synth GuitarPickLeft = {
  osc: (Noise |> mix 0.12) +
       (Triangle |> mix 0.36) +
       (Sine |> mix 0.28 |> octave 1) +
       (Saw |> mix 0.24 |> osc_detune (-5)),
  env: envelope(0.004, 0.24, 0.24, 0.4),
  filter: BandPass(3400, 0.38)
}

synth GuitarGhostFar = {
  osc: (Triangle |> mix 0.36) +
       (Sine |> mix 0.28) +
       (Saw |> mix 0.2 |> osc_detune 7) +
       (Sine |> mix 0.16 |> octave 2),
  env: envelope(0.02, 0.42, 0.36, 0.82),
  filter: HighPass(1700, 0.26),
  detune: 9
}

synth SaxReedNear = {
  osc: (Saw |> mix 0.34) +
       (Triangle |> mix 0.28) +
       (Square |> mix 0.16) +
       (Sine |> mix 0.22 |> octave 1),
  env: envelope(0.07, 0.2, 0.84, 0.68),
  filter: BandPass(1700, 0.46),
  detune: 4
}

synth SaxBellDelay = {
  osc: (Triangle |> mix 0.4) +
       (Saw |> mix 0.32 |> osc_detune 5) +
       (Sine |> mix 0.28 |> octave 1),
  env: envelope(0.08, 0.34, 0.72, 0.95),
  filter: LowPass(5600, 0.18),
  detune: 6
}

synth LeadCenter = {
  osc: (Saw |> mix 0.32 |> osc_detune (-6)) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.22 |> octave 1) +
       (FM(Sine, 1.51, 0.12) |> mix 0.18),
  env: envelope(0.035, 0.28, 0.74, 0.62),
  filter: LowPass(5200, 0.28),
  detune: 7
}

synth LeadOrbit = {
  osc: (Wavetable(Vapor) |> mix 0.34) +
       (Saw |> mix 0.26 |> osc_detune 11) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.18 |> octave 1),
  env: envelope(0.045, 0.34, 0.72, 0.82),
  filter: LowPass(6800, 0.24),
  detune: 14
}

synth FormantSwerve = {
  osc: (Wavetable(Formant) |> mix 0.46) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.26 |> octave 1),
  env: envelope(0.05, 0.32, 0.66, 0.8),
  filter: BandPass(3200, 0.42),
  detune: 11
}

synth StringHaloFar = {
  osc: (Saw |> mix 0.26 |> osc_detune (-8)) +
       (Saw |> mix 0.26 |> osc_detune 8) +
       (Triangle |> mix 0.26) +
       (Sine |> mix 0.22 |> octave 1),
  env: envelope(0.2, 0.42, 0.82, 1.5),
  filter: LowPass(4200, 0.2),
  detune: 17
}

synth PadWashFar = {
  osc: (Wavetable(Vapor) |> mix 0.3) +
       (Saw |> mix 0.24 |> osc_detune (-13)) +
       (Saw |> mix 0.24 |> osc_detune 13) +
       (Sine |> mix 0.22 |> octave 1),
  env: envelope(0.45, 0.5, 0.84, 1.8),
  filter: LowPass(2400, 0.2),
  detune: 24
}

synth DustMistFar = {
  osc: (Granular(Drift) |> mix 0.5) +
       (Noise |> mix 0.28) +
       (Sine |> mix 0.22 |> octave 2),
  env: envelope(0.12, 0.36, 0.58, 1.2),
  filter: BandPass(4200, 0.58),
  detune: 30
}

synth BellThrowLeft = {
  osc: (FM(Sine, 3.97, 0.44) |> mix 0.5) +
       (Sine |> mix 0.28 |> octave 1) +
       (Triangle |> mix 0.22),
  env: envelope(0.006, 0.85, 0.2, 1.2),
  filter: LowPass(9300, 0.12)
}

synth BellThrowRight = {
  osc: (FM(Sine, 4.21, 0.38) |> mix 0.52) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.24 |> octave 1),
  env: envelope(0.005, 0.62, 0.18, 1.0),
  filter: LowPass(8800, 0.12)
}

synth VocalGrainFar = {
  osc: (Granular(Vocal) |> mix 0.54) +
       (Triangle |> mix 0.24) +
       (Noise |> mix 0.22),
  env: envelope(0.08, 0.35, 0.62, 1.1),
  filter: BandPass(2200, 0.72),
  detune: 18
}

synth ShimmerAirPan = {
  osc: (Granular(Shimmer) |> mix 0.56) +
       (Sine |> mix 0.24 |> octave 2) +
       (Noise |> mix 0.2),
  env: envelope(0.08, 0.28, 0.52, 1.0),
  filter: HighPass(5200, 0.24),
  detune: 31
}

synth RoomBloomFar = {
  osc: (Triangle |> mix 0.36) +
       (Sine |> mix 0.3 |> octave (-1)) +
       (Wavetable(Vapor) |> mix 0.34),
  env: envelope(0.36, 0.48, 0.86, 1.7),
  filter: LowPass(2100, 0.18),
  detune: 16
}

set key = D1
set tempo = 184

let kick_sub = |
  R - - - - R - - - - R - - - R -
  R - - - - - R - - R - - - - R -
|:16 |> repeat(4) |> voice(KickSubCenter)

let kick_click = |
  P8 - - - - P8 - - - - P8 - - - P8 -
  P8 - - - - - P8 - - P8 - - - - P8 -
|:16 |> repeat(4) |> voice(KickClickNear)

let snare_body = |
  - - - - P8 - - - - - - - P8 - - -
  - - - - P8 - - P8 - - - - P8 - P8 -
|:16 |> repeat(4) |> voice(SnareBodyNear)

let snare_ghost = |
  - - - - - - P8 - - - - - - - - P8
  - P8 - - - - - - - - P8 - - - - -
|:16 |> repeat(4) |> voice(SnareGhostFar)

let hats_left = |
  P15 - P15 - P15 - P15 P15 - P15 - P15 P15 - P15 -
  P15 P15 - P15 - P15 P15 - P15 - P15 P15 - P15 - P15
|:16 |> repeat(4) |> voice(HatTickLeft)

let hats_right = |
  - P15 - P15 P15 - P15 - P15 - P15 - - P15 - P15
  P15 - P15 P15 - P15 - P15 - P15 P15 - P15 - P15 -
|:16 |> repeat(4) |> voice(HatTickRight)

let hat_air = |
  - - P22 - - P24 - - P22 - - P19 - - P21 -
  P24 - - P22 - - P21 - - P19 - P22 - - P24 -
|:16 |> repeat(4) |> voice(HatAirScatter)

let dust_tick = |
  - P26 - - P24 - P22 - - P26 - P24 - - P21 -
  P24 - - P26 - P22 - - P24 - P21 - - P26 - -
|:16 |> repeat(4) |> voice(DustTickScatter)

let sub = |
  R~ - - - P5 - R - m7~ - - - P5 - R -
  R - P5 - M6~ - - - P5 - P4 - M3 - R -
|:16 |> repeat(4) |> voice(SubCenter)

let bass_growl = |
  P8 - P5 P8 - m7 P8 M10 P8 - P12 - M10 - P8 -
  P8 - M10 - P12 - M14 P12 - M10 - P8 - P5 -
|:16 |> repeat(4) |> voice(BassGrowlCenter)

let bass_finger = |
  - P8 - P5 - M10 - P8 - P12 - M10 - P8 -
  - M10 - P12 - M14 - P12 - M10 - P8 - P5 -
|:16 |> repeat(4) |> voice(BassFingerMicro)

let piano_near = |
  [P8, M10, P12, M14] - [M9, P12, M14] - [P5, M7, P9, M13] -
  [M6, P8, M10, P15] - [P4, M6, P8, M14] - [P5, M7, M10, P14] -
|:16 |> repeat(4) |> voice(FeltPianoNear)

let piano_room = |
  [P12, M14, P15] - - - [M9, P12, M14] - - -
  [P8, M10, P12] - - - [M6, P8, M10] - - -
|:16 |> repeat(4) |> voice(FeltPianoRoom)

let epiano_tine = |
  - P12 M14 - P15 - M17 P19 - M17 P15 - M14 - P12 -
  - M10 P12 - M14 - P15 M17 - P15 M14 - P12 - M10 -
|:16 |> repeat(4) |> voice(EPianoTineOrbit)

let epiano_bark = |
  - - [P12, M14] - - [P15, M17] - - [M10, P12] - - [M14, P15] -
  - [P8, M10] - - [P12, M14] - - [P15, M17] - [M14, P15] - -
|:16 |> repeat(4) |> voice(EPianoBarkRight)

let guitar_pick = |
  P12 P15 M17 P19 M17 P15 P12 M10 P12 M14 P15 M17 P15 M14 P12 M10
  M9 P12 M14 P15 M14 P12 M9 P8 P12 M14 P15 M17 M14 P12 M10 P8
|:16 |> repeat(4) |> voice(GuitarPickLeft)

let guitar_ghost = |
  - P19 - M21 - P22 - P19 - M17 - P15 - M14 -
  - P22 - P24 - M21 - P19 - M17 - P15 - P12 -
|:16 |> repeat(4) |> voice(GuitarGhostFar)

let sax_reed = |
  - - P12 M14 P15 - M17 P19 - M17 P15 M14 P12 - M10 -
  P12 - M14 P15 M17 - P19 M21 P22 - M21 P19 M17 P15 M14 -
|:16 |> repeat(4) |> voice(SaxReedNear)

let sax_bell = |
  - - - P24 - - M21 - - P22 - - P19 - - M17
  - P22 - - P24 - M21 - P19 - - M17 - P15 - -
|:16 |> repeat(4) |> voice(SaxBellDelay)

let lead_center = |
  P12 - M14 P15 - M17 P19 - M17 - P15 M14 P12 - M10 -
  P12 M14 P15 - M17 P19 - P22 M21 P19 - M17 P15 M14 P12 -
|:16 |> repeat(4) |> voice(LeadCenter)

let lead_orbit = |
  - P19 - P22 M21 - P19 - M17 P19 - P22 - P24 - M21
  - P22 M21 P19 - M17 P15 - M14 P15 - M17 - P19 - P22
|:16 |> repeat(4) |> voice(LeadOrbit)

let formant_swerve = |
  - P15 - M17 - P19 - M17 - M14 - P15 - M17 - P19
  - P22 - M21 - P19 - M17 - P15 - M14 - P12 -
|:16 |> repeat(4) |> voice(FormantSwerve)

let strings = |
  [P8, P12, P15] - - - [M9, M14, M17] - - -
  [P5, P12, M17] - - - [M6, M10, P15] - - -
|:16 |> repeat(4) |> voice(StringHaloFar)

let pad = |
  [P12, M14, P15, M17] - - - [M10, P12, M14, P19] - - -
  [P8, M10, P12, P17] - - - [M6, P8, M10, M14] - - -
|:16 |> repeat(4) |> voice(PadWashFar)

let dust_mist = |
  - - P24 - - M21 - - P22 - - P19 - - M17 -
  - P22 - - P24 - - M21 - P19 - - M17 - P15 -
|:16 |> repeat(4) |> voice(DustMistFar)

let bells_left = |
  - - P24 - - - M21 - - P22 - - - P19 - -
  - P22 - - - P24 - - M21 - - P19 - - M17 -
|:16 |> repeat(4) |> voice(BellThrowLeft)

let bells_right = |
  - P26 - - P24 - - P22 - - P21 - - P19 - -
  P24 - - P26 - - P22 - P24 - - P21 - - P19 -
|:16 |> repeat(4) |> voice(BellThrowRight)

let vocal_grain = |
  - - P17~ - - P19~ - - M21~ - - P22~ - - P19~ -
  - M17~ - - P19~ - - P22~ - - P24~ - - M21~ -
|:16 |> repeat(4) |> voice(VocalGrainFar)

let shimmer = |
  - - - P29 - - P31 - - M28 - - P26 - - P24
  - P31 - - P29 - - P26 - P24 - - M21 - - P22
|:16 |> repeat(4) |> voice(ShimmerAirPan)

let room_bloom = |
  [P5, P8, P12] - - - [M6, M10, M14] - - -
  [P4, M9, P12] - - - [P5, M10, P14] - - -
|:16 |> repeat(4) |> voice(RoomBloomFar)

layer [
  kick_sub, kick_click, snare_body, snare_ghost,
  hats_left, hats_right, hat_air, dust_tick,
  sub, bass_growl, bass_finger,
  piano_near, piano_room, epiano_tine, epiano_bark,
  guitar_pick, guitar_ghost,
  sax_reed, sax_bell,
  lead_center, lead_orbit, formant_swerve,
  strings, pad, dust_mist,
  bells_left, bells_right, vocal_grain, shimmer, room_bloom
]
```

## Synthetic Session Sample

A high-tempo fusion study built from component models instead of single
presets. Piano is hammer noise, string body, and soundboard bloom;
drums are shell, wire, metal, and room; bass is fundamental, finger
attack, and wood resonance; guitar is pick, body, and upper harmonics;
sax is reed pressure, breath noise, and bell air.

```rela
synth PianoHammer = {
  osc: (Noise |> mix 0.12) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.6),
  env: envelope(0.004, 0.18, 0.12, 0.28),
  filter: BandPass(4100, 0.32)
}

synth PianoStrings = {
  osc: (Sine |> mix 0.42) +
       (Triangle |> mix 0.28 |> octave 1) +
       (Sine |> mix 0.2 |> octave 2) +
       (Saw |> mix 0.1 |> osc_detune 3),
  env: envelope(0.006, 0.72, 0.3, 1.1),
  filter: LowPass(6800, 0.18)
}

synth PianoSoundboard = {
  osc: (Triangle |> mix 0.46) +
       (Sine |> mix 0.34 |> octave (-1)) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.035, 0.9, 0.42, 1.4),
  filter: LowPass(4200, 0.16),
  detune: 4
}

synth EPianoTine = {
  osc: (FM(Sine, 2.98, 0.32) |> mix 0.44) +
       (Sine |> mix 0.2) +
       (Triangle |> mix 0.2 |> octave 1) +
       (Sine |> mix 0.16 |> octave 2),
  env: envelope(0.006, 0.72, 0.28, 1.15),
  filter: LowPass(6400, 0.18),
  detune: 3
}

synth EPianoPickup = {
  osc: (Triangle |> mix 0.34) +
       (Saw |> mix 0.22 |> osc_detune (-5)) +
       (Sine |> mix 0.24 |> octave 1) +
       (Noise |> mix 0.2),
  env: envelope(0.005, 0.34, 0.34, 0.72),
  filter: BandPass(3200, 0.36),
  detune: 5
}

synth EPianoBark = {
  osc: (FM(Sine, 1.99, 0.5) |> mix 0.36) +
       (Saw |> mix 0.24) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.18 |> octave 1),
  env: envelope(0.004, 0.24, 0.22, 0.55),
  filter: LowPass(5200, 0.28),
  detune: 7
}

synth StudioKickShell = {
  osc: (Sine |> mix 0.82) + (Triangle |> mix 0.18),
  env: envelope(0.001, 0.18, 0.0, 0.12),
  filter: LowPass(120, 0.18),
  pitch_env: (155, 42, 0.075)
}

synth StudioSnareWire = {
  osc: (Noise |> mix 0.68) + (Triangle |> mix 0.32),
  env: envelope(0.001, 0.12, 0.0, 0.22),
  filter: BandPass(2300, 0.48)
}

synth StudioHatMetal = {
  osc: Noise,
  env: envelope(0.001, 0.055, 0.0, 0.08),
  filter: HighPass(7600, 0.38)
}

synth UprightBassFund = {
  osc: (Sine |> mix 0.58) +
       (Triangle |> mix 0.28) +
       (Saw |> mix 0.14 |> octave (-1)),
  env: envelope(0.025, 0.28, 0.72, 0.5),
  filter: LowPass(920, 0.24)
}

synth UprightBassFinger = {
  osc: (Triangle |> mix 0.48) +
       (Noise |> mix 0.18) +
       (Sine |> mix 0.34 |> octave 1),
  env: envelope(0.006, 0.16, 0.18, 0.24),
  filter: BandPass(1450, 0.42)
}

synth UprightBassWood = {
  osc: (Sine |> mix 0.44 |> octave (-1)) +
       (Triangle |> mix 0.36) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.04, 0.5, 0.64, 0.75),
  filter: LowPass(1500, 0.18),
  detune: 3
}

synth GuitarPick = {
  osc: (Noise |> mix 0.12) +
       (Triangle |> mix 0.36) +
       (Sine |> mix 0.28 |> octave 1) +
       (Saw |> mix 0.24 |> osc_detune (-4)),
  env: envelope(0.004, 0.26, 0.28, 0.42),
  filter: BandPass(3300, 0.38)
}

synth GuitarBody = {
  osc: (Triangle |> mix 0.42) +
       (Sine |> mix 0.38) +
       (Sine |> mix 0.2 |> octave (-1)),
  env: envelope(0.012, 0.38, 0.48, 0.7),
  filter: LowPass(3600, 0.16)
}

synth GuitarHarmonics = {
  osc: (Sine |> mix 0.42 |> octave 1) +
       (Triangle |> mix 0.28 |> octave 2) +
       (Saw |> mix 0.3 |> osc_detune 6),
  env: envelope(0.01, 0.34, 0.2, 0.58),
  filter: HighPass(2400, 0.24),
  detune: 5
}

synth SaxReedCore = {
  osc: (Saw |> mix 0.32) +
       (Triangle |> mix 0.3) +
       (Square |> mix 0.18) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.075, 0.22, 0.86, 0.7),
  filter: BandPass(1750, 0.46),
  detune: 3
}

synth SaxBreathNoise = {
  osc: (Noise |> mix 0.36) +
       (Triangle |> mix 0.34) +
       (Sine |> mix 0.3),
  env: envelope(0.08, 0.2, 0.58, 0.85),
  filter: BandPass(2650, 0.34)
}

synth SaxBellAir = {
  osc: (Triangle |> mix 0.4) +
       (Sine |> mix 0.28 |> octave 1) +
       (Saw |> mix 0.32 |> osc_detune 5),
  env: envelope(0.09, 0.3, 0.76, 0.9),
  filter: LowPass(5400, 0.2),
  detune: 4
}

set key = Bb1
set tempo = 168

let kick = |
  R - - - - R - - - - R - - - R -
  R - - - - - R - - R - - - - R -
|:16 |> repeat(3) |> voice(StudioKickShell)

let snare = |
  - - - - P8 - - - - - - - P8 - - -
  - - - - P8 - - P8 - - - - P8 - P8 -
|:16 |> repeat(3) |> voice(StudioSnareWire)

let hats = |
  P15 - P15 P15 - P15 - P15 P15 - P15 - - P15 P15 -
  P15 P15 - P15 - P15 P15 - P15 - P15 P15 - P15 - P15
|:16 |> repeat(3) |> voice(StudioHatMetal)

let piano_hammers = |
  [R, M3, P5, M7] - [M2, P4, M6] - [P4, M6, M7, P12] -
  [P5, M7, M9, P12] - [M6, P8, M10, M14] - [P4, M6, P9] -
  [R, M3, P5, M9] - [M2, P4, M6, P11] - [P5, M7, P12] -
  [M6, P8, M10] - [P4, M6, M9, P12] - [P5, M7, M10] -
|:16 |> repeat(1) |> voice(PianoHammer)

let piano_strings = |
  [R, M3, P5, M7] - - [M2, P4, M6, M9] - - [P4, M6, P8, P12] -
  [P5, M7, M9, P12] - - [M6, P8, M10, M14] - [P4, M6, P9, P12] -
  [R, M3, P5, M9] - - [M2, P4, M6, P11] - - [P5, M7, P12, M14] -
  [M6, P8, M10, P15] - [P4, M6, M9, P12] - [P5, M7, M10, P14] -
|:16 |> repeat(1) |> voice(PianoStrings)

let piano_board = |
  [P8, M10, P12] - - - [M9, P12, M14] - - -
  [P12, M14, P15] - - - [M10, P12, M14] - - -
|:16 |> repeat(3) |> voice(PianoSoundboard)

let epiano_tine = |
  [P8, M10, P12, M14] - [M9, P12, M14] - [P5, M7, P9, M13] -
  [M6, P8, M10, P15] - [P4, M6, P8, M14] - [P5, M7, M10, P14] -
|:16 |> repeat(3) |> voice(EPianoTine)

let epiano_pickup = |
  - P12 M14 - P15 - M17 P19 - M17 P15 - M14 - P12 -
  - M10 P12 - M14 - P15 M17 - P15 M14 - P12 - M10 -
|:16 |> repeat(3) |> voice(EPianoPickup)

let epiano_bark = |
  - - [P12, M14] - - [P15, M17] - - [M10, P12] - - [M14, P15] -
  - [P8, M10] - - [P12, M14] - - [P15, M17] - [M14, P15] - -
|:16 |> repeat(3) |> voice(EPianoBark)

let bass_fund = |
  R - P5 - M6 - P5 - P4 - R - P5 - M3 -
  R - M7 - P5 - M6 - P5 - P4 - M3 - P5 -
|:16 |> repeat(3) |> voice(UprightBassFund)

let bass_finger = |
  - P8 - P5 - M10 - P8 - P12 - M10 - P8 -
  - M10 - P12 - M14 - P12 - M10 - P8 - P5 -
|:16 |> repeat(3) |> voice(UprightBassFinger)

let bass_wood = |
  R~ - - - P5 - - - P4~ - - - P5 - M3 -
  R~ - - - M7 - - - M6~ - - - P5 - R -
|:16 |> repeat(3) |> voice(UprightBassWood)

let guitar_pick = |
  P12 P15 M17 P19 M17 P15 P12 M10 P12 M14 P15 M17 P15 M14 P12 M10
  M9 P12 M14 P15 M14 P12 M9 P8 P12 M14 P15 M17 M14 P12 M10 P8
|:16 |> repeat(3) |> voice(GuitarPick)

let guitar_body = |
  [P5, M10, P12] - - [P8, M12, P15] - - [P4, M9, P12] -
  [P5, M10, M14] - - [M6, P9, P12] - [P4, M7, P11] -
|:16 |> repeat(3) |> voice(GuitarBody)

let guitar_harmonics = |
  - P19 - M21 - P22 - P19 - M17 - P15 - M14 -
  - P22 - P24 - M21 - P19 - M17 - P15 - P12 -
|:16 |> repeat(3) |> voice(GuitarHarmonics)

let sax_reed = |
  - - P12 M14 P15 - M17 P19 - M17 P15 M14 P12 - M10 -
  P12 - M14 P15 M17 - P19 M21 P22 - M21 P19 M17 P15 M14 -
  - P15 M17 P19 P22 - M21 P19 - M17 P15 M14 P12 - M10 -
  P12 M14 P15 - M17 P19 - P22 M21 P19 - M17 P15 M14 P12 -
|:16 |> voice(SaxReedCore)

let sax_breath = |
  - - P12~ - P15~ - M17~ - - P19~ - M17~ - P15~ -
  P12~ - M14~ - P15~ - M17~ - P19~ - M21~ - P22~ -
|:16 |> repeat(2) |> voice(SaxBreathNoise)

let sax_air = |
  - - - P24 - - M21 - - P22 - - P19 - - M17
  - P22 - - P24 - M21 - P19 - - M17 - P15 - -
|:16 |> repeat(3) |> voice(SaxBellAir)

layer [
  kick, snare, hats,
  piano_hammers, piano_strings, piano_board,
  epiano_tine, epiano_pickup, epiano_bark,
  bass_fund, bass_finger, bass_wood,
  guitar_pick, guitar_body, guitar_harmonics,
  sax_reed, sax_breath, sax_air
]
```

## Composite Timbre Stack

A compact study in layered synthesis: every musical role is built from
several complementary synths instead of one preset carrying the whole
texture.

```rela
synth DeepKick = {
  osc: Sine,
  env: envelope(0.001, 0.12, 0.0, 0.08),
  filter: LowPass(55, 0.1)
}

synth RoomSnare = {
  osc: Noise,
  env: envelope(0.001, 0.11, 0.0, 0.18),
  filter: BandPass(1900, 0.55),
  detune: 8
}

synth WideHat = {
  osc: Noise,
  env: envelope(0.001, 0.045, 0.0, 0.08),
  filter: HighPass(8200, 0.7),
  detune: 18
}

synth DeepSub = {
  osc: Sine,
  env: envelope(0.01, 0.22, 0.95, 0.35),
  filter: LowPass(54, 0.0)
}

synth BassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.82, 0.25),
  filter: LowPass(640, 0.65),
  detune: 14
}

synth AcidEdge = {
  osc: Saw,
  env: envelope(0.004, 0.12, 0.7, 0.18),
  filter: LowPass(1180, 0.92),
  detune: 9
}

synth RhodesBody = {
  osc: FM(Sine, 2.98, 0.33),
  env: envelope(0.006, 0.24, 0.58, 0.8),
  filter: LowPass(7600, 0.25)
}

synth PadBloom = {
  osc: Saw,
  env: envelope(0.34, 0.4, 0.82, 1.4),
  filter: LowPass(2300, 0.32),
  detune: 22
}

synth GlassPad = {
  osc: Triangle,
  env: envelope(0.28, 0.35, 0.76, 1.2),
  filter: LowPass(3400, 0.2),
  detune: 18
}

synth WaveFormantPan = {
  osc: (Wavetable(Formant) |> mix 0.45) +
       (Triangle |> mix 0.3) +
       (Sine |> mix 0.25 |> octave 1),
  env: envelope(0.04, 0.32, 0.68, 0.75),
  filter: BandPass(3100, 0.42),
  detune: 10
}

synth WaveVaporPan = {
  osc: (Wavetable(Vapor) |> mix 0.34) +
       (Saw |> mix 0.24 |> osc_detune (-7)) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.045, 0.38, 0.72, 0.82),
  filter: LowPass(6100, 0.22),
  detune: 12
}

synth WaveSupersawPan = {
  osc: (Saw |> mix 0.28 |> osc_detune (-14)) +
       (Saw |> mix 0.28 |> osc_detune 14) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.035, 0.32, 0.76, 0.7),
  filter: LowPass(6800, 0.24),
  detune: 18
}

synth GrainFarShimmer = {
  osc: Granular(Shimmer),
  env: envelope(0.08, 0.25, 0.55, 0.95),
  filter: BandPass(5200, 0.75),
  detune: 28
}

synth GrainFarDrift = {
  osc: Granular(Drift),
  env: envelope(0.18, 0.4, 0.68, 1.3),
  filter: BandPass(2600, 0.55),
  detune: 24
}

synth GrainFarVocal = {
  osc: Granular(Vocal),
  env: envelope(0.06, 0.3, 0.6, 0.9),
  filter: BandPass(2100, 0.8),
  detune: 16
}

synth BellGlass = {
  osc: (FM(Sine, 3.97, 0.42) |> mix 0.55) +
       (Sine |> mix 0.25 |> octave 1) +
       (Triangle |> mix 0.2),
  env: envelope(0.006, 0.9, 0.22, 1.25),
  filter: LowPass(9200, 0.12)
}

synth KalimbaBell = {
  osc: (FM(Sine, 4.2, 0.38) |> mix 0.58) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.18 |> octave 1),
  env: envelope(0.005, 0.52, 0.18, 0.9),
  filter: LowPass(8600, 0.12)
}

synth FatBassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.84, 0.28),
  filter: LowPass(520, 0.72),
  detune: 18
}

synth SoftPadAir = {
  osc: Triangle,
  env: envelope(0.38, 0.35, 0.8, 1.5),
  filter: LowPass(2100, 0.28),
  detune: 16
}

synth ModularLeadPan = {
  osc: (Saw |> mix 0.34 |> osc_detune (-9)) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.22 |> octave 1) +
       (Saw |> mix 0.16 |> osc_detune 11),
  env: envelope(0.055, 0.32, 0.78, 0.85),
  filter: LowPass(5200, 0.28),
  detune: 9
}

set key = F1
set tempo = 154

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
synth DeepKick = {
  osc: Sine,
  env: envelope(0.001, 0.12, 0.0, 0.08),
  filter: LowPass(55, 0.1)
}

synth RoomSnare = {
  osc: Noise,
  env: envelope(0.001, 0.11, 0.0, 0.18),
  filter: BandPass(1900, 0.55),
  detune: 8
}

synth WideHat = {
  osc: Noise,
  env: envelope(0.001, 0.045, 0.0, 0.08),
  filter: HighPass(8200, 0.7),
  detune: 18
}

synth DeepSub = {
  osc: Sine,
  env: envelope(0.01, 0.22, 0.95, 0.35),
  filter: LowPass(54, 0.0)
}

synth BassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.82, 0.25),
  filter: LowPass(640, 0.65),
  detune: 14
}

synth AcidEdge = {
  osc: Saw,
  env: envelope(0.004, 0.12, 0.7, 0.18),
  filter: LowPass(1180, 0.92),
  detune: 9
}

synth RhodesBody = {
  osc: FM(Sine, 2.98, 0.33),
  env: envelope(0.006, 0.24, 0.58, 0.8),
  filter: LowPass(7600, 0.25)
}

synth PadBloom = {
  osc: Saw,
  env: envelope(0.34, 0.4, 0.82, 1.4),
  filter: LowPass(2300, 0.32),
  detune: 22
}

synth GlassPad = {
  osc: Triangle,
  env: envelope(0.28, 0.35, 0.76, 1.2),
  filter: LowPass(3400, 0.2),
  detune: 18
}

synth WaveFormantPan = {
  osc: (Wavetable(Formant) |> mix 0.45) +
       (Triangle |> mix 0.3) +
       (Sine |> mix 0.25 |> octave 1),
  env: envelope(0.04, 0.32, 0.68, 0.75),
  filter: BandPass(3100, 0.42),
  detune: 10
}

synth WaveVaporPan = {
  osc: (Wavetable(Vapor) |> mix 0.34) +
       (Saw |> mix 0.24 |> osc_detune (-7)) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.045, 0.38, 0.72, 0.82),
  filter: LowPass(6100, 0.22),
  detune: 12
}

synth WaveSupersawPan = {
  osc: (Saw |> mix 0.28 |> osc_detune (-14)) +
       (Saw |> mix 0.28 |> osc_detune 14) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.035, 0.32, 0.76, 0.7),
  filter: LowPass(6800, 0.24),
  detune: 18
}

synth GrainFarShimmer = {
  osc: Granular(Shimmer),
  env: envelope(0.08, 0.25, 0.55, 0.95),
  filter: BandPass(5200, 0.75),
  detune: 28
}

synth GrainFarDrift = {
  osc: Granular(Drift),
  env: envelope(0.18, 0.4, 0.68, 1.3),
  filter: BandPass(2600, 0.55),
  detune: 24
}

synth GrainFarVocal = {
  osc: Granular(Vocal),
  env: envelope(0.06, 0.3, 0.6, 0.9),
  filter: BandPass(2100, 0.8),
  detune: 16
}

synth BellGlass = {
  osc: (FM(Sine, 3.97, 0.42) |> mix 0.55) +
       (Sine |> mix 0.25 |> octave 1) +
       (Triangle |> mix 0.2),
  env: envelope(0.006, 0.9, 0.22, 1.25),
  filter: LowPass(9200, 0.12)
}

synth KalimbaBell = {
  osc: (FM(Sine, 4.2, 0.38) |> mix 0.58) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.18 |> octave 1),
  env: envelope(0.005, 0.52, 0.18, 0.9),
  filter: LowPass(8600, 0.12)
}

synth FatBassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.84, 0.28),
  filter: LowPass(520, 0.72),
  detune: 18
}

synth SoftPadAir = {
  osc: Triangle,
  env: envelope(0.38, 0.35, 0.8, 1.5),
  filter: LowPass(2100, 0.28),
  detune: 16
}

synth ModularLeadPan = {
  osc: (Saw |> mix 0.34 |> osc_detune (-9)) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.22 |> octave 1) +
       (Saw |> mix 0.16 |> osc_detune 11),
  env: envelope(0.055, 0.32, 0.78, 0.85),
  filter: LowPass(5200, 0.28),
  detune: 9
}

set key = D1
set tempo = 176

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
synth DeepKick = {
  osc: Sine,
  env: envelope(0.001, 0.12, 0.0, 0.08),
  filter: LowPass(55, 0.1)
}

synth RoomSnare = {
  osc: Noise,
  env: envelope(0.001, 0.11, 0.0, 0.18),
  filter: BandPass(1900, 0.55),
  detune: 8
}

synth WideHat = {
  osc: Noise,
  env: envelope(0.001, 0.045, 0.0, 0.08),
  filter: HighPass(8200, 0.7),
  detune: 18
}

synth DeepSub = {
  osc: Sine,
  env: envelope(0.01, 0.22, 0.95, 0.35),
  filter: LowPass(54, 0.0)
}

synth BassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.82, 0.25),
  filter: LowPass(640, 0.65),
  detune: 14
}

synth AcidEdge = {
  osc: Saw,
  env: envelope(0.004, 0.12, 0.7, 0.18),
  filter: LowPass(1180, 0.92),
  detune: 9
}

synth RhodesBody = {
  osc: FM(Sine, 2.98, 0.33),
  env: envelope(0.006, 0.24, 0.58, 0.8),
  filter: LowPass(7600, 0.25)
}

synth PadBloom = {
  osc: Saw,
  env: envelope(0.34, 0.4, 0.82, 1.4),
  filter: LowPass(2300, 0.32),
  detune: 22
}

synth GlassPad = {
  osc: Triangle,
  env: envelope(0.28, 0.35, 0.76, 1.2),
  filter: LowPass(3400, 0.2),
  detune: 18
}

synth WaveFormantPan = {
  osc: (Wavetable(Formant) |> mix 0.45) +
       (Triangle |> mix 0.3) +
       (Sine |> mix 0.25 |> octave 1),
  env: envelope(0.04, 0.32, 0.68, 0.75),
  filter: BandPass(3100, 0.42),
  detune: 10
}

synth WaveVaporPan = {
  osc: (Wavetable(Vapor) |> mix 0.34) +
       (Saw |> mix 0.24 |> osc_detune (-7)) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.045, 0.38, 0.72, 0.82),
  filter: LowPass(6100, 0.22),
  detune: 12
}

synth WaveSupersawPan = {
  osc: (Saw |> mix 0.28 |> osc_detune (-14)) +
       (Saw |> mix 0.28 |> osc_detune 14) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.035, 0.32, 0.76, 0.7),
  filter: LowPass(6800, 0.24),
  detune: 18
}

synth GrainFarShimmer = {
  osc: Granular(Shimmer),
  env: envelope(0.08, 0.25, 0.55, 0.95),
  filter: BandPass(5200, 0.75),
  detune: 28
}

synth GrainFarDrift = {
  osc: Granular(Drift),
  env: envelope(0.18, 0.4, 0.68, 1.3),
  filter: BandPass(2600, 0.55),
  detune: 24
}

synth GrainFarVocal = {
  osc: Granular(Vocal),
  env: envelope(0.06, 0.3, 0.6, 0.9),
  filter: BandPass(2100, 0.8),
  detune: 16
}

synth BellGlass = {
  osc: (FM(Sine, 3.97, 0.42) |> mix 0.55) +
       (Sine |> mix 0.25 |> octave 1) +
       (Triangle |> mix 0.2),
  env: envelope(0.006, 0.9, 0.22, 1.25),
  filter: LowPass(9200, 0.12)
}

synth KalimbaBell = {
  osc: (FM(Sine, 4.2, 0.38) |> mix 0.58) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.18 |> octave 1),
  env: envelope(0.005, 0.52, 0.18, 0.9),
  filter: LowPass(8600, 0.12)
}

synth FatBassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.84, 0.28),
  filter: LowPass(520, 0.72),
  detune: 18
}

synth SoftPadAir = {
  osc: Triangle,
  env: envelope(0.38, 0.35, 0.8, 1.5),
  filter: LowPass(2100, 0.28),
  detune: 16
}

synth ModularLeadPan = {
  osc: (Saw |> mix 0.34 |> osc_detune (-9)) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.22 |> octave 1) +
       (Saw |> mix 0.16 |> osc_detune 11),
  env: envelope(0.055, 0.32, 0.78, 0.85),
  filter: LowPass(5200, 0.28),
  detune: 9
}

set key = C2
set tempo = 150

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
synth DeepKick = {
  osc: Sine,
  env: envelope(0.001, 0.12, 0.0, 0.08),
  filter: LowPass(55, 0.1)
}

synth RoomSnare = {
  osc: Noise,
  env: envelope(0.001, 0.11, 0.0, 0.18),
  filter: BandPass(1900, 0.55),
  detune: 8
}

synth WideHat = {
  osc: Noise,
  env: envelope(0.001, 0.045, 0.0, 0.08),
  filter: HighPass(8200, 0.7),
  detune: 18
}

synth DeepSub = {
  osc: Sine,
  env: envelope(0.01, 0.22, 0.95, 0.35),
  filter: LowPass(54, 0.0)
}

synth BassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.82, 0.25),
  filter: LowPass(640, 0.65),
  detune: 14
}

synth AcidEdge = {
  osc: Saw,
  env: envelope(0.004, 0.12, 0.7, 0.18),
  filter: LowPass(1180, 0.92),
  detune: 9
}

synth RhodesBody = {
  osc: FM(Sine, 2.98, 0.33),
  env: envelope(0.006, 0.24, 0.58, 0.8),
  filter: LowPass(7600, 0.25)
}

synth PadBloom = {
  osc: Saw,
  env: envelope(0.34, 0.4, 0.82, 1.4),
  filter: LowPass(2300, 0.32),
  detune: 22
}

synth GlassPad = {
  osc: Triangle,
  env: envelope(0.28, 0.35, 0.76, 1.2),
  filter: LowPass(3400, 0.2),
  detune: 18
}

synth WaveFormantPan = {
  osc: (Wavetable(Formant) |> mix 0.45) +
       (Triangle |> mix 0.3) +
       (Sine |> mix 0.25 |> octave 1),
  env: envelope(0.04, 0.32, 0.68, 0.75),
  filter: BandPass(3100, 0.42),
  detune: 10
}

synth WaveVaporPan = {
  osc: (Wavetable(Vapor) |> mix 0.34) +
       (Saw |> mix 0.24 |> osc_detune (-7)) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.045, 0.38, 0.72, 0.82),
  filter: LowPass(6100, 0.22),
  detune: 12
}

synth WaveSupersawPan = {
  osc: (Saw |> mix 0.28 |> osc_detune (-14)) +
       (Saw |> mix 0.28 |> osc_detune 14) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.035, 0.32, 0.76, 0.7),
  filter: LowPass(6800, 0.24),
  detune: 18
}

synth GrainFarShimmer = {
  osc: Granular(Shimmer),
  env: envelope(0.08, 0.25, 0.55, 0.95),
  filter: BandPass(5200, 0.75),
  detune: 28
}

synth GrainFarDrift = {
  osc: Granular(Drift),
  env: envelope(0.18, 0.4, 0.68, 1.3),
  filter: BandPass(2600, 0.55),
  detune: 24
}

synth GrainFarVocal = {
  osc: Granular(Vocal),
  env: envelope(0.06, 0.3, 0.6, 0.9),
  filter: BandPass(2100, 0.8),
  detune: 16
}

synth BellGlass = {
  osc: (FM(Sine, 3.97, 0.42) |> mix 0.55) +
       (Sine |> mix 0.25 |> octave 1) +
       (Triangle |> mix 0.2),
  env: envelope(0.006, 0.9, 0.22, 1.25),
  filter: LowPass(9200, 0.12)
}

synth KalimbaBell = {
  osc: (FM(Sine, 4.2, 0.38) |> mix 0.58) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.18 |> octave 1),
  env: envelope(0.005, 0.52, 0.18, 0.9),
  filter: LowPass(8600, 0.12)
}

synth FatBassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.84, 0.28),
  filter: LowPass(520, 0.72),
  detune: 18
}

synth SoftPadAir = {
  osc: Triangle,
  env: envelope(0.38, 0.35, 0.8, 1.5),
  filter: LowPass(2100, 0.28),
  detune: 16
}

synth ModularLeadPan = {
  osc: (Saw |> mix 0.34 |> osc_detune (-9)) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.22 |> octave 1) +
       (Saw |> mix 0.16 |> osc_detune 11),
  env: envelope(0.055, 0.32, 0.78, 0.85),
  filter: LowPass(5200, 0.28),
  detune: 9
}

set key = A1
set tempo = 156

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
synth DeepKick = {
  osc: Sine,
  env: envelope(0.001, 0.12, 0.0, 0.08),
  filter: LowPass(55, 0.1)
}

synth RoomSnare = {
  osc: Noise,
  env: envelope(0.001, 0.11, 0.0, 0.18),
  filter: BandPass(1900, 0.55),
  detune: 8
}

synth WideHat = {
  osc: Noise,
  env: envelope(0.001, 0.045, 0.0, 0.08),
  filter: HighPass(8200, 0.7),
  detune: 18
}

synth DeepSub = {
  osc: Sine,
  env: envelope(0.01, 0.22, 0.95, 0.35),
  filter: LowPass(54, 0.0)
}

synth BassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.82, 0.25),
  filter: LowPass(640, 0.65),
  detune: 14
}

synth AcidEdge = {
  osc: Saw,
  env: envelope(0.004, 0.12, 0.7, 0.18),
  filter: LowPass(1180, 0.92),
  detune: 9
}

synth RhodesBody = {
  osc: FM(Sine, 2.98, 0.33),
  env: envelope(0.006, 0.24, 0.58, 0.8),
  filter: LowPass(7600, 0.25)
}

synth PadBloom = {
  osc: Saw,
  env: envelope(0.34, 0.4, 0.82, 1.4),
  filter: LowPass(2300, 0.32),
  detune: 22
}

synth GlassPad = {
  osc: Triangle,
  env: envelope(0.28, 0.35, 0.76, 1.2),
  filter: LowPass(3400, 0.2),
  detune: 18
}

synth WaveFormantPan = {
  osc: (Wavetable(Formant) |> mix 0.45) +
       (Triangle |> mix 0.3) +
       (Sine |> mix 0.25 |> octave 1),
  env: envelope(0.04, 0.32, 0.68, 0.75),
  filter: BandPass(3100, 0.42),
  detune: 10
}

synth WaveVaporPan = {
  osc: (Wavetable(Vapor) |> mix 0.34) +
       (Saw |> mix 0.24 |> osc_detune (-7)) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.045, 0.38, 0.72, 0.82),
  filter: LowPass(6100, 0.22),
  detune: 12
}

synth WaveSupersawPan = {
  osc: (Saw |> mix 0.28 |> osc_detune (-14)) +
       (Saw |> mix 0.28 |> osc_detune 14) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.035, 0.32, 0.76, 0.7),
  filter: LowPass(6800, 0.24),
  detune: 18
}

synth GrainFarShimmer = {
  osc: Granular(Shimmer),
  env: envelope(0.08, 0.25, 0.55, 0.95),
  filter: BandPass(5200, 0.75),
  detune: 28
}

synth GrainFarDrift = {
  osc: Granular(Drift),
  env: envelope(0.18, 0.4, 0.68, 1.3),
  filter: BandPass(2600, 0.55),
  detune: 24
}

synth GrainFarVocal = {
  osc: Granular(Vocal),
  env: envelope(0.06, 0.3, 0.6, 0.9),
  filter: BandPass(2100, 0.8),
  detune: 16
}

synth BellGlass = {
  osc: (FM(Sine, 3.97, 0.42) |> mix 0.55) +
       (Sine |> mix 0.25 |> octave 1) +
       (Triangle |> mix 0.2),
  env: envelope(0.006, 0.9, 0.22, 1.25),
  filter: LowPass(9200, 0.12)
}

synth KalimbaBell = {
  osc: (FM(Sine, 4.2, 0.38) |> mix 0.58) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.18 |> octave 1),
  env: envelope(0.005, 0.52, 0.18, 0.9),
  filter: LowPass(8600, 0.12)
}

synth FatBassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.84, 0.28),
  filter: LowPass(520, 0.72),
  detune: 18
}

synth SoftPadAir = {
  osc: Triangle,
  env: envelope(0.38, 0.35, 0.8, 1.5),
  filter: LowPass(2100, 0.28),
  detune: 16
}

synth ModularLeadPan = {
  osc: (Saw |> mix 0.34 |> osc_detune (-9)) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.22 |> octave 1) +
       (Saw |> mix 0.16 |> osc_detune 11),
  env: envelope(0.055, 0.32, 0.78, 0.85),
  filter: LowPass(5200, 0.28),
  detune: 9
}

set key = F1
set tempo = 144

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
synth DeepKick = {
  osc: Sine,
  env: envelope(0.001, 0.12, 0.0, 0.08),
  filter: LowPass(55, 0.1)
}

synth RoomSnare = {
  osc: Noise,
  env: envelope(0.001, 0.11, 0.0, 0.18),
  filter: BandPass(1900, 0.55),
  detune: 8
}

synth WideHat = {
  osc: Noise,
  env: envelope(0.001, 0.045, 0.0, 0.08),
  filter: HighPass(8200, 0.7),
  detune: 18
}

synth DeepSub = {
  osc: Sine,
  env: envelope(0.01, 0.22, 0.95, 0.35),
  filter: LowPass(54, 0.0)
}

synth BassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.82, 0.25),
  filter: LowPass(640, 0.65),
  detune: 14
}

synth AcidEdge = {
  osc: Saw,
  env: envelope(0.004, 0.12, 0.7, 0.18),
  filter: LowPass(1180, 0.92),
  detune: 9
}

synth RhodesBody = {
  osc: FM(Sine, 2.98, 0.33),
  env: envelope(0.006, 0.24, 0.58, 0.8),
  filter: LowPass(7600, 0.25)
}

synth PadBloom = {
  osc: Saw,
  env: envelope(0.34, 0.4, 0.82, 1.4),
  filter: LowPass(2300, 0.32),
  detune: 22
}

synth GlassPad = {
  osc: Triangle,
  env: envelope(0.28, 0.35, 0.76, 1.2),
  filter: LowPass(3400, 0.2),
  detune: 18
}

synth WaveFormantPan = {
  osc: (Wavetable(Formant) |> mix 0.45) +
       (Triangle |> mix 0.3) +
       (Sine |> mix 0.25 |> octave 1),
  env: envelope(0.04, 0.32, 0.68, 0.75),
  filter: BandPass(3100, 0.42),
  detune: 10
}

synth WaveVaporPan = {
  osc: (Wavetable(Vapor) |> mix 0.34) +
       (Saw |> mix 0.24 |> osc_detune (-7)) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.045, 0.38, 0.72, 0.82),
  filter: LowPass(6100, 0.22),
  detune: 12
}

synth WaveSupersawPan = {
  osc: (Saw |> mix 0.28 |> osc_detune (-14)) +
       (Saw |> mix 0.28 |> osc_detune 14) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.035, 0.32, 0.76, 0.7),
  filter: LowPass(6800, 0.24),
  detune: 18
}

synth GrainFarShimmer = {
  osc: Granular(Shimmer),
  env: envelope(0.08, 0.25, 0.55, 0.95),
  filter: BandPass(5200, 0.75),
  detune: 28
}

synth GrainFarDrift = {
  osc: Granular(Drift),
  env: envelope(0.18, 0.4, 0.68, 1.3),
  filter: BandPass(2600, 0.55),
  detune: 24
}

synth GrainFarVocal = {
  osc: Granular(Vocal),
  env: envelope(0.06, 0.3, 0.6, 0.9),
  filter: BandPass(2100, 0.8),
  detune: 16
}

synth BellGlass = {
  osc: (FM(Sine, 3.97, 0.42) |> mix 0.55) +
       (Sine |> mix 0.25 |> octave 1) +
       (Triangle |> mix 0.2),
  env: envelope(0.006, 0.9, 0.22, 1.25),
  filter: LowPass(9200, 0.12)
}

synth KalimbaBell = {
  osc: (FM(Sine, 4.2, 0.38) |> mix 0.58) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.18 |> octave 1),
  env: envelope(0.005, 0.52, 0.18, 0.9),
  filter: LowPass(8600, 0.12)
}

synth FatBassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.84, 0.28),
  filter: LowPass(520, 0.72),
  detune: 18
}

synth SoftPadAir = {
  osc: Triangle,
  env: envelope(0.38, 0.35, 0.8, 1.5),
  filter: LowPass(2100, 0.28),
  detune: 16
}

synth ModularLeadPan = {
  osc: (Saw |> mix 0.34 |> osc_detune (-9)) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.22 |> octave 1) +
       (Saw |> mix 0.16 |> osc_detune 11),
  env: envelope(0.055, 0.32, 0.78, 0.85),
  filter: LowPass(5200, 0.28),
  detune: 9
}

set key = E2
set tempo = 168

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
synth DeepKick = {
  osc: Sine,
  env: envelope(0.001, 0.12, 0.0, 0.08),
  filter: LowPass(55, 0.1)
}

synth RoomSnare = {
  osc: Noise,
  env: envelope(0.001, 0.11, 0.0, 0.18),
  filter: BandPass(1900, 0.55),
  detune: 8
}

synth WideHat = {
  osc: Noise,
  env: envelope(0.001, 0.045, 0.0, 0.08),
  filter: HighPass(8200, 0.7),
  detune: 18
}

synth DeepSub = {
  osc: Sine,
  env: envelope(0.01, 0.22, 0.95, 0.35),
  filter: LowPass(54, 0.0)
}

synth BassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.82, 0.25),
  filter: LowPass(640, 0.65),
  detune: 14
}

synth AcidEdge = {
  osc: Saw,
  env: envelope(0.004, 0.12, 0.7, 0.18),
  filter: LowPass(1180, 0.92),
  detune: 9
}

synth RhodesBody = {
  osc: FM(Sine, 2.98, 0.33),
  env: envelope(0.006, 0.24, 0.58, 0.8),
  filter: LowPass(7600, 0.25)
}

synth PadBloom = {
  osc: Saw,
  env: envelope(0.34, 0.4, 0.82, 1.4),
  filter: LowPass(2300, 0.32),
  detune: 22
}

synth GlassPad = {
  osc: Triangle,
  env: envelope(0.28, 0.35, 0.76, 1.2),
  filter: LowPass(3400, 0.2),
  detune: 18
}

synth WaveFormantPan = {
  osc: (Wavetable(Formant) |> mix 0.45) +
       (Triangle |> mix 0.3) +
       (Sine |> mix 0.25 |> octave 1),
  env: envelope(0.04, 0.32, 0.68, 0.75),
  filter: BandPass(3100, 0.42),
  detune: 10
}

synth WaveVaporPan = {
  osc: (Wavetable(Vapor) |> mix 0.34) +
       (Saw |> mix 0.24 |> osc_detune (-7)) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.045, 0.38, 0.72, 0.82),
  filter: LowPass(6100, 0.22),
  detune: 12
}

synth WaveSupersawPan = {
  osc: (Saw |> mix 0.28 |> osc_detune (-14)) +
       (Saw |> mix 0.28 |> osc_detune 14) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.035, 0.32, 0.76, 0.7),
  filter: LowPass(6800, 0.24),
  detune: 18
}

synth GrainFarShimmer = {
  osc: Granular(Shimmer),
  env: envelope(0.08, 0.25, 0.55, 0.95),
  filter: BandPass(5200, 0.75),
  detune: 28
}

synth GrainFarDrift = {
  osc: Granular(Drift),
  env: envelope(0.18, 0.4, 0.68, 1.3),
  filter: BandPass(2600, 0.55),
  detune: 24
}

synth GrainFarVocal = {
  osc: Granular(Vocal),
  env: envelope(0.06, 0.3, 0.6, 0.9),
  filter: BandPass(2100, 0.8),
  detune: 16
}

synth BellGlass = {
  osc: (FM(Sine, 3.97, 0.42) |> mix 0.55) +
       (Sine |> mix 0.25 |> octave 1) +
       (Triangle |> mix 0.2),
  env: envelope(0.006, 0.9, 0.22, 1.25),
  filter: LowPass(9200, 0.12)
}

synth KalimbaBell = {
  osc: (FM(Sine, 4.2, 0.38) |> mix 0.58) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.18 |> octave 1),
  env: envelope(0.005, 0.52, 0.18, 0.9),
  filter: LowPass(8600, 0.12)
}

synth FatBassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.84, 0.28),
  filter: LowPass(520, 0.72),
  detune: 18
}

synth SoftPadAir = {
  osc: Triangle,
  env: envelope(0.38, 0.35, 0.8, 1.5),
  filter: LowPass(2100, 0.28),
  detune: 16
}

synth ModularLeadPan = {
  osc: (Saw |> mix 0.34 |> osc_detune (-9)) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.22 |> octave 1) +
       (Saw |> mix 0.16 |> osc_detune 11),
  env: envelope(0.055, 0.32, 0.78, 0.85),
  filter: LowPass(5200, 0.28),
  detune: 9
}

set key = G1
set tempo = 158

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
synth DeepKick = {
  osc: Sine,
  env: envelope(0.001, 0.12, 0.0, 0.08),
  filter: LowPass(55, 0.1)
}

synth RoomSnare = {
  osc: Noise,
  env: envelope(0.001, 0.11, 0.0, 0.18),
  filter: BandPass(1900, 0.55),
  detune: 8
}

synth WideHat = {
  osc: Noise,
  env: envelope(0.001, 0.045, 0.0, 0.08),
  filter: HighPass(8200, 0.7),
  detune: 18
}

synth DeepSub = {
  osc: Sine,
  env: envelope(0.01, 0.22, 0.95, 0.35),
  filter: LowPass(54, 0.0)
}

synth BassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.82, 0.25),
  filter: LowPass(640, 0.65),
  detune: 14
}

synth AcidEdge = {
  osc: Saw,
  env: envelope(0.004, 0.12, 0.7, 0.18),
  filter: LowPass(1180, 0.92),
  detune: 9
}

synth RhodesBody = {
  osc: FM(Sine, 2.98, 0.33),
  env: envelope(0.006, 0.24, 0.58, 0.8),
  filter: LowPass(7600, 0.25)
}

synth PadBloom = {
  osc: Saw,
  env: envelope(0.34, 0.4, 0.82, 1.4),
  filter: LowPass(2300, 0.32),
  detune: 22
}

synth GlassPad = {
  osc: Triangle,
  env: envelope(0.28, 0.35, 0.76, 1.2),
  filter: LowPass(3400, 0.2),
  detune: 18
}

synth WaveFormantPan = {
  osc: (Wavetable(Formant) |> mix 0.45) +
       (Triangle |> mix 0.3) +
       (Sine |> mix 0.25 |> octave 1),
  env: envelope(0.04, 0.32, 0.68, 0.75),
  filter: BandPass(3100, 0.42),
  detune: 10
}

synth WaveVaporPan = {
  osc: (Wavetable(Vapor) |> mix 0.34) +
       (Saw |> mix 0.24 |> osc_detune (-7)) +
       (Triangle |> mix 0.22) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.045, 0.38, 0.72, 0.82),
  filter: LowPass(6100, 0.22),
  detune: 12
}

synth WaveSupersawPan = {
  osc: (Saw |> mix 0.28 |> osc_detune (-14)) +
       (Saw |> mix 0.28 |> osc_detune 14) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.2 |> octave 1),
  env: envelope(0.035, 0.32, 0.76, 0.7),
  filter: LowPass(6800, 0.24),
  detune: 18
}

synth GrainFarShimmer = {
  osc: Granular(Shimmer),
  env: envelope(0.08, 0.25, 0.55, 0.95),
  filter: BandPass(5200, 0.75),
  detune: 28
}

synth GrainFarDrift = {
  osc: Granular(Drift),
  env: envelope(0.18, 0.4, 0.68, 1.3),
  filter: BandPass(2600, 0.55),
  detune: 24
}

synth GrainFarVocal = {
  osc: Granular(Vocal),
  env: envelope(0.06, 0.3, 0.6, 0.9),
  filter: BandPass(2100, 0.8),
  detune: 16
}

synth BellGlass = {
  osc: (FM(Sine, 3.97, 0.42) |> mix 0.55) +
       (Sine |> mix 0.25 |> octave 1) +
       (Triangle |> mix 0.2),
  env: envelope(0.006, 0.9, 0.22, 1.25),
  filter: LowPass(9200, 0.12)
}

synth KalimbaBell = {
  osc: (FM(Sine, 4.2, 0.38) |> mix 0.58) +
       (Triangle |> mix 0.24) +
       (Sine |> mix 0.18 |> octave 1),
  env: envelope(0.005, 0.52, 0.18, 0.9),
  filter: LowPass(8600, 0.12)
}

synth FatBassBody = {
  osc: Saw,
  env: envelope(0.006, 0.18, 0.84, 0.28),
  filter: LowPass(520, 0.72),
  detune: 18
}

synth SoftPadAir = {
  osc: Triangle,
  env: envelope(0.38, 0.35, 0.8, 1.5),
  filter: LowPass(2100, 0.28),
  detune: 16
}

synth ModularLeadPan = {
  osc: (Saw |> mix 0.34 |> osc_detune (-9)) +
       (Triangle |> mix 0.28) +
       (Sine |> mix 0.22 |> octave 1) +
       (Saw |> mix 0.16 |> osc_detune 11),
  env: envelope(0.055, 0.32, 0.78, 0.85),
  filter: LowPass(5200, 0.28),
  detune: 9
}

set key = B1
set tempo = 164

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
