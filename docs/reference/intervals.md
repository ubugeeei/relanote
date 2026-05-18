# Intervals reference

## Notation

Every interval is `<quality><degree><modifiers>`.

### Quality

| Symbol | Quality | Used for |
| --- | --- | --- |
| `R` | Root | shorthand for `P1` |
| `P` | Perfect | unison, 4th, 5th, 8th, 11th, 12th |
| `M` | Major | 2nd, 3rd, 6th, 7th, 9th, 10th, 13th |
| `m` | Minor | flattened major intervals |
| `A` | Augmented | raised by a semitone |
| `d` | Diminished | lowered by a semitone |

### Degree

The scale degree, `1` to `13+`. Anything above `8` wraps an octave.

### Modifiers

| Symbol | Meaning |
| --- | --- |
| `+` | raise by one semitone (chromatic) |
| `-` | lower by one semitone (chromatic) |
| `++`, `--` | stack `+` and `-` for whole-tone shifts |
| `+Nc`, `-Nc` | raise / lower by *N* cents (microtonal) |

`+`/`-` shift by 100 cents; `+Nc`/`-Nc` shift by exactly *N* cents.
See [Microtones](/guide/microtones).

## Standard intervals (12-EDO)

| Interval | Semitones | Cents | Name |
| --- | ---: | ---: | --- |
| `R` / `P1` | 0 | 0 | Perfect unison |
| `m2` | 1 | 100 | Minor second |
| `M2` | 2 | 200 | Major second |
| `m3` | 3 | 300 | Minor third |
| `M3` | 4 | 400 | Major third |
| `P4` | 5 | 500 | Perfect fourth |
| `A4` / `d5` | 6 | 600 | Tritone |
| `P5` | 7 | 700 | Perfect fifth |
| `m6` | 8 | 800 | Minor sixth |
| `M6` | 9 | 900 | Major sixth |
| `m7` | 10 | 1000 | Minor seventh |
| `M7` | 11 | 1100 | Major seventh |
| `P8` | 12 | 1200 | Perfect octave |

## Extended intervals

| Interval | Semitones | Cents | Name |
| --- | ---: | ---: | --- |
| `m9` | 13 | 1300 | Minor ninth |
| `M9` | 14 | 1400 | Major ninth |
| `m10` | 15 | 1500 | Minor tenth |
| `M10` | 16 | 1600 | Major tenth |
| `P11` | 17 | 1700 | Perfect eleventh |
| `A11` | 18 | 1800 | Augmented eleventh |
| `P12` | 19 | 1900 | Perfect twelfth |
| `m13` | 20 | 2000 | Minor thirteenth |
| `M13` | 21 | 2100 | Major thirteenth |

## Arithmetic

```rela
M3 + m3     ; = P5 (4 + 3 = 7 semitones)
P5 + P4     ; = P8 (7 + 5 = 12 semitones)
P8 - P5     ; = P4
M7 - M3     ; = P5
invert(M3)  ; = m6 (12 - 4 = 8 semitones)
invert(P5)  ; = P4
```

Arithmetic preserves cents, so `M3 -13.7c + m3` returns a fifth that
is 13.7 cents flat of `P5`.

## Microtonal intervals

Append a cents offset to fine-tune. Chains compose by addition:

```rela
M3 -13.7c       ; just-intonation major third
P5 +1.96c       ; well-temperament perfect fifth (Werckmeister III)
P1++ +50c       ; quarter-tone shy of a major second
```

See [Microtones](/guide/microtones) for the surrounding language
features — `tuning` declarations, `set tuning`, `|> in_tuning`.

## Common chord shapes

```rela
chord MajorTriad   = [ R, M3, P5 ]            ; 0, 4, 7
chord MinorTriad   = [ R, m3, P5 ]            ; 0, 3, 7
chord Diminished   = [ R, m3, d5 ]            ; 0, 3, 6
chord Augmented    = [ R, M3, A5 ]            ; 0, 4, 8

chord Maj7         = [ R, M3, P5, M7 ]        ; 0, 4, 7, 11
chord Min7         = [ R, m3, P5, m7 ]        ; 0, 3, 7, 10
chord Dom7         = [ R, M3, P5, m7 ]        ; 0, 4, 7, 10
chord Dim7         = [ R, m3, d5, d7 ]        ; 0, 3, 6, 9
chord HalfDim7     = [ R, m3, d5, m7 ]        ; 0, 3, 6, 10
chord MinMaj7      = [ R, m3, P5, M7 ]        ; 0, 3, 7, 11

chord Maj9         = [ R, M3, P5, M7, M9 ]
chord Min9         = [ R, m3, P5, m7, M9 ]
chord Maj11        = [ R, M3, P5, M7, M9, P11 ]
chord Maj13        = [ R, M3, P5, M7, M9, P11, M13 ]
```

## Common scale shapes

```rela
scale Major          = { R, M2, M3, P4, P5, M6, M7 }
scale Minor          = { R, M2, m3, P4, P5, m6, m7 }
scale HarmonicMinor  = { R, M2, m3, P4, P5, m6, M7 }
scale MelodicMinor   = { R, M2, m3, P4, P5, M6, M7 }

scale Pentatonic     = { R, M2, M3, P5, M6 }
scale MinorPentatonic = { R, m3, P4, P5, m7 }
scale Blues          = { R, m3, P4, A4, P5, m7 }

scale Dorian         = { R, M2, m3, P4, P5, M6, m7 }
scale Phrygian       = { R, m2, m3, P4, P5, m6, m7 }
scale Lydian         = { R, M2, M3, A4, P5, M6, M7 }
scale Mixolydian     = { R, M2, M3, P4, P5, M6, m7 }
scale Locrian        = { R, m2, m3, P4, P5, m6, m7 }

scale WholeTone      = { R, M2, M3, A4, A5, A6 }
scale Diminished     = { R, M2, m3, P4, A4, m6, M6, M7 }
scale Chromatic      = { R, m2, M2, m3, M3, P4, A4, P5, m6, M6, m7, M7 }
```

## Enharmonic equivalence

Intervals at the same cents distance compare equal regardless of
spelling:

```rela
A4 == d5   ; true (both six semitones)
M3 == d4   ; true (both four semitones)
m6 == A5   ; true (both eight semitones)
```

Cents offsets are also considered for equality:

```rela
M3 -100c == m3   ; true — 300 cents on both sides
```
