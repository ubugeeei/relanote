# Synthesizers

Relanote includes built-in synthesizer support for creating custom sounds. You can use preset synths or define your own with full control over oscillators, envelopes, and filters.

## Using Preset Synths

Apply a synth preset to a block using the `voice` function:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <3> |

; Apply synth preset
let lead = melody |> voice Lead
let pad = melody |> voice SoftPad
let bass = melody |> voice FatBass

lead
```

## Available Presets

Relanote includes 80+ professionally designed synth presets. See the [Preset Reference](/deep-dive/preset-reference) for a complete list.

### Piano & Electric Piano

| Preset | Description |
|--------|-------------|
| `AcousticPiano` | Warm, natural acoustic piano |
| `BrightPiano` | Clear, present piano |
| `Rhodes` | Warm, bell-like electric piano |
| `Wurlitzer` | Gritty, funky electric piano |
| `Clavinet` | Funky, percussive |

### Bass Instruments

| Preset | Description |
|--------|-------------|
| `WoodBass` | Warm upright bass |
| `ElectricBass` | Punchy electric bass |
| `SynthBass` | Fat electronic bass |
| `SubBass` | Deep sub-heavy bass |
| `AcidBass` | Squelchy resonant bass |

### Brass Instruments

| Preset | Description |
|--------|-------------|
| `Trumpet` | Bright, cutting brass |
| `MutedTrumpet` | Soft, nasal trumpet |
| `Trombone` | Rich, warm brass |
| `Brass` | Generic brass section |
| `BrassSection` | Wide, powerful section |

### Synth Leads

| Preset | Description |
|--------|-------------|
| `Lead` | Classic versatile lead |
| `SuperSaw` | Huge detuned trance lead |
| `SquareLead` | Hollow, punchy lead |
| `ResoLead` | Squelchy filtered lead |

### Pads

| Preset | Description |
|--------|-------------|
| `SoftPad` | Warm sustained pad |
| `WarmPad` | Rich, enveloping pad |
| `StringPad` | Orchestral string pad |
| `ChoirPad` | Vocal, ethereal pad |

### Classic & 8-bit

| Preset | Description |
|--------|-------------|
| `Chiptune` | Classic square wave |
| `NES` | Nintendo-style sound |
| `GameBoy` | Narrow pulse wave |
| `Pluck` | Short attack pluck |
| `Strings` | Slow attack strings |
| `Organ` | Harmonic sine organ |

### Drums (with Pitch Envelope)

| Preset | Description |
|--------|-------------|
| `DeepKick` | Sub-heavy kick drum |
| `PunchyKick` | Attack-focused kick |
| `TightSnare` | Short, punchy snare |
| `FatSnare` | Big, roomy snare |
| `ClosedHat` | Tight hi-hat |
| `OpenHiHat` | Sizzling open hat |
| `HighTom` / `MidTom` / `FloorTom` | Pitched toms |
| `CrashCymbal` / `RideCymbal` | Cymbals |

### Percussion

| Preset | Description |
|--------|-------------|
| `HandClap` | Snappy clap |
| `Cowbell` | Pitched metallic |
| `Conga` / `Bongo` | Latin drums |
| `Tambourine` / `Shaker` | Rhythm instruments |

## Modifying Synth Parameters

Use pipe functions to adjust synth parameters:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> |

; Filter cutoff (Hz)
let dark = melody |> voice Lead |> cutoff 800
let bright = melody |> voice Lead |> cutoff 4000

; Resonance (0.0 - 1.0)
let resonant = melody |> voice Lead |> cutoff 1500 |> resonance 0.6

; Detune (cents)
let detuned = melody |> voice Lead |> detune 15

; Custom ADSR envelope
let custom = melody |> voice Lead |> adsr 0.1 0.2 0.6 0.5

custom
```

### Parameter Functions

| Function | Parameters | Description |
|----------|------------|-------------|
| `cutoff freq` | freq: Hz | Filter cutoff frequency |
| `resonance q` | q: 0.0-1.0 | Filter resonance/Q |
| `detune cents` | cents: number | Detune in cents |
| `adsr a d s r` | a,d,r: seconds, s: 0.0-1.0 | ADSR envelope |

## Custom Synth Definitions

Define your own synth with the `synth` keyword:

```rela
synth MyLead = {
  osc: Saw,
  env: { A: 0.02, D: 0.15, S: 0.7, R: 0.2 },
  filter: LowPass(3000, 0.3)
}

synth ThickBass = {
  osc: Saw,
  detune: 10,
  env: { A: 0.05, D: 0.2, S: 0.6, R: 0.3 },
  filter: LowPass(200, 0.5)
}

scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> |
melody |> voice MyLead
```

### Synth Properties

| Property | Values | Description |
|----------|--------|-------------|
| `osc` | Sine, Square, Saw, Triangle, Noise | Oscillator waveform |
| `env` | `{ A: s, D: s, S: level, R: s }` | ADSR envelope |
| `filter` | LowPass(Hz, Q), HighPass(Hz, Q), BandPass(Hz, Q) | Filter type |
| `detune` | cents | Oscillator detune amount |

### Oscillator Types

- `Sine` - Pure sine wave
- `Square` - Square wave (50% duty)
- `Saw` - Sawtooth wave
- `Triangle` - Triangle wave
- `Noise` - White noise

### Filter Types

- `LowPass(cutoff, resonance)` - Low-pass filter
- `HighPass(cutoff, resonance)` - High-pass filter
- `BandPass(cutoff, resonance)` - Band-pass filter

## Combining with Effects

Synth parameters can be combined with other effects:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> |

let processed = melody
  |> voice Lead
  |> cutoff 2000
  |> resonance 0.3
  |> reverb 0.4
  |> volume 0.8

processed
```

## Multi-Part Arrangements

Use synths in full arrangements:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let song = section "Main" {
  part "Lead" {
    | <5> <6> <5> <3> | ++ | <1> <2> <3> <1> |
  } |> voice Lead |> volume 0.8

  part "Pad" {
    | [<1> <3> <5>] | ++ | [<1> <3> <5>] |
  } |> voice SoftPad |> volume 0.5

  part "Bass" {
    | <1> - <1> <5> | ++ | <4> - <4> <1> |
  } |> voice FatBass |> volume 0.7

  part "Drums" {
    | R - R - | ++ | R - R R |
  } |> voice Kick
}

compose([song])
```

## MIDI Output

When rendering to MIDI, synth parameters are converted to MIDI CC messages:

| Parameter | MIDI CC | Range |
|-----------|---------|-------|
| Cutoff | CC#74 | 0-127 |
| Resonance | CC#71 | 0-127 |
| Attack | CC#73 | 0-127 |
| Decay | CC#75 | 0-127 |
| Release | CC#72 | 0-127 |
| Detune (as Modulation) | CC#1 | 0-127 |

This allows DAWs and hardware synths to respond to your parameter changes.
