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
