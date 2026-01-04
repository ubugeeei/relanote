# Music Theory Fundamentals

This document covers the essential music theory concepts needed to effectively use Relanote.

## Pitch and Frequency

### What is Pitch?

Pitch is how we perceive the frequency of a sound wave. Higher frequencies sound "higher" in pitch.

| Frequency (Hz) | Note | MIDI Number | |
|----------------|------|-------------|---|
| 261.63 | C4 | 60 | |
| 293.66 | D4 | 62 | |
| 329.63 | E4 | 64 | |
| 349.23 | F4 | 65 | |
| 392.00 | G4 | 67 | |
| 440.00 | A4 | 69 | Concert pitch standard |
| 493.88 | B4 | 71 | |
| 523.25 | C5 | 72 | |

### The Octave

An **octave** is the interval between one pitch and another with double its frequency. Notes an octave apart sound "the same" but higher or lower.

**C4 (261.63 Hz) → C5 (523.25 Hz)** — C5 is exactly 2× the frequency of C4

In MIDI, an octave is always 12 semitones (half steps).

## Semitones and the Chromatic Scale

### The Semitone (Half Step)

A **semitone** is the smallest interval in Western music. On a piano, it's the distance from one key to the very next key (including black keys).

<img src="/diagrams/piano-keyboard.svg" alt="Piano Keyboard Layout" style="width: 100%; max-width: 700px; margin: 1rem 0;" />

### The Chromatic Scale

The chromatic scale contains all 12 semitones in an octave:

```
C → C# → D → D# → E → F → F# → G → G# → A → A# → B → C
    Db       Eb            Gb       Ab       Bb
```

## Intervals

### What is an Interval?

An **interval** is the distance between two pitches, measured in semitones.

### Interval Names

<img src="/diagrams/intervals-chart.svg" alt="Musical Intervals Reference" style="width: 100%; max-width: 800px; margin: 1rem 0;" />

### Quality Prefixes

```
P = Perfect    Used for: unisons, 4ths, 5ths, octaves
M = Major      Used for: 2nds, 3rds, 6ths, 7ths
m = minor      One semitone less than Major
A = Augmented  One semitone more than Perfect/Major
d = diminished One semitone less than Perfect/minor
```

### Why "Perfect"?

The intervals P1, P4, P5, and P8 are called "perfect" because:
1. They were considered most consonant (harmonious) in medieval music
2. They occur naturally in the harmonic series
3. They don't have major/minor variants

### Interval Inversions

When you flip an interval (move the lower note up an octave), you get its inversion:

| Original | + | Inversion | = | Total |
|----------|---|-----------|---|-------|
| m2 (1) | + | M7 (11) | = | 12 semitones |
| M2 (2) | + | m7 (10) | = | 12 semitones |
| m3 (3) | + | M6 (9) | = | 12 semitones |
| M3 (4) | + | m6 (8) | = | 12 semitones |
| P4 (5) | + | P5 (7) | = | 12 semitones |

## Scales

### What is a Scale?

A **scale** is a set of notes arranged in order of pitch. Scales define which notes "belong" together and create a musical context.

### The Major Scale

The most common scale, with a bright, happy sound:

```
Whole-Whole-Half-Whole-Whole-Whole-Half
  W     W    H    W     W     W    H

C Major:  C - D - E - F - G - A - B - C
            W   W   H   W   W   W   H

In intervals from root:
  R   M2  M3  P4  P5  M6  M7  P8
```

In Relanote:
```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
```

### The Natural Minor Scale

A darker, sadder sound than major:

```
Whole-Half-Whole-Whole-Half-Whole-Whole
  W    H    W     W    H    W     W

A minor:  A - B - C - D - E - F - G - A
            W   H   W   W   H   W   W

In intervals from root:
  R   M2  m3  P4  P5  m6  m7  P8
```

In Relanote:
```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }
```

### Comparing Major and Minor

<img src="/diagrams/major-minor-scales.svg" alt="Major vs Minor Scale Comparison" style="width: 100%; max-width: 750px; margin: 1rem 0;" />

The 3rd degree is the most important difference - it determines if a scale/chord sounds "major" (happy) or "minor" (sad).

### Other Common Scales

```rela
; Pentatonic scales (5 notes) - easy to improvise with
scale MajorPentatonic = { R, M2, M3, P5, M6 }
scale MinorPentatonic = { R, m3, P4, P5, m7 }

; Blues scale - adds the "blue note" (tritone)
scale Blues = { R, m3, P4, A4, P5, m7 }

; Modes - rotations of the major scale
scale Dorian = { R, M2, m3, P4, P5, M6, m7 }      ; Minor with raised 6th
scale Phrygian = { R, m2, m3, P4, P5, m6, m7 }   ; Spanish/Middle Eastern
scale Lydian = { R, M2, M3, A4, P5, M6, M7 }     ; Dreamy, floating
scale Mixolydian = { R, M2, M3, P4, P5, M6, m7 } ; Dominant, bluesy
```

### The Circle of Fifths

The circle of fifths shows relationships between keys:

<img src="/diagrams/circle-of-fifths.svg" alt="Circle of Fifths" style="width: 100%; max-width: 400px; margin: 1rem 0;" />

## Chords

### What is a Chord?

A **chord** is three or more notes played simultaneously.

### Triads

The simplest chords are **triads** - three notes stacked in thirds:

```
Major triad:     R + M3 + P5    (happy)
Minor triad:     R + m3 + P5    (sad)
Diminished:      R + m3 + d5    (tense)
Augmented:       R + M3 + A5    (unstable)
```

In Relanote:
```rela
chord Maj = [ R, M3, P5 ]
chord Min = [ R, m3, P5 ]
chord Dim = [ R, m3, d5 ]
chord Aug = [ R, M3, A5 ]
```

### Seventh Chords

Adding a 7th creates richer harmony:

```
Major 7th:       R + M3 + P5 + M7    (jazz, dreamy)
Dominant 7th:    R + M3 + P5 + m7    (blues, needs resolution)
Minor 7th:       R + m3 + P5 + m7    (smooth, mellow)
Diminished 7th:  R + m3 + d5 + d7    (very tense)
Half-dim 7th:    R + m3 + d5 + m7    (jazz, bittersweet)
```

```rela
chord Maj7 = [ R, M3, P5, M7 ]
chord Dom7 = [ R, M3, P5, m7 ]
chord Min7 = [ R, m3, P5, m7 ]
chord Dim7 = [ R, m3, d5, M6 ]   ; d7 = M6 enharmonically
chord Min7b5 = [ R, m3, d5, m7 ]
```

### Chord Inversions

Chords can be rearranged by moving the lowest note up an octave:

```
C Major triad inversions:

Root position:   C - E - G     (R - M3 - P5)
1st inversion:   E - G - C     (M3 on bottom)
2nd inversion:   G - C - E     (P5 on bottom)
```

### Chord Progressions

Common chord progressions in popular music:

```
I - IV - V - I        (C - F - G - C)     Classic rock/pop
I - V - vi - IV       (C - G - Am - F)    "Axis of Awesome" progression
ii - V - I            (Dm - G - C)        Jazz standard
I - vi - IV - V       (C - Am - F - G)    50s progression
```

## Rhythm

### Beat and Tempo

- **Beat**: The basic pulse of music
- **Tempo**: Speed of the beat (BPM = beats per minute)

```
Common tempos:
  60 BPM  = 1 beat per second (slow ballad)
  90 BPM  = relaxed groove
  120 BPM = standard pop/rock
  140 BPM = energetic dance
  180 BPM = fast punk/metal
```

### Note Values

| Name | Symbol | Beats (in 4/4) |
|------|--------|----------------|
| Whole note | 1 | 4 |
| Half note | 2 | 2 |
| Quarter note | 4 | 1 |
| Eighth note | 8 | 0.5 |
| Sixteenth | 16 | 0.25 |

In Relanote, the `:n` suffix sets duration:
```rela
| C4:1 |    ; whole note (4 beats)
| C4:2 |    ; half note (2 beats)
| C4:4 |    ; quarter note (1 beat)
| C4:8 |    ; eighth note (0.5 beats)
```

### Time Signatures

The time signature tells you how beats are grouped:

```
4/4 = 4 quarter notes per measure (most common)
3/4 = 3 quarter notes per measure (waltz)
6/8 = 6 eighth notes per measure (compound duple)
```

### Relative Rhythm in Relanote

In Relanote, rhythm is relative within blocks:

```rela
; 4 notes in a block = each gets 1/4 of the duration
| C4 D4 E4 F4 |

; 2 notes = each gets 1/2
| C4 E4 |

; Mixed with explicit durations
| C4:2 E4:4 G4:4 |  ; half + quarter + quarter
```

## Key Signatures

### What is a Key?

A **key** defines:
1. Which scale the music uses
2. Which note is "home" (the tonic)

### Key Signatures and Accidentals

```
Key of C Major:  No sharps or flats
Key of G Major:  F#
Key of D Major:  F#, C#
Key of F Major:  Bb
Key of Bb Major: Bb, Eb
```

### Relative Major/Minor

Every major key has a relative minor that shares the same notes:

```
C Major  ←→  A minor   (no sharps/flats)
G Major  ←→  E minor   (1 sharp: F#)
F Major  ←→  D minor   (1 flat: Bb)
```

The relative minor starts on the 6th degree of the major scale.

## Applying Theory in Relanote

### Why Relative Intervals?

Traditional notation uses absolute pitches (C, D, E...). Relanote uses relative intervals because:

1. **Transposition is free**: Change the key by changing one setting
2. **Patterns are reusable**: A melody works in any key
3. **Relationships are explicit**: You see the harmonic structure

```rela
; This melody works in ANY key
let melody = | <1> <3> <5> <8> |

; Play in C major
set key C4
melody  ; C - E - G - C

; Play in G major - same pattern, different key
set key G4
melody  ; G - B - D - G
```

### Scale Degrees

Scale degrees reference positions in the current scale:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; In C Major:
; <1> = C (degree 1 = R = root)
; <2> = D (degree 2 = M2)
; <3> = E (degree 3 = M3)
; <4> = F (degree 4 = P4)
; <5> = G (degree 5 = P5)
; <6> = A (degree 6 = M6)
; <7> = B (degree 7 = M7)
```

### Building Chord Progressions

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
chord Maj = [ R, M3, P5 ]
chord Min = [ R, m3, P5 ]

; I - IV - V - I progression
let progression =
  | [<1> <3> <5>] |    ; I   (C major in key of C)
  ++ | [<4> <6> <8>] | ; IV  (F major)
  ++ | [<5> <7> <9>] | ; V   (G major)
  ++ | [<1> <3> <5>] | ; I   (back to C)
```

## Further Reading

- **Sound Synthesis**: Learn how these musical concepts translate to sound
- **Preset Reference**: See how theory applies to synth design
- **Language Design**: Understand how Relanote models these concepts
