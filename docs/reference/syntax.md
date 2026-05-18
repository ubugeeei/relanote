# Syntax Reference

Complete syntax reference for Relanote.

## Comments

```rela
; Single line comment
```

## Literals

### Intervals

```rela
R     ; Root (unison)
M2    ; Major second
m3    ; Minor third
A4    ; Augmented fourth
d5    ; Diminished fifth
P5+   ; Perfect fifth, octave up
M3-   ; Major third, octave down
```

### Absolute Pitches

Absolute pitch notation for specifying the key (root note):

```rela
C4    ; Middle C (MIDI note 60)
D4    ; D above middle C
Bb3   ; B-flat below middle C
F#4   ; F-sharp above middle C
G3    ; G below middle C
```

**Format:** `[Note][Accidental][Octave]`
- **Note:** C, D, E, F, G, A, B
- **Accidental (optional):** `#` (sharp) or `b` (flat)
- **Octave:** 0-9 (4 is the middle C octave)

### Numbers

```rela
42      ; Integer
3.14    ; Float
```

### Strings

```rela
"Hello, World!"
```

### Booleans

```rela
true
false
```

## Variables

### Let Binding

```rela
let name = value

; With type annotation (optional)
let name: Type = value
```

## Set Bindings

The `set` keyword is used for built-in configuration variables:

### Key (Root Note)

```rela
set key = C4     ; Root is middle C (default)
set key = Bb3    ; Root is B-flat below middle C
set key = G4     ; Root is G above middle C
```

All intervals are calculated relative to this pitch. If not specified, the default key is C4 (MIDI note 60).

### Tempo

```rela
set tempo = 120  ; 120 beats per minute (default)
set tempo = 80   ; Slower tempo
set tempo = 140  ; Faster tempo
```

### Let...In Expression

```rela
let x = 10 in
  x + 5    ; Returns 15
```

## Blocks

### Basic Block

```rela
| note1 note2 note3 |
```

### With Scale Degrees

```rela
| <1> <2> <3> |
```

### With Rests

```rela
| <1> - <3> |
```

### Note Duration

Individual notes, rests, and chords can have explicit durations using the `:n` syntax:

```rela
| <1>:2 <2> <3> |      ; First note is 2 slots long, others are 1 slot
| <1>:4 - - - |        ; Note held for 4 slots
| <1>:2 -:2 <3>:2 |    ; Each element is 2 slots
| [R, M3, P5]:4 |      ; Chord held for 4 slots
```

The number after `:` represents how many "slots" the note occupies. Within a block, all slots share the block's total duration equally. So `:2` means the note takes twice as long as a normal slot.

**Examples:**
```rela
; Half notes and quarter notes
| <1>:2 <2>:2 |        ; Two half notes

; Dotted rhythm
| <1>:3 <2> |          ; Dotted quarter + eighth

; Whole note
| <1>:4 |              ; One whole note (4 slots worth)

; With articulations
| <1>^:2 <2>*:2 |      ; Accented half note, staccato half note
```

## Scale and Chord

### Scale Definition

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
```

### Chord Definition

```rela
chord MajorTriad = [ R, M3, P5 ]
```

## Functions

### Lambda Expression

```rela
\x -> x + 1

\x, y -> x + y
```

### Function Application

```rela
f(x)
f(x, y)
```

### Pipe Operator

```rela
x |> f          ; Same as f(x)
x |> f |> g     ; Same as g(f(x))
```

### Function Composition

```rela
f >> g    ; Same as \x -> g(f(x))
```

## Control Flow

### If Expression

```rela
if condition then
  true_expr
else
  false_expr
```

### Match Expression

```rela
match value with
  | pattern1 -> result1
  | pattern2 -> result2
  | _ -> default
```

## Operators

### Arithmetic

```rela
a + b    ; Addition
a - b    ; Subtraction
a * b    ; Multiplication
a / b    ; Division
```

### Comparison

```rela
a == b   ; Equal
a != b   ; Not equal
a < b    ; Less than
a > b    ; Greater than
a <= b   ; Less or equal
a >= b   ; Greater or equal
```

### Logical

```rela
a and b
a or b
not a
```

### Block Operations

```rela
a ++ b   ; Concatenation
```

## Articulations

```rela
<1>'     ; Staccato
<1>^     ; Accent
```

## Synth Definition

### Basic Synth

```rela
synth MyLead = {
  osc: Saw,
  env: { A: 0.02, D: 0.15, S: 0.7, R: 0.2 },
  filter: LowPass(3000, 0.3)
}
```

### Synth Properties

| Property | Values | Description |
| --- | --- | --- |
| `osc` | `Sine`, `Square`, `Saw`, `Triangle`, `Noise`, `FM(...)`, `Wavetable(...)`, `Granular(...)` | Oscillator(s). Stack with `+`. |
| `env` | `{ A: s, D: s, S: level, R: s }` | ADSR envelope |
| `filter` | `LowPass(hz, q)`, `HighPass(hz, q)`, `BandPass(hz, q)` | Filter |
| `detune` | number (cents) | Unison detune across voices |
| `pitch_env` | `{ from: hz, to: hz, time: s }` | Pitch envelope (drums) |
| `mod` | `[ lfo(...), env(...), keytrack(...), velocity(...) ]` | Modulation matrix |
| `bitcrush` | `{ bits, rate }` | Per-voice bit reduction |
| `saturate` | number (0–1) | Per-voice saturation amount |

### Oscillator forms

```rela
Sine
Square
Saw
Triangle
Noise(color: White | Pink)

; Stacked oscillators — `+` sums voices.
Saw(voices: 5) + Sine(level: 0.4, octave: -1)

; FM — two operators, the carrier the listener hears.
FM(op1: Sine, op2: Sine, op2_ratio: 3.5, op2_level: 0.6, feedback: 0.0)

; Wavetable — scan through single-cycle waves.
Wavetable(table: "vapor", voices: 3?)

; Granular — chop a sample bank.
Granular(source: "drone",
         grain_size: 0.08,
         density: 28,
         spray: 0.4,
         pitch_jitter: 0,
         reverse: false?)
```

### Filter types

```rela
LowPass(cutoff_hz, resonance)
HighPass(cutoff_hz, resonance)
BandPass(cutoff_hz, resonance)
```

## Tuning declarations

```rela
tuning EDO24            = equal { steps: 24 }
tuning JustIntonation   = ratios [ 1/1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8 ]
tuning WerckmeisterIII  = cents [ 0.0, -3.91, -7.82, ... ]
tuning BohlenPierce     = ratios_per_period { period: 3/1, steps: 13 }

set tuning = JustIntonation        ; activate globally
let passage = melody |> in_tuning EDO24    ; activate for one expression
```

Cents offsets on individual pitches use `+Nc` / `-Nc`:

```rela
| <1> M3 -13.7c <5> |          ; just major third on top of the M3
| <3 +5c> <5 -7c> |            ; cents offset on a scale-degree reference
| C4 +50c |                    ; cents offset on an absolute pitch
```

## Groove declarations

```rela
groove Swing67 = offsets {
  length: 2,
  steps: [0.0, 0.17]
}

groove Dilla = offsets {
  length: 16,
  steps: [
     0.00,  0.04, -0.02,  0.05,
    -0.03,  0.06,  0.02,  0.07,
     0.00,  0.05, -0.02,  0.05,
    -0.04,  0.07,  0.02,  0.08
  ]
}

set groove = Dilla              ; activate globally
melody |> groove Swing67         ; per-track activation
```

## Polyrhythm

`a over b` plays both sides simultaneously at independent periods.
The figure realigns every `lcm(slots(a), slots(b))` slots:

```rela
| <1> <5> <8> |:3 over | [<1> m3 P5] [<4> m6 R] [<5> m7 P9] [<1> m3 P5] |:4
```

## Effect declarations

```rela
effect DubDelay = delay {
  time: "1/4", feedback: 0.55, mix: 0.35, filter: LowPass(3500, 0.2), saturate: 0.15
}

effect PlateLarge = reverb {
  size: 0.85, decay: 4.5, damping: 0.6, mix: 0.35, pre_delay: 0.04
}

effect BusGlue = compressor {
  threshold: -16, ratio: 2.5, attack: 0.030, release: 0.250, knee: 4, makeup: 2
}

effect DubRoom = chain [
  delay { time: "1/4", feedback: 0.45, mix: 0.3 },
  reverb { size: 0.7, decay: 3.5, damping: 0.55, mix: 0.4 }
]

melody |> effect DubDelay                ; apply by name
```

## Mix block

```rela
mix {
  ; Per-track effects.
  track "lead"  |> compress -10 4
  track "bass"  |> saturate 0.2

  ; Shared buses.
  bus Verb  = effect PlateLarge
  bus Tape  = effect TapeEcho
  bus Glue  = effect BusGlue

  ; Sends.
  track "lead"  |> send Verb 0.35 |> send Tape 0.20
  track "drums" |> send Glue 1.00

  ; Sidechain ducking.
  sidechain track "kick" -> track "bass" 0.6

  ; Master chain.
  master = effect MasterChain
}
```

## Built-in Functions

### Block Transformations

```rela
melody |> reverse           ; Reverse the block
melody |> transpose P5     ; Transpose by interval
melody |> repeat 2         ; Repeat n times
melody |> map (\n -> n + P8) ; Transform each note
```

### Synth Functions

```rela
melody |> voice Lead       ; Apply synth preset
melody |> cutoff 1000      ; Set filter cutoff (Hz)
melody |> resonance 0.5    ; Set filter resonance (0-1)
melody |> detune 10        ; Set detune (cents)
melody |> adsr 0.1 0.2 0.7 0.3  ; Set envelope
```

### Synth Presets

**Classic:**
- `Lead` - Bright sawtooth lead
- `SoftPad` - Warm sustained pad
- `FatBass` - Thick detuned bass
- `Pluck` - Short attack pluck
- `Strings` - Slow attack strings
- `Organ` - Harmonic sine organ

**8-bit:**
- `Chiptune` - Classic square wave
- `Chip8bit` - Pure square, fast decay
- `NES` - Nintendo-style sound
- `GameBoy` - Narrow pulse wave

**Drums:**
- `Kick` - Kick drum
- `Snare` - Snare drum
- `HiHat` - Closed hi-hat
- `OpenHat` - Open hi-hat
- `Tom` - Tom drum
- `Clap` - Hand clap
