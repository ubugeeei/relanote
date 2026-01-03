# Built-in Functions Reference

Complete reference for Relanote's built-in functions.

## Block Transformations

### reverse

Reverses the order of notes in a block.

```rela
reverse : Block -> Block

| <1> <2> <3> | |> reverse
; Result: | <3> <2> <1> |
```

### transpose

Shifts all notes by a given interval.

```rela
transpose : Interval -> Block -> Block

| <1> <3> <5> | |> transpose P5
; All notes shifted up by a perfect fifth

| <1> <3> <5> | |> transpose (R - P8)
; Transpose down an octave (use parentheses for expressions)
```

### repeat

Repeats a block n times.

```rela
repeat : Int -> Block -> Block

| <1> <2> | |> repeat 3
; Result: | <1> <2> <1> <2> <1> <2> |
```

## Synth Functions

### voice

Applies a synth preset or custom synth to a block.

```rela
voice : Synth -> Block -> Part

| <1> <3> <5> | |> voice Lead
| <1> <3> <5> | |> voice Chiptune
| <1> <3> <5> | |> voice MyCustomSynth
```

### cutoff

Sets the filter cutoff frequency in Hz.

```rela
cutoff : Float -> Part -> Part

melody |> voice Lead |> cutoff 800    ; Dark sound
melody |> voice Lead |> cutoff 4000   ; Bright sound
```

### resonance

Sets the filter resonance (Q factor).

```rela
resonance : Float -> Part -> Part

melody |> voice Lead |> resonance 0.3   ; Subtle
melody |> voice Lead |> resonance 0.8   ; Resonant peak
```

**Range:** 0.0 to 1.0

### detune

Detunes the oscillators in cents.

```rela
detune : Float -> Part -> Part

melody |> voice Lead |> detune 10    ; Slight thickening
melody |> voice Lead |> detune 50    ; Heavy chorus effect
```

### adsr

Sets the ADSR envelope (Attack, Decay, Sustain, Release).

```rela
adsr : Float -> Float -> Float -> Float -> Part -> Part

; adsr attack decay sustain release
melody |> voice Lead |> adsr 0.01 0.1 0.7 0.3   ; Quick attack
melody |> voice Lead |> adsr 0.5 0.2 0.8 1.0    ; Slow pad
```

**Parameters:**
- Attack: Time in seconds to reach peak volume
- Decay: Time in seconds to reach sustain level
- Sustain: Volume level during sustain (0.0 - 1.0)
- Release: Time in seconds to fade after note off

### env

Creates an ADSR envelope value for use in synth definitions.

```rela
env : Float -> Float -> Float -> Float -> ADSR

let myEnv = env 0.1 0.2 0.7 0.4
```

## Oscillator Constructors

Oscillators generate the raw waveform for a synth. Use these when defining custom synths.

### Sine

Pure sine wave - smooth, fundamental tone.

```rela
Sine : Oscillator

synth Pad = {
  osc: Sine,
  env: { A: 0.3, D: 0.1, S: 0.8, R: 0.5 }
}
```

### Saw

Sawtooth wave - bright, rich harmonics. Classic lead sound.

```rela
Saw : Oscillator

synth BrightLead = {
  osc: Saw,
  env: { A: 0.02, D: 0.1, S: 0.6, R: 0.2 }
}
```

### Square

Square wave - hollow, woody tone. Classic chiptune sound.

```rela
Square : Oscillator

synth Retro = {
  osc: Square,
  env: { A: 0.01, D: 0.1, S: 0.5, R: 0.1 }
}
```

### Triangle

Triangle wave - softer than square, flute-like.

```rela
Triangle : Oscillator

synth Soft = {
  osc: Triangle,
  env: { A: 0.1, D: 0.2, S: 0.7, R: 0.3 }
}
```

### Pulse

Pulse wave with variable duty cycle (0.0 - 1.0). Creates different timbres.

```rela
Pulse : Float -> Oscillator

synth NES = {
  osc: Pulse 0.25,    ; 25% duty cycle
  env: { A: 0.01, D: 0.05, S: 0.4, R: 0.1 }
}
```

### Noise

White noise - used for drums, percussion, and effects.

```rela
Noise : Oscillator

synth Snare = {
  osc: Noise,
  env: { A: 0.001, D: 0.1, S: 0.0, R: 0.1 }
}
```

## Filter Constructors

Filters shape the harmonic content of a sound. Use these when defining custom synths.

### LowPass

Low-pass filter - removes high frequencies. Makes sound darker/warmer.

```rela
LowPass : Float -> Float -> Filter
; LowPass cutoff_hz resonance

synth Warm = {
  osc: Saw,
  filter: LowPass 800 0.3,
  env: { A: 0.1, D: 0.2, S: 0.6, R: 0.3 }
}
```

### HighPass

High-pass filter - removes low frequencies. Makes sound thinner/brighter.

```rela
HighPass : Float -> Float -> Filter
; HighPass cutoff_hz resonance

synth Thin = {
  osc: Saw,
  filter: HighPass 500 0.2,
  env: { A: 0.05, D: 0.1, S: 0.7, R: 0.2 }
}
```

### BandPass

Band-pass filter - keeps only frequencies around the cutoff. Creates nasal, focused sound.

```rela
BandPass : Float -> Float -> Filter
; BandPass center_hz resonance

synth Telephone = {
  osc: Saw,
  filter: BandPass 1000 0.8,
  env: { A: 0.02, D: 0.1, S: 0.5, R: 0.2 }
}
```

## Effect Functions

### reverb

Applies reverb effect.

```rela
reverb : Float -> Block -> Part

melody |> reverb 0.5   ; 50% wet
```

**Range:** 0.0 (dry) to 1.0 (fully wet)

### hall_reverb

Applies hall-style reverb preset.

```rela
hall_reverb : Block -> Part

melody |> hall_reverb
```

### room_reverb

Applies room-style reverb preset.

```rela
room_reverb : Block -> Part

melody |> room_reverb
```

### plate_reverb

Applies plate-style reverb preset.

```rela
plate_reverb : Block -> Part

melody |> plate_reverb
```

### dry

Creates a dry (no reverb) part.

```rela
dry : Block -> Part

melody |> dry
```

### volume

Sets the volume level.

```rela
volume : Float -> Block -> Part
volume : Float -> Part -> Part

melody |> volume 0.8            ; 80% volume
melody |> voice Lead |> volume 0.5   ; Chain with synth
```

**Range:** 0.0 (silent) to 1.0 (full volume)

## Rhythm Functions

### swing

Applies swing feel to a block.

```rela
swing : Block -> Block

| <1> <2> <3> <4> | |> swing
```

### double_time

Doubles the tempo (halves note durations).

```rela
double_time : Block -> Block

| <1> <2> <3> <4> | |> double_time
```

### metronome

Creates a metronome click track.

```rela
metronome : Int -> Int -> Block

metronome 4 4   ; 4 beats, 4 bars
```

## Composition Functions

### compose

Combines sections into a song.

```rela
compose : [Section] -> Song

compose [intro, verse, chorus, verse, chorus, outro]
```

### play

Adds a block to an existing part.

```rela
play : Block -> Part -> Part

part |> play newMelody
```

## Array Functions

### take

Takes the first n elements from an array.

```rela
take : Int -> [a] -> [a]

[1, 2, 3, 4, 5] |> take 3
; Result: [1, 2, 3]
```

### drop

Drops the first n elements from an array.

```rela
drop : Int -> [a] -> [a]

[1, 2, 3, 4, 5] |> drop 2
; Result: [3, 4, 5]
```

### zip

Combines two arrays into an array of tuples.

```rela
zip : [a] -> [b] -> [(a, b)]

zip [1, 2, 3] ["a", "b", "c"]
; Result: [(1, "a"), (2, "b"), (3, "c")]
```

### concat

Concatenates two arrays.

```rela
concat : [a] -> [a] -> [a]

concat [1, 2] [3, 4]
; Result: [1, 2, 3, 4]
```

### len

Returns the length of an array or string.

```rela
len : [a] -> Int
len : String -> Int

len [1, 2, 3]
; Result: 3

len "hello"
; Result: 5
```

### foldl

Left fold - accumulates from left to right.

```rela
foldl : (a -> b -> a) -> a -> [b] -> a

; foldl f z [a,b,c] = f (f (f z a) b) c
foldl (\acc x -> acc + x) 0 [1, 2, 3, 4]
; Result: 10
```

### foldr

Right fold - accumulates from right to left.

```rela
foldr : (a -> b -> b) -> b -> [a] -> b

; foldr f z [a,b,c] = f a (f b (f c z))
foldr (\x acc -> x :: acc) [] [1, 2, 3]
; Result: [1, 2, 3]
```

### map

Transforms each element of an array.

```rela
map : (a -> b) -> [a] -> [b]

map (\x -> x * 2) [1, 2, 3]
; Result: [2, 4, 6]
```

### filter

Keeps elements matching a predicate.

```rela
filter : (a -> Bool) -> [a] -> [a]

filter (\x -> x > 2) [1, 2, 3, 4]
; Result: [3, 4]
```

### flatMap

Maps a function over an array and flattens the result.

```rela
flatMap : (a -> [b]) -> [a] -> [b]

flatMap (\x -> [x, x * 2]) [1, 2, 3]
; Result: [1, 2, 2, 4, 3, 6]
```

### find

Returns the first element matching a predicate, or Unit if not found.

```rela
find : (a -> Bool) -> [a] -> a | Unit

find (\x -> x > 2) [1, 2, 3, 4]
; Result: 3
```

### any

Checks if any element satisfies a predicate.

```rela
any : (a -> Bool) -> [a] -> Bool

any (\x -> x > 3) [1, 2, 3, 4]
; Result: true

any (\x -> x > 5) [1, 2, 3, 4]
; Result: false
```

### all

Checks if all elements satisfy a predicate.

```rela
all : (a -> Bool) -> [a] -> Bool

all (\x -> x > 0) [1, 2, 3, 4]
; Result: true

all (\x -> x > 2) [1, 2, 3, 4]
; Result: false
```

## Synth Presets Reference

### Classic Synths

| Name | Description | Best for |
|------|-------------|----------|
| `Lead` | Bright sawtooth | Melodies, solos |
| `SoftPad` | Warm sustained | Chords, atmosphere |
| `FatBass` | Thick detuned | Bass lines |
| `Pluck` | Short attack | Arpeggios, staccato |
| `Strings` | Slow attack | Pads, swells |
| `Organ` | Harmonic sines | Keys, chords |

### 8-bit Synths

| Name | Description | Best for |
|------|-------------|----------|
| `Chiptune` | Classic square | Retro melodies |
| `Chip8bit` | Pure square | Beeps, blips |
| `NES` | Nintendo style | Game music |
| `GameBoy` | Narrow pulse | Lo-fi sounds |

### Drum Synths

| Name | Description | Best for |
|------|-------------|----------|
| `Kick` | Synthesized kick | Bass drum |
| `Snare` | Noise + tone | Backbeat |
| `HiHat` | Filtered noise | Rhythm |
| `OpenHat` | Longer decay | Accents |
| `Tom` | Pitched drum | Fills |
| `Clap` | Hand clap | Accents |

## Practical Examples

### Creating a Complete Track

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Melody with synth and effects
let melody = | <1> <3> <5> <8> |
  |> transpose P5
  |> voice Lead
  |> cutoff 2000
  |> reverb 0.3

; Bass line with custom envelope
let bass = | <1>:2 <5>:2 |
  |> repeat 4
  |> voice FatBass
  |> adsr 0.02 0.1 0.8 0.2
  |> volume 0.9

; Chiptune arpeggio
let arp = | <1> <3> <5> <3> |
  |> double_time
  |> voice Chiptune
  |> volume 0.6

layer [melody, bass, arp]
```

### Using Map for Algorithmic Composition

```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }

; Generate a sequence of intervals
let intervals = [P1, M3, P5, M7, P8]

; Map to create variations
let melody = intervals
  |> map (\i -> i + M2)    ; Transpose each up a step

; Transform a block note by note
let pattern = | <1> <2> <3> <4> |
let octave_up = pattern |> map (\n -> n + P8)
```

### Building Reusable Transformations

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Compose transformations
let jazz_up = transpose P5 >> swing >> reverb 0.4
let thicken = voice FatBass >> detune 15 >> volume 0.8

; Apply to different parts
let melody = | <1> <3> <5> <3> | |> jazz_up
let bass = | <1> <5> | |> thicken
```

### Swing and Rhythm

```rela
scale Blues = { R, m3, P4, A4, P5, m7 }

; Straight rhythm
let straight = | <1> <3> <4> <5> <3> <1> - - |

; Apply swing for jazz feel
let swung = straight |> swing

; Double time for energy
let fast = straight |> double_time

swung |> voice Lead |> reverb 0.3
```

### Custom Synth Definition

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Define a warm pad synth
synth WarmPad = {
  osc: Saw,
  filter: LowPass 1200 0.4,
  env: { A: 0.4, D: 0.2, S: 0.7, R: 0.8 },
  detune: 8
}

; Define a plucky bass
synth PluckBass = {
  osc: Square,
  filter: LowPass 600 0.6,
  env: { A: 0.01, D: 0.3, S: 0.0, R: 0.2 }
}

let chords = | [R, M3, P5] [P4, M6, R] |
  |> voice WarmPad
  |> volume 0.7

let bass = | <1>:2 <5>:2 |
  |> voice PluckBass
  |> volume 0.9

layer [chords, bass]
```
