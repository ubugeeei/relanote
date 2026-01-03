# Intervals Reference

Complete reference for musical intervals in Relanote.

## Interval Notation

Format: `<Quality><Number><Modifier>`

### Quality

| Symbol | Name | Description |
|--------|------|-------------|
| `P` | Perfect | Unison, 4th, 5th, octave |
| `M` | Major | 2nd, 3rd, 6th, 7th |
| `m` | Minor | Flattened major intervals |
| `A` | Augmented | Raised by half step |
| `d` | Diminished | Lowered by half step |

### Number

The scale degree (1-13+).

### Modifier

| Symbol | Meaning |
|--------|---------|
| `+` | One octave up |
| `-` | One octave down |
| `++` | Two octaves up |
| `--` | Two octaves down |

## Complete Interval Table

| Interval | Semitones | Name |
|----------|-----------|------|
| `R` / `P1` | 0 | Root / Perfect Unison |
| `m2` | 1 | Minor Second |
| `M2` | 2 | Major Second |
| `m3` | 3 | Minor Third |
| `M3` | 4 | Major Third |
| `P4` | 5 | Perfect Fourth |
| `A4` / `d5` | 6 | Tritone |
| `P5` | 7 | Perfect Fifth |
| `m6` | 8 | Minor Sixth |
| `M6` | 9 | Major Sixth |
| `m7` | 10 | Minor Seventh |
| `M7` | 11 | Major Seventh |
| `P8` | 12 | Perfect Octave |

## Extended Intervals

| Interval | Semitones | Name |
|----------|-----------|------|
| `m9` | 13 | Minor Ninth |
| `M9` | 14 | Major Ninth |
| `m10` | 15 | Minor Tenth |
| `M10` | 16 | Major Tenth |
| `P11` | 17 | Perfect Eleventh |
| `A11` | 18 | Augmented Eleventh |
| `P12` | 19 | Perfect Twelfth |
| `m13` | 20 | Minor Thirteenth |
| `M13` | 21 | Major Thirteenth |

## Interval Arithmetic

### Addition

```rela
M3 + m3    ; = P5 (4 + 3 = 7 semitones)
P5 + P4    ; = P8 (7 + 5 = 12 semitones)
M2 + M2    ; = M3 (2 + 2 = 4 semitones)
```

### Subtraction

```rela
P8 - P5    ; = P4 (12 - 7 = 5 semitones)
M7 - M3    ; = P5 (11 - 4 = 7 semitones)
```

### Inversion

```rela
invert(M3)    ; = m6 (12 - 4 = 8 semitones)
invert(P5)    ; = P4 (12 - 7 = 5 semitones)
invert(m2)    ; = M7 (12 - 1 = 11 semitones)
```

## Common Patterns

### Major Triad

```rela
chord MajorTriad = [ R, M3, P5 ]    ; 0, 4, 7 semitones
```

### Minor Triad

```rela
chord MinorTriad = [ R, m3, P5 ]    ; 0, 3, 7 semitones
```

### Dominant 7th

```rela
chord Dom7 = [ R, M3, P5, m7 ]    ; 0, 4, 7, 10 semitones
```

### Major 7th

```rela
chord Maj7 = [ R, M3, P5, M7 ]    ; 0, 4, 7, 11 semitones
```

### Major Scale

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
; 0, 2, 4, 5, 7, 9, 11 semitones
```

### Natural Minor Scale

```rela
scale Minor = { R, M2, m3, P4, P5, m6, m7 }
; 0, 2, 3, 5, 7, 8, 10 semitones
```

## Enharmonic Equivalents

These intervals have the same number of semitones:

| Semitones | Intervals |
|-----------|-----------|
| 6 | `A4`, `d5` |
| 1 | `m2`, `A1` |
| 11 | `M7`, `d8` |

In Relanote, enharmonically equivalent intervals are treated as equal:

```rela
A4 == d5    ; true (both are 6 semitones)
```
