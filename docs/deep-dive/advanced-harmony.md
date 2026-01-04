# Advanced Harmony

This document covers advanced music theory concepts for experienced musicians and those looking to explore jazz, modern classical, and experimental harmony in Relanote.

## Church Modes

### What are Modes?

Modes are scales derived by starting on different degrees of a parent scale. The seven **church modes** (or diatonic modes) come from the major scale:

| Mode | Degree | Pattern | Character |
|------|--------|---------|-----------|
| **Ionian** | 1st | W-W-H-W-W-W-H | Bright, happy (= Major) |
| **Dorian** | 2nd | W-H-W-W-W-H-W | Minor with bright 6th |
| **Phrygian** | 3rd | H-W-W-W-H-W-W | Dark, Spanish/Middle Eastern |
| **Lydian** | 4th | W-W-W-H-W-W-H | Dreamy, floating |
| **Mixolydian** | 5th | W-W-H-W-W-H-W | Dominant, bluesy |
| **Aeolian** | 6th | W-H-W-W-H-W-W | Natural minor |
| **Locrian** | 7th | H-W-W-H-W-W-W | Diminished, unstable |

### Modal Characteristics

Each mode has a **characteristic tone** that distinguishes it from major or natural minor:

| Mode | vs Major/Minor | Characteristic Tone |
|------|----------------|---------------------|
| Dorian | Minor + M6 | Raised 6th (M6 vs m6) |
| Phrygian | Minor + m2 | Lowered 2nd (m2 vs M2) |
| Lydian | Major + A4 | Raised 4th (#4) |
| Mixolydian | Major + m7 | Lowered 7th (b7) |
| Locrian | Minor + d5 | Diminished 5th (b5) |

### Modes in Relanote

```rela
; Church modes as interval sets
scale Ionian     = { R, M2, M3, P4, P5, M6, M7 }  ; = Major
scale Dorian     = { R, M2, m3, P4, P5, M6, m7 }
scale Phrygian   = { R, m2, m3, P4, P5, m6, m7 }
scale Lydian     = { R, M2, M3, A4, P5, M6, M7 }
scale Mixolydian = { R, M2, M3, P4, P5, M6, m7 }
scale Aeolian    = { R, M2, m3, P4, P5, m6, m7 }  ; = Natural Minor
scale Locrian    = { R, m2, m3, P4, d5, m6, m7 }
```

### Modal Rotation with `rotate`

You can think of modes as rotations. The `rotate` builtin shifts elements:

```rela
; rotate shifts block elements
; rotate 1 moves first element to end
| C4 D4 E4 F4 G4 A4 B4 | |> rotate 1  ; => | D4 E4 F4 G4 A4 B4 C4 |

; C Ionian rotated by 1 = D Dorian (starting from D)
; C Ionian rotated by 2 = E Phrygian (starting from E)
; ...and so on for all 7 modes
```

## Diatonic Harmony

### Diatonic Chords

**Diatonic chords** are built using only notes from a single scale. In major:

| Degree | Triad | Seventh | Function |
|--------|-------|---------|----------|
| I | Major | Maj7 | Tonic |
| ii | minor | min7 | Subdominant |
| iii | minor | min7 | Tonic substitute |
| IV | Major | Maj7 | Subdominant |
| V | Major | Dom7 | Dominant |
| vi | minor | min7 | Tonic substitute |
| vii° | dim | min7(b5) | Dominant substitute |

```rela
; Diatonic triads in C major
scale Major = { R, M2, M3, P4, P5, M6, M7 }

chord IMaj   = [ R, M3, P5 ]       ; C
chord IImin  = [ R, m3, P5 ]       ; Dm  (built on 2nd degree)
chord IIImin = [ R, m3, P5 ]       ; Em
chord IVMaj  = [ R, M3, P5 ]       ; F
chord VMaj   = [ R, M3, P5 ]       ; G
chord VImin  = [ R, m3, P5 ]       ; Am
chord VIIdim = [ R, m3, d5 ]       ; Bdim

; Diatonic 7th chords
chord IMaj7   = [ R, M3, P5, M7 ]      ; Cmaj7
chord IImin7  = [ R, m3, P5, m7 ]      ; Dm7
chord IIImin7 = [ R, m3, P5, m7 ]      ; Em7
chord IVMaj7  = [ R, M3, P5, M7 ]      ; Fmaj7
chord V7      = [ R, M3, P5, m7 ]      ; G7 (dominant)
chord VImin7  = [ R, m3, P5, m7 ]      ; Am7
chord VIIm7b5 = [ R, m3, d5, m7 ]      ; Bm7(b5)
```

### Functional Harmony

Chords serve three main functions:

| Function | Chords | Character |
|----------|--------|-----------|
| **Tonic** | I, iii, vi | Stable, home |
| **Subdominant** | ii, IV | Moving away |
| **Dominant** | V, vii° | Tension, wants to resolve |

```rela
; ii - V - I progression (jazz standard)
let twoFiveOne =
  | [<2> <4> <6> <8>]:2 |    ; IImin7
  ++ | [<5> <7> <9> <11>]:2 | ; V7
  ++ | [<1> <3> <5> <7>]:1 |  ; IMaj7
```

## Tension Chords

### What are Tensions?

**Tensions** are chord tones beyond the 7th: 9th, 11th, and 13th. They add color and complexity.

| Tension | Interval | Semitones from Root |
|---------|----------|---------------------|
| 9 | M9 (= M2 + octave) | 14 |
| b9 | m9 | 13 |
| #9 | A9 | 15 |
| 11 | P11 (= P4 + octave) | 17 |
| #11 | A11 | 18 |
| 13 | M13 (= M6 + octave) | 21 |
| b13 | m13 | 20 |

### Available Tensions

Not all tensions work with all chord types:

| Chord Type | Available Tensions |
|------------|-------------------|
| Maj7 | 9, #11, 13 |
| min7 | 9, 11, 13 |
| Dom7 | 9, #11, 13 (natural) |
| Dom7 | b9, #9, #11, b13 (altered) |
| min7(b5) | 9, 11, b13 |

### Tension Chords in Relanote

```rela
; Extended chords
chord Maj9   = [ R, M3, P5, M7, M9 ]
chord Maj13  = [ R, M3, P5, M7, M9, M13 ]

chord min9   = [ R, m3, P5, m7, M9 ]
chord min11  = [ R, m3, P5, m7, M9, P11 ]

chord Dom9   = [ R, M3, P5, m7, M9 ]
chord Dom13  = [ R, M3, P5, m7, M9, M13 ]

; Altered dominant tensions
chord Dom7b9     = [ R, M3, P5, m7, m9 ]
chord Dom7sharp9 = [ R, M3, P5, m7, A9 ]
chord Dom7b13    = [ R, M3, P5, m7, m13 ]

; The "Hendrix chord" - 7#9
chord HendrixChord = [ R, M3, P5, m7, A9 ]  ; E7#9 in Purple Haze
```

### Voice Leading with Tensions

```rela
; Smooth voice leading: tensions resolve down by step
let smoothTwoFive =
  | [<2> <4> <6> <8> <9>]:2 |       ; Dm9
  ++ | [<5> <7> <9> <11> <13>]:2 |  ; G13
  ++ | [<1> <3> <5> <7> <9>]:1 |    ; Cmaj9
```

## Altered Scale

### What is the Altered Scale?

The **altered scale** (also called "super locrian" or "diminished whole-tone") contains all four altered tensions: b9, #9, #11 (= b5), and b13 (= #5).

| Degree | 1 | b2 | #2 | 3 | #4 | #5 | b7 |
|--------|---|----|----|---|----|----|-----|
| Interval | R | m2 | A2 | M3 | A4 | A5 | m7 |

### Altered = Melodic Minor `rotate 6`

The altered scale is the **7th mode of melodic minor**. Think of it as melodic minor rotated by 6 positions:

```rela
; Melodic minor scale
scale MelodicMinor = { R, M2, m3, P4, P5, M6, M7 }

; Play Ab melodic minor as a block, then rotate 6
; Ab Bb Cb Db Eb F G => rotated by 6 => G Ab Bb Cb Db Eb F
; This gives us G Altered!

let abMelodicMinor = | Ab4 Bb4 Cb5 Db5 Eb5 F5 G5 |
let gAltered = abMelodicMinor |> rotate 6  ; => | G5 Ab4 Bb4 Cb5 Db5 Eb5 F5 |
```

### Melodic Minor Modes

All seven modes of melodic minor are useful (each is a `rotate` of the parent):

| Mode | Name | rotate | Formula | Use |
|------|------|--------|---------|-----|
| I | Melodic Minor | 0 | R M2 m3 P4 P5 M6 M7 | min(maj7) chords |
| II | Dorian b2 | 1 | R m2 m3 P4 P5 M6 m7 | sus(b9) chords |
| III | Lydian Augmented | 2 | R M2 M3 A4 A5 M6 M7 | Maj7(#5) chords |
| IV | Lydian Dominant | 3 | R M2 M3 A4 P5 M6 m7 | 7(#11) chords |
| V | Mixolydian b6 | 4 | R M2 M3 P4 P5 m6 m7 | 7(b13) chords |
| VI | Locrian #2 | 5 | R M2 m3 P4 d5 m6 m7 | min7(b5) chords |
| VII | **Altered** | 6 | R m2 A2 M3 A4 A5 m7 | 7alt chords |

### In Relanote

```rela
; Melodic minor and its modes
scale MelodicMinor    = { R, M2, m3, P4, P5, M6, M7 }
scale DorianFlat2     = { R, m2, m3, P4, P5, M6, m7 }
scale LydianAugmented = { R, M2, M3, A4, A5, M6, M7 }
scale LydianDominant  = { R, M2, M3, A4, P5, M6, m7 }
scale MixolydianFlat6 = { R, M2, M3, P4, P5, m6, m7 }
scale LocrianNat2     = { R, M2, m3, P4, d5, m6, m7 }
scale Altered         = { R, m2, A2, M3, A4, A5, m7 }

; Altered dominant chord
chord Alt7 = [ R, M3, A5, m7, m9 ]  ; 7(#5b9)

; ii-V-I with altered dominant
let alteredTwoFive =
  | [<2> <4> <6> <8>]:2 |               ; Dm7
  ++ | G4 B4 Eb5 F5 Ab5 |:2             ; G7alt (absolute pitches for clarity)
  ++ | [<1> <3> <5> <7>]:1 |            ; Cmaj7
```

## Harmonic Minor P5 Below (HMP5b)

### What is HMP5b?

**HMP5b** (Harmonic Minor Perfect 5th Below), also called **Phrygian Dominant** or **Spanish Phrygian**, is the **5th mode of harmonic minor** (= `rotate 4`).

```rela
; A Harmonic Minor rotated by 4 = E Phrygian Dominant
let aHarmonicMinor = | A4 B4 C5 D5 E5 F5 G#5 |
let ePhrygianDom = aHarmonicMinor |> rotate 4  ; => | E5 F5 G#5 A4 B4 C5 D5 |
```

### The Characteristic Sound

HMP5b combines:
- **Phrygian** b2 (Spanish/Arabic sound)
- **Major 3rd** (dominant chord quality)

This creates the classic flamenco/Middle Eastern dominant sound.

| Interval | R | m2 | M3 | P4 | P5 | m6 | m7 |
|----------|---|----|----|----|----|----|----|
| Character | Root | b9 tension | Major 3rd | 11 | 5 | b13 | Dominant 7 |

### In Relanote

```rela
; Harmonic minor modes (each is rotate N of harmonic minor)
scale HarmonicMinor   = { R, M2, m3, P4, P5, m6, M7 }  ; rotate 0
scale LocrianNat6     = { R, m2, m3, P4, d5, M6, m7 }  ; rotate 1
scale IonianAug       = { R, M2, M3, P4, A5, M6, M7 }  ; rotate 2
scale DorianSharp4    = { R, M2, m3, A4, P5, M6, m7 }  ; rotate 3
scale PhrygianDom     = { R, m2, M3, P4, P5, m6, m7 }  ; rotate 4 = HMP5b
scale LydianSharp2    = { R, A2, M3, A4, P5, M6, M7 }  ; rotate 5
scale SuperLocrianbb7 = { R, m2, m3, d4, d5, m6, d7 }  ; rotate 6

; Flamenco-style progression
let flamenco =
  | [<1> <3> <5>] |:4           ; Am
  ++ | [<7> <2> <4>] |:4        ; G
  ++ | [<6> <1> <3>] |:4        ; F
  ++ | E4 G#4 B4 D5 |:4         ; E7(b9) - Phrygian Dominant
```

## Messiaen's Modes of Limited Transposition

### What are Symmetrical Scales?

Olivier Messiaen identified scales that repeat at intervals smaller than an octave. These **modes of limited transposition** have only 2, 3, 4, or 6 unique transpositions (unlike the 12 of normal scales).

### The Seven Modes

| Mode | Pattern | Transpositions | Notes |
|------|---------|----------------|-------|
| **1** | W-W-W-W-W-W | 2 | Whole tone scale |
| **2** | H-W-H-W-H-W-H-W | 3 | Octatonic (diminished) |
| **3** | W-H-H-W-H-H-W-H-H | 4 | 9 notes |
| **4** | H-H-m3-H-H-H-m3-H | 6 | 8 notes |
| **5** | H-M3-H-H-M3-H | 6 | 6 notes |
| **6** | W-W-H-H-W-W-H-H | 6 | 8 notes |
| **7** | H-H-H-W-H-H-H-H-W-H | 6 | 10 notes |

### Mode 2: Octatonic (Diminished Scale)

The most commonly used symmetrical scale in jazz:

```
Half-Whole: H-W-H-W-H-W-H-W (starts with half step)
Whole-Half: W-H-W-H-W-H-W-H (starts with whole step)

C Half-Whole: C - Db - Eb - E - F# - G - A - Bb - C
C Whole-Half: C - D  - Eb - F - Gb - Ab - A - B  - C
```

### In Relanote

```rela
; Messiaen's Modes of Limited Transposition
scale WholeTone    = { R, M2, M3, A4, A5, A6 }          ; Mode 1
scale Diminished   = { R, m2, m3, M3, A4, P5, M6, m7 }  ; Mode 2 (H-W)
scale DiminishedWH = { R, M2, m3, P4, d5, m6, M6, M7 }  ; Mode 2 (W-H)

; Mode 3
scale Messiaen3 = { R, M2, m3, M3, A4, P5, m6, M6, M7 }

; Whole tone dominant
chord Aug7 = [ R, M3, A5, m7 ]  ; Works with whole tone scale

; Diminished 7th chord (symmetrical - same chord every m3)
chord Dim7 = [ R, m3, d5, M6 ]  ; M6 = d7 enharmonically
```

### Symmetry and Transposition

```rela
; Diminished scale has only 3 transpositions:
; C dim = Eb dim = F# dim = A dim
; Db dim = E dim = G dim = Bb dim
; D dim = F dim = Ab dim = B dim

; Whole tone has only 2 transpositions:
; C whole tone = D = E = F# = G# = A#
; Db whole tone = Eb = F = G = A = B
```

## Lydian Chromatic Concept

### George Russell's Theory

The **Lydian Chromatic Concept of Tonal Organization** (1953) proposes that the **Lydian scale** (not Ionian/Major) is the most consonant scale relative to a major chord.

### Why Lydian?

The major scale has a dissonance: the 4th degree (F in C major) creates an "avoid note" against the major chord. Lydian's #4 eliminates this:

```
C Major chord: C - E - G

C Ionian:  C - D - E - F - G - A - B    (F clashes with E)
C Lydian:  C - D - E - F# - G - A - B   (F# = #11, no clash)
```

### The Lydian Chromatic Scale

Russell extended Lydian to include all 12 chromatic notes, ordered by consonance:

| Order | Notes | Relationship |
|-------|-------|--------------|
| 1-7 | C D E F# G A B | Lydian scale (most consonant) |
| 8 | F | Lydian b7 (Mixolydian character) |
| 9 | Bb | Blues note |
| 10 | Eb | Minor character |
| 11 | Ab | Further removed |
| 12 | Db | Most distant |

### Chord-Scale Unity

Russell's concept: every chord implies a scale, and vice versa. The parent scale defines "in" and "out" notes:

| Chord | Parent Scale |
|-------|--------------|
| Cmaj7 | C Lydian |
| Cmaj7#11 | C Lydian |
| C7 | C Lydian Dominant (mode IV of G melodic minor) |
| Cm7 | C Dorian |
| Cm(maj7) | C Melodic Minor |
| C7alt | C Altered (mode VII of Db melodic minor) |

### In Relanote

```rela
; Lydian as the primary scale
scale Lydian = { R, M2, M3, A4, P5, M6, M7 }

; Lydian Chromatic extensions
scale LydianDominant = { R, M2, M3, A4, P5, M6, m7 }     ; add b7
scale LydianAugmented = { R, M2, M3, A4, A5, M6, M7 }    ; add #5
scale LydianDimished = { R, M2, M3, A4, P5, M6, m7, M7 } ; add both 7ths

; Chord-scale approach: define chord with its scale
let cmaj7_sound = {
  chord: [ R, M3, P5, M7 ],
  scale: Lydian,
  avoid: []  ; no avoid notes in Lydian!
}

; Vertical vs Horizontal
; Vertical: chord tones (arpeggios)
; Horizontal: scale tones (melody)
let lydianMelody =
  | <1> <2> <3> <#4> <5> <6> <7> <8> |
```

## Practical Applications

### Jazz ii-V-I with Extensions

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
set key C4
set tempo 120

; Rich ii-V-I voicings
let jazzTwoFiveOne =
  ; Dm9
  | D3 A3 C4 E4 F4 |:2
  ; G13(b9) - altered dominant
  ++ | G2 B3 E4 F4 Ab4 |:2
  ; Cmaj9
  ++ | C3 E3 B3 D4 |:1
```

### Modal Interchange

```rela
; Borrowing chords from parallel modes
set key C4

; I - bVII - IV - I (borrowing bVII from C Mixolydian)
let modalInterchange =
  | [<1> <3> <5>] |:4     ; C
  ++ | Bb3 D4 F4 |:4       ; Bb (from C Mixolydian)
  ++ | [<4> <6> <8>] |:4   ; F
  ++ | [<1> <3> <5>] |:4   ; C
```

### Symmetrical Scale Application

```rela
; Using diminished scale over dominant 7th
set key G4  ; G7 resolving to C

; G diminished (H-W) for G7(b9) sound
let dimDominant =
  | G4 Ab4 Bb4 B4 Db5 D5 E5 F5 |:4
  ++ | C4 E4 G4 |:1  ; resolve to C
```

## Further Reading

- **Music Theory Fundamentals**: Basic concepts prerequisite for this material
- **Synthesizer Basics**: How to voice these advanced harmonies
- **Sound Synthesis**: Creating appropriate timbres for jazz/modern music
