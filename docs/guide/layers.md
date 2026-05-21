# Layers

`++` plays blocks **in sequence**. `layer [ ... ]` plays them **in
parallel** — two or more voices running concurrently over the same
time window. It's the building block for harmony, counterpoint,
accompaniment and any "two lines at once" arrangement.

## Basic syntax

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> |
let bass   = | <1> -   <5> -   |

layer [
  melody,
  bass
]
```

The lines start at the same instant and run for the same total time;
relative-rhythm rules apply to each line independently, so a 4-note
melody against a 2-note bass simply means the bass holds twice as
long.

## Layers and effects

Each layer carries its own pipe chain — voice, volume, effects:

```rela
let lead = | <5> <6> <7> <8> |
let pad  = | [<1> M3 P5] - - - |
let bass = | <1> - <5> - |

layer [
  lead |> voice ModularLead |> volume 0.85 |> reverb 0.3,
  pad  |> voice FloatingBloom |> volume 0.50,
  bass |> voice BassMoog |> volume 0.70
]
```

## Build harmony by transposing

The most direct way to harmonise a line is to layer it with
transposed copies of itself:

```rela
let theme = | <1> <3> <5> <3> |

layer [
  theme,
  theme |> transpose M3 |> volume 0.7,
  theme |> transpose P5 |> volume 0.6
]
```

## Call and response

Layers don't have to play *constantly*. Punctuate with rests:

```rela
let call     = | <1> <3> <5> <3> - - - - |
let response = | - - - - <5> <4> <3> <2> |

layer [ call, response ]
```

## Rhythmic counterpoint

Different densities in different layers — the most reliable way to
make an arrangement feel alive:

```rela
let melody  = | <1>~ - <3>~ - <5>~ - - - |
let pattern = | R R R R R R R R |
let counter = | - - <5> <4> <3> <2> <1>~ - |

layer [
  melody,
  pattern |> transpose -P8 |> voice LofiHat |> volume 0.4,
  counter |> voice ModularLead |> volume 0.6
]
```

## Layers vs sections

`section { part ... part ... }` is also concurrent parts. The
difference is intent:

- **`section`** — concurrent **roles** that belong together because
  they're the same structural unit (verse, chorus). The mixer can
  address each `part "Name"` by name; sidechains, sends and
  per-instrument effects belong here.
- **`layer [ ... ]`** — concurrent **lines** built inline, without
  naming them. Cheap and good for one-off harmonies, counter-melodies
  and ornaments inside a single block expression.

A reasonable rule: if the lines need to be addressable from the
[mix](./mixing) block, use `part` inside a `section`. Otherwise reach
for `layer`.

## Layers within a section

You can also nest a `layer` inside a `part`:

```rela
section "Bridge" {
  part "Lead" {
    layer [
      | <5> <6> <7> <8> |,
      | <3> <4> <5> <6> | |> volume 0.6
    ]
  } |> voice ModularLead
}
```

The whole `layer` becomes a single addressable track called
`"Bridge.Lead"` for mixing purposes.

## Rules of thumb

- **Balance volumes**: lead voices loudest, accompaniment softer,
  sub layers softest of all.
- **Octave separation prevents mud**: drop bass with `|> transpose -P8`.
- **Leave space**: not every layer needs to play every beat — silence
  in one layer makes the others louder.
- **Mind the mix**: if you're routing reverb or sidechaining,
  promote the layer to a named `part` so the [mix](./mixing) block
  can address it.

## Listen-through example

The docs preview plays `layer [ ... ]` as simultaneous voices, so this
example keeps the bass, harmony and lead independent while still fitting
inside a tiny program.

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let bass = | R - P5 - |:4 |> voice(FatBass)
let keys = | [R, M3, P5] - [P4, M6, P8] - |:4 |> voice(FMRhodes)
let lead = | P8 M10 P12 M10 P8 - M7 - |:4 |> voice(Lead)

layer [bass, keys, lead]
```
