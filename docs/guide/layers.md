# Layers

**Layers** allow you to play multiple musical lines simultaneously. This is essential for creating harmonies, accompaniments, and full arrangements.

## Basic Syntax

Use the `layer` keyword with an array of parts:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> |
let bass = | R - - - P5 - - - |

layer [
  melody,
  bass
]
```

## Layering with Effects

Each layer can have its own effects and volume:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let lead = | <5> <6> <7> <8> |
let pad = | [R, M3, P5] - - - |
let bass = | R - P5 - |

layer [
  lead |> room_reverb |> volume 0.9,
  pad |> hall_reverb |> volume 0.5,
  bass |> volume 0.7
]
```

## Practical Example: Jazz Combo

```rela
set tempo = 120

scale Major = { R, M2, M3, P4, P5, M6, M7 }
scale Dorian = { R, M2, m3, P4, P5, M6, m7 }

; Lead line with bebop phrasing
let lead = |
  <1> <2> <3> <5>
  <8> <7> <6> <5>
  <4> <3> <2> <1>
  <1>~ - - -
|

; Comping chords (sparse, jazz style)
let comping = |
  [M3, m7]~ - - -
  - - [M3, m7]^ -
  - - - -
  - [M3, m7]~ - -
|

; Walking bass line
let walking_bass = |
  R M3 P5 M6
  m7 P5 M3 M2
|

; Metronome for practice
let click = metronome 4 4

layer [
  lead |> room_reverb,
  comping |> volume 0.6,
  walking_bass |> transpose (R - P8 - P8) |> volume 0.7,
  click |> volume 0.25
]
```

## Layering Transformations

You can apply the same transformation to multiple layers:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <3> <5> <3> |

; Create harmony by transposing
let harmony_3rd = theme |> transpose M3
let harmony_5th = theme |> transpose P5

layer [
  theme,
  harmony_3rd |> volume 0.7,
  harmony_5th |> volume 0.6
]
```

## Call and Response

Layers don't have to play simultaneously throughout. Use rests to create call-and-response patterns:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Call (first voice plays, second rests)
let call = | <1> <3> <5> <3> - - - - |

; Response (first rests, second plays)
let response = | - - - - <5> <4> <3> <2> |

layer [
  call,
  response
]
```

## Rhythmic Layers

Combine different rhythmic patterns:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

; Melody: longer notes
let melody = | <1>~ - <3>~ - <5>~ - - - |

; Accompaniment: rhythmic pattern
let rhythm = | R R R R R R R R |:8

; Counter melody
let counter = | - - <5> <4> <3> <2> <1>~ - |

layer [
  melody,
  rhythm |> transpose (R - P8) |> volume 0.4,
  counter |> volume 0.6
]
```

## Best Practices

1. **Balance volumes**: Lead voices louder, accompaniment softer
2. **Use octave separation**: Transpose bass lines down with `transpose (R - P8)`
3. **Add space**: Not every layer needs to play every beat
4. **Apply effects judiciously**: Different reverbs for different layers creates depth
5. **Keep it simple**: Start with 2-3 layers, add more as needed
