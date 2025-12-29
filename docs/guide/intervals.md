# Intervals

Intervals are the heart of Relanote. They describe the distance between two notes without specifying absolute pitch.

## Interval Notation

An interval consists of:
1. **Quality**: P (Perfect), M (Major), m (minor), A (Augmented), d (diminished)
2. **Number**: 1-13 (scale degree)
3. **Modifier**: + (up octave), - (down octave)

```rela
P1    // Perfect unison (0 semitones)
m2    // Minor second (1 semitone)
M2    // Major second (2 semitones)
m3    // Minor third (3 semitones)
M3    // Major third (4 semitones)
P4    // Perfect fourth (5 semitones)
A4    // Augmented fourth / Tritone (6 semitones)
d5    // Diminished fifth / Tritone (6 semitones)
P5    // Perfect fifth (7 semitones)
m6    // Minor sixth (8 semitones)
M6    // Major sixth (9 semitones)
m7    // Minor seventh (10 semitones)
M7    // Major seventh (11 semitones)
P8    // Perfect octave (12 semitones)
```

## Octave Modifiers

Add `+` or `-` to shift octaves:

```rela
P1+   // One octave up (12 semitones)
P5+   // Fifth + octave (19 semitones)
M3-   // Major third, one octave down (-8 semitones)
P8++  // Two octaves up (24 semitones)
```

## Interval Arithmetic

Intervals can be added and subtracted:

```rela
M3 + m3    // = P5 (4 + 3 = 7 semitones)
P8 - P5    // = P4 (12 - 7 = 5 semitones)
M2 + M2    // = M3 (2 + 2 = 4 semitones)
```

## Common Interval Patterns

### Major Triad
```rela
[P1, M3, P5]    // Root, major third, perfect fifth
```

### Minor Triad
```rela
[P1, m3, P5]    // Root, minor third, perfect fifth
```

### Dominant 7th
```rela
[P1, M3, P5, m7]
```

### Major Scale
```rela
[P1, M2, M3, P4, P5, M6, M7]
```

### Minor Scale (Natural)
```rela
[P1, M2, m3, P4, P5, m6, m7]
```

## Intervals as Functions

Intervals can transform other intervals:

```rela
let transpose_up_fifth = \i -> i + P5

P1 |> transpose_up_fifth    // P5
M3 |> transpose_up_fifth    // M7
```

## Enharmonic Equivalents

Relanote treats enharmonically equivalent intervals as identical:

```rela
A4 == d5    // Both are 6 semitones (tritone)
```
