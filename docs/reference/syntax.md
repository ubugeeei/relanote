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
|----------|--------|-------------|
| `osc` | Sine, Square, Saw, Triangle, Noise | Oscillator waveform |
| `env` | `{ A: s, D: s, S: level, R: s }` | ADSR envelope |
| `filter` | LowPass, HighPass, BandPass | Filter type with cutoff and Q |
| `detune` | number (cents) | Oscillator detune |

### Filter Types

```rela
LowPass(cutoff_hz, resonance)
HighPass(cutoff_hz, resonance)
BandPass(cutoff_hz, resonance)
```

## Built-in Functions

### Block Transformations

```rela
melody |> reverse           ; Reverse the block
melody |> transpose(P5)     ; Transpose by interval
melody |> repeat(2)         ; Repeat n times
melody |> map(\n -> n + P8) ; Transform each note
```

### Synth Functions

```rela
melody |> voice(Lead)       ; Apply synth preset
melody |> cutoff(1000)      ; Set filter cutoff (Hz)
melody |> resonance(0.5)    ; Set filter resonance (0-1)
melody |> detune(10)        ; Set detune (cents)
melody |> adsr(0.1, 0.2, 0.7, 0.3)  ; Set envelope
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
