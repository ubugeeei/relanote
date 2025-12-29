# Adding Synth Sounds

Learn how to use synthesizers to give your compositions unique timbres and textures.

## What are Synths?

Synthesizers in Relanote let you control how notes sound. You can use:
- **Preset synths** - Ready-to-use sounds like Lead, Pad, Bass
- **Custom synths** - Define your own with oscillators, filters, and envelopes
- **Parameter adjustments** - Tweak cutoff, resonance, and more

## Using Preset Synths

Apply a synth to your melody with the `voice()` function:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; A simple melody
let melody = | <1> <3> <5> <3> |

; Apply a lead synth sound
let lead = melody |> voice(Lead)

lead
```

## Available Presets

### Classic Synths

Try these different synth sounds:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> |

; Bright sawtooth lead
let bright = melody |> voice(Lead)

; Warm sustained pad
let warm = melody |> voice(SoftPad)

; Thick bass sound
let thick = melody |> voice(FatBass)

; Short pluck
let plucky = melody |> voice(Pluck)

bright
```

### 8-bit Sounds

Create retro video game music:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> <5> <3> |

; Classic chiptune
let chip = melody |> voice(Chiptune)

; NES-style sound
let nes = melody |> voice(NES)

; GameBoy style
let gameboy = melody |> voice(GameBoy)

chip
```

### Drum Sounds

Add rhythm with synthesized drums:

```rela
; Kick drum pattern
let kick = | R - - - | |> repeat(4) |> voice(Kick)

; Snare on beats 2 and 4
let snare = | - - R - | |> repeat(4) |> voice(Snare)

; Hi-hat pattern
let hat = | R R R R | |> repeat(4) |> voice(HiHat) |> volume(0.4)

kick
```

## Adjusting Synth Parameters

Fine-tune your sound with parameter functions:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> |

; Darker sound with low cutoff
let dark = melody |> voice(Lead) |> cutoff(800)

; Bright and resonant
let bright = melody |> voice(Lead) |> cutoff(3000) |> resonance(0.5)

; Detuned for thickness
let fat = melody |> voice(Lead) |> detune(15)

; Custom envelope (attack, decay, sustain, release)
let slow = melody |> voice(Lead) |> adsr(0.3, 0.2, 0.7, 0.5)

dark
```

## Combining Synths with Effects

Chain synth parameters with other effects:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> <5> <3> <1> - |

; Full processing chain
let processed = melody
  |> voice(Lead)
  |> cutoff(2000)
  |> resonance(0.3)
  |> reverb(0.4)
  |> volume(0.8)

processed
```

## Creating a Synth Arrangement

Put it all together in a multi-part piece:

```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

let main = section "Main" {
  ; Lead melody
  part "Lead" {
    | <5> <6> <5> <3> | ++ | <1> <2> <3> <1> |
  } |> voice(Lead) |> volume(0.8)

  ; Pad chords
  part "Pad" {
    | [<1> <3> <5>] | ++ | [<1> <3> <5>] |
  } |> voice(SoftPad) |> volume(0.5)

  ; Bass line
  part "Bass" {
    | <1> - <1> <5> | ++ | <4> - <4> <1> |
  } |> voice(FatBass) |> cutoff(300)

  ; Drums
  part "Kick" {
    | R - R - | ++ | R - R R |
  } |> voice(Kick)

  part "Hat" {
    | R R R R | ++ | R R R R |
  } |> voice(HiHat) |> volume(0.3)
}

compose([main])
```

## Custom Synth Definitions

For ultimate control, define your own synth:

```rela
; Define a custom synth
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

let melody = | <1> <3> <5> <8> |
let bass = | <1> - <1> <5> |

let song = section "Custom" {
  part "Lead" { melody } |> voice(MyLead)
  part "Bass" { bass } |> voice(PunchyBass)
}

compose([song])
```

## Exercise

Create a chiptune-style song:

1. Use 8-bit synth presets (Chiptune, NES, GameBoy)
2. Add a bass line with low cutoff
3. Include simple drum sounds

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Your chiptune here!
let lead = | <1> <3> <5> <8> | |> voice(Chiptune)
let bass = | <1> - <1> <5> | |> voice(Chiptune) |> cutoff(400)
let drums = | R - R - | |> voice(Kick)

lead
```

## Next Steps

- Explore the [Synthesizers Guide](/guide/synth) for complete documentation
- Check out the [examples/10_chiptune.rela](https://github.com/ubugeeei/relanote/blob/main/examples/10_chiptune.rela) for more 8-bit ideas
- Try [examples/11_synth_advanced.rela](https://github.com/ubugeeei/relanote/blob/main/examples/11_synth_advanced.rela) for advanced sound design
