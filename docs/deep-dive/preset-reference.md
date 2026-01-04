# Synth Preset Reference

This document provides a complete reference for all built-in synth presets, organized by category.

## Overview

Relanote includes 80+ professionally designed synth presets covering:

- **Basic** - Classic synths and 8-bit sounds
- **Piano** - Acoustic and electric pianos
- **Bass** - Various bass instruments
- **Brass** - Trumpet, trombone, and sections
- **Leads** - Synth lead sounds
- **Pads** - Atmospheric sounds
- **Pluck** - Percussive melodic instruments
- **Drums** - Full drum kit with pitch envelopes
- **Percussion** - Hand percussion instruments
- **Retro** - Vintage and lo-fi sounds

## Piano & Electric Piano

### Acoustic Piano

| Preset | Character | Best For |
|--------|-----------|----------|
| `AcousticPiano` | Warm, natural | Ballads, classical |
| `BrightPiano` | Clear, present | Pop, rock |
| `MellowPiano` | Soft, dark | Jazz, ambient |

```rela
synth AcousticPiano = {
  osc: (Sine |> mix 0.6) + (Triangle |> mix 0.25 |> octave 1) + (Sine |> mix 0.15 |> octave 2),
  env: envelope 0.005 0.4 0.3 0.8,
  filter: LowPass 5000 0.2
}
```

### Electric Piano

| Preset | Character | Best For |
|--------|-----------|----------|
| `Rhodes` | Warm, bell-like | Jazz, R&B, neo-soul |
| `Wurlitzer` | Gritty, biting | Rock, funk |
| `DXPiano` | Bright, FM | 80s pop, fusion |
| `Clavinet` | Funky, percussive | Funk, disco |

## Bass Instruments

| Preset | Character | Best For |
|--------|-----------|----------|
| `WoodBass` | Warm, upright | Jazz, acoustic |
| `ElectricBass` | Punchy, round | Rock, pop |
| `SynthBass` | Fat, electronic | EDM, synth-pop |
| `SubBass` | Deep, sub-heavy | Hip-hop, dubstep |
| `AcidBass` | Squelchy, resonant | Acid house, techno |
| `ReeseBass` | Detuned, wide | Drum & bass, dubstep |

### Bass Design Tips

```
For punchy bass:
├── Use Saw + Square oscillators
├── Fast attack (< 20ms)
├── Low filter cutoff (200-600Hz)
└── Moderate resonance (0.4-0.6)

For sub bass:
├── Use pure Sine
├── Very low cutoff (< 200Hz)
├── Low resonance
└── Optional: add octave-down sine
```

## Brass Instruments

| Preset | Character | Best For |
|--------|-----------|----------|
| `Trumpet` | Bright, cutting | Jazz, Latin, big band |
| `MutedTrumpet` | Soft, nasal | Jazz, film noir |
| `Trombone` | Rich, warm | Jazz, orchestral |
| `FrenchHorn` | Mellow, noble | Orchestral, film |
| `Brass` | Generic section | Pop, rock |
| `BrassSection` | Wide, powerful | Big band, soul |

### Brass Envelope

Real brass has a characteristic "bloom":

```
Trumpet envelope:
│
│     ╱────────╲
│    ╱          ╲
│   ╱            ╲
│  ╱              ╲
│ ╱  A=80ms       R=200ms
└──────────────────→
   Slow attack for realism
```

## Synth Leads

| Preset | Character | Best For |
|--------|-----------|----------|
| `Lead` | Classic, versatile | Any genre |
| `SuperSaw` | Huge, detuned | Trance, eurodance |
| `HyperSaw` | Massive, wide | EDM, big room |
| `SquareLead` | Hollow, punchy | Chiptune, retro |
| `ResoLead` | Squelchy, filtered | Acid, techno |
| `SoftLead` | Gentle, smooth | Ambient, chill |
| `OctaveLead` | Full, octaved | Rock, metal |

### SuperSaw Anatomy

The iconic trance/EDM sound:

```
SuperSaw = 3 detuned saw waves

       -12 cents    center    +12 cents
           │          │          │
           ▼          ▼          ▼
       ┌──────┐   ┌──────┐   ┌──────┐
       │ Saw  │ + │ Saw  │ + │ Saw  │
       │ 0.33 │   │ 0.33 │   │ 0.34 │
       └──────┘   └──────┘   └──────┘
           │          │          │
           └──────────┴──────────┘
                      │
                      ▼
                  HUGE SOUND
```

## Synth Pads

| Preset | Character | Best For |
|--------|-----------|----------|
| `SoftPad` | Simple, warm | Backgrounds |
| `WarmPad` | Rich, enveloping | Ambient |
| `StringPad` | Orchestral | Film, classical |
| `ChoirPad` | Vocal, ethereal | New age, ambient |
| `GlassPad` | Crystalline, bright | Electronic |
| `DarkPad` | Deep, ominous | Cinematic, horror |
| `SweepPad` | Moving, filtered | EDM, progressive |

### Pad Envelope Tips

```
Slow attack for pads:
│
│           ╱──────────────╲
│          ╱                ╲
│         ╱                  ╲
│        ╱                    ╲
│       ╱  A=0.5-1.0s          R=1.0-2.0s
└───────────────────────────────→
    Creates smooth, ambient feel
```

## Pluck Instruments

| Preset | Character | Best For |
|--------|-----------|----------|
| `Pluck` | Generic, bright | Arpeggios |
| `PluckBass` | Punchy, low | Bass lines |
| `PluckLead` | Articulate | Melodies |
| `Marimba` | Woody, mellow | World, jazz |
| `Vibraphone` | Bell-like, sustain | Jazz, chill |
| `Xylophone` | Bright, percussive | Classical |
| `Kalimba` | Thumb piano | African, ambient |
| `Harp` | Plucked strings | Classical, new age |

## Drum Kit

### Kick Drums

| Preset | Character | Best For |
|--------|-----------|----------|
| `Kick` | Basic, simple | General use |
| `DeepKick` | Sub-heavy | Hip-hop, R&B |
| `PunchyKick` | Attack-focused | Rock, EDM |
| `SubKick` | Ultra low | Bass music |
| `HardKick` | Aggressive | Metal, hardcore |
| `SoftKick` | Gentle | Jazz, acoustic |

```rela
; DeepKick with pitch envelope
synth DeepKick = {
  osc: Sine,
  env: envelope 0.001 0.15 0.0 0.1,
  pitch_env: (150, 40, 0.08)  ; 150Hz → 40Hz in 80ms
}
```

### Snare Drums

| Preset | Character | Best For |
|--------|-----------|----------|
| `Snare` | Basic | General use |
| `TightSnare` | Short, punchy | Funk, rock |
| `FatSnare` | Big, roomy | Hip-hop, pop |
| `CrispSnare` | Bright, snappy | Electronic |
| `RimShot` | Sharp, crack | Latin, funk |
| `SideStick` | Subtle, click | Jazz, ballads |

### Hi-Hats

| Preset | Character | Best For |
|--------|-----------|----------|
| `HiHat` | Basic closed | General use |
| `ClosedHat` | Tight, short | Dance |
| `OpenHiHat` | Sizzle, long | Rock, jazz |
| `PedalHat` | Medium, foot | Jazz |
| `TightHat` | Very short | Electronic |

### Toms

| Preset | Pitch Range | Best For |
|--------|-------------|----------|
| `Tom` | Basic | General use |
| `HighTom` | High | Fills |
| `MidTom` | Mid | Fills |
| `FloorTom` | Low | Accents, fills |
| `LowTom` | Very low | Tribal, cinematic |

### Cymbals

| Preset | Character | Best For |
|--------|-----------|----------|
| `CrashCymbal` | Bright, explosive | Accents |
| `RideCymbal` | Sustained, ping | Jazz, rock |
| `RideBell` | Bell-like | Latin, jazz |
| `SplashCymbal` | Quick, bright | Fills |
| `ChinaCymbal` | Trashy, exotic | Rock, metal |

## Percussion

| Preset | Character | Best For |
|--------|-----------|----------|
| `HandClap` | Snappy | Pop, dance |
| `Cowbell` | Pitched, metallic | Latin, disco |
| `Shaker` | Rhythmic noise | Latin, acoustic |
| `Tambourine` | Jingly | Pop, rock |
| `Conga` | Deep, tonal | Latin |
| `Bongo` | Higher, tonal | Latin, jazz |
| `Timbale` | Bright, sharp | Latin |
| `WoodBlock` | Clicky, pitched | Classical, Latin |
| `Claves` | Short, high | Latin |

## Retro / Lo-Fi

| Preset | Character | Best For |
|--------|-----------|----------|
| `LoFiPiano` | Filtered, warm | Lo-fi hip-hop |
| `VintageOrgan` | Classic drawbar | Gospel, rock |
| `RetroSynth` | 80s, punchy | Synthwave |
| `TapeBass` | Warm, saturated | Lo-fi |
| `VHSPad` | Detuned, warbly | Vaporwave, lo-fi |

## 8-bit / Chiptune

| Preset | Character | Best For |
|--------|-----------|----------|
| `Chiptune` | Square wave | Retro games |
| `Chip8bit` | Pure square | NES style |
| `NES` | Classic Nintendo | 8-bit covers |
| `GameBoy` | Narrow pulse | GB style |
| `Kick8bit` | Square kick | Chiptune |
| `Snare8bit` | Noise snare | Chiptune |
| `HiHat8bit` | Noise hat | Chiptune |

## Usage Examples

### Full Song Arrangement

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let song = section "Pop Song" {
  part "Lead" {
    | <5> <6> <5> <3> | ++ | <1> <2> <3> <1> |
  } |> voice Rhodes |> volume 0.8

  part "Pad" {
    | [<1> <3> <5>]:1 | ++ | [<4> <6> <8>]:1 |
  } |> voice WarmPad |> volume 0.5

  part "Bass" {
    | <1> - <1> <5> | ++ | <4> - <4> <1> |
  } |> voice ElectricBass |> volume 0.7

  part "Drums" {
    | R - R - | ++ | R - R R |
  } |> voice PunchyKick

  part "HiHat" {
    | R R R R | ++ | R R R R |
  } |> voice ClosedHat |> volume 0.4
}

compose([song])
```

### Layered Sound

```rela
; Layer multiple synths for richness
let layered_pad = | [<1> <3> <5>]:1 |

let layer1 = layered_pad |> voice WarmPad |> volume 0.5
let layer2 = layered_pad |> voice StringPad |> volume 0.3
let layer3 = layered_pad |> voice GlassPad |> volume 0.2 |> octave 1

compose([layer1, layer2, layer3])
```
