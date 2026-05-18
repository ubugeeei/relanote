# Microtones

Pitches in relanote default to 12-tone equal temperament (12-EDO),
which is the same grid every piano in the world uses. But "everything
is relative" includes the grid itself — pitches resolve through
whatever **tuning** is in scope. Swap that tuning and the same melody
plays at different frequencies.

This page covers three orthogonal mechanisms:

1. Direct **cents offsets** on individual pitches and intervals — a
   per-note escape hatch.
2. **Tuning declarations** — a named pitch system that scale-degree
   references resolve through.
3. **Activating a tuning** — `set tuning = …` for a whole piece, or a
   piped variant for a single passage.

## Cents on a single note

`+Xc` and `-Xc` push a pitch by `X` cents (100 cents = 1 semitone).
Modifiers can chain — `M3 +12.5c -3c` lands the pitch 9.5 cents above
the conventional major third.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Just-intonation major third — 13.7 cents flat of 12-EDO M3.
| <1> M3 -13.7c <5> |

; A blues 3rd: between m3 and M3, leaning low.
| <1> m3 +30c <5> |
```

Cents can also be the *whole* pitch, with no interval base — useful
when nothing maps cleanly into intervals:

```rela
; A pitch 50 cents above C4 (a quarter-tone "C-half-sharp").
| C4 +50c |

; Scale degree with fine-tune offset.
| <3 +5c> |
```

## Tuning declarations

A `tuning` describes how one octave is divided. The stdlib ships
several common ones (see [`tunings.rela`](https://github.com/ubugeeei/relanote/blob/main/moonbit/relanote_stdlib/prelude/tunings.rela)):

```rela
; Equal divisions of the octave — 24 quarter-tone steps.
tuning EDO24 = equal { steps: 24 }

; Explicit frequency ratios — 5-limit just intonation.
tuning JustIntonation = ratios [
  1/1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8
]

; Cents offsets relative to 12-EDO — well-temperament.
tuning WerckmeisterIII = cents [
  0.0, -3.91, -7.82, -5.86, -9.77, -1.96,
  -5.86, -3.91, -5.86, -7.82, -3.91, -7.82
]

; Non-octave equal — Bohlen-Pierce divides 3:1 into 13.
tuning BohlenPierce = ratios_per_period { period: 3/1, steps: 13 }
```

The four modes (`equal`, `ratios`, `cents`, `ratios_per_period`) cover
the systems most music theory and contemporary microtonalists use.

## Activating a tuning

`set tuning = X` switches the active tuning for the whole program:

```rela
set tuning = JustIntonation
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Now <3> is a just major third, not the tempered 400-cent one.
| <1> <3> <5> |
```

You can also tag a specific passage:

```rela
let just_passage = | <1> <3> <5> | |> in_tuning JustIntonation
let temp_passage = | <1> <3> <5> |

just_passage ++ temp_passage    ; both rooted in the same key, different feel
```

## Why bother

- **Period instruments.** Werckmeister, Kirnberger, Vallotti — playing
  18th-century music in a contemporaneous well-temperament rather than
  12-EDO is the difference between a faithful performance and a
  modernised one.
- **Non-Western traditions.** Maqam, raga, gamelan and Persian dastgah
  use intervals that don't fit on a piano. The `cents` and
  `ratios_per_period` modes are designed for them.
- **Contemporary microtonal composition.** Composers from Partch to
  Glasper drop micro-pitches into otherwise tonal material; the
  per-note cents offset is the simplest way in.
- **Subtle expression.** A "blue note" — a third slightly flatter than
  m3 — is the difference between a textbook blues phrase and a phrase
  that sounds played-by-a-human.

## Status

The AST supports microtone literals, tuning declarations and the
`set tuning` / `|> in_tuning` activation forms today
([`moonbit/relanote_ast/sound.mbt`](https://github.com/ubugeeei/relanote/blob/main/moonbit/relanote_ast/sound.mbt)).
The parser and evaluator still treat them as forward-declarations —
they parse and round-trip but don't yet shift MIDI pitch bend or change
synthesis frequencies. The audible behaviour lands alongside the
parser / evaluator ports.
