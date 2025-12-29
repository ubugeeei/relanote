# Functions

Relanote is a **pure functional** language. Functions are first-class values that can be passed around, composed, and applied to data.

## Lambda Expressions

Create anonymous functions with the `\` (lambda) syntax:

```rela
-- Single parameter
\x -> x + P8

-- Multiple parameters
\x y -> x ++ y

-- Used inline
| <1> <2> <3> | |> (\b -> b |> repeat 2)
```

## Let Bindings

Use `let` to bind values and create named functions:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Bind a value
let melody = | <1> <3> <5> |

-- Bind a function
let up_octave = \b -> b |> transpose P8

-- Apply
melody |> up_octave
```

### Let-In Expressions

For local bindings within an expression:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let result =
  let theme = | <1> <3> <5> | in
  let variation = theme |> reverse in
  theme ++ variation

result
```

## Built-in Functions

### Block Transformations

| Function | Description | Example |
|----------|-------------|---------|
| `reverse` | Reverse slot order | `melody \|> reverse` |
| `repeat n` | Repeat n times | `melody \|> repeat 2` |
| `transpose interval` | Shift all pitches | `melody \|> transpose P5` |

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let theme = | <1> <2> <3> <4> |

-- Transformations
let reversed = theme |> reverse
let doubled = theme |> repeat 2
let higher = theme |> transpose P5
```

### Rhythm & Feel

| Function | Description | Example |
|----------|-------------|---------|
| `swing` | Apply swing feel | `melody \|> swing` |
| `double_time` | Halve durations | `melody \|> double_time` |

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let straight = | <1> <2> <3> <4> <5> <6> <7> <8> |

-- Jazz swing feel
let swung = straight |> swing

-- Double tempo
let fast = straight |> double_time
```

### Effects

| Function | Description | Example |
|----------|-------------|---------|
| `volume level` | Set volume (0.0-1.0) | `melody \|> volume 0.8` |
| `reverb level` | Add reverb | `melody \|> reverb 0.5` |
| `room_reverb` | Room reverb preset | `melody \|> room_reverb` |
| `hall_reverb` | Hall reverb preset | `melody \|> hall_reverb` |
| `plate_reverb` | Plate reverb preset | `melody \|> plate_reverb` |
| `dry` | No reverb | `melody \|> dry` |

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <8> |

-- Apply effects
melody
  |> hall_reverb
  |> volume 0.7
```

### Utility

| Function | Description | Example |
|----------|-------------|---------|
| `metronome bars beats` | Generate click track | `metronome 4 4` |

```rela
-- 4 bars of 4/4 metronome
let click = metronome 4 4 |> volume 0.3
```

## Function Composition

Compose functions with `>>`:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Create a reusable transformation
let jazz_transform = transpose P5 >> swing >> room_reverb

-- Apply to any melody
let melody1 = | <1> <3> <5> |
let melody2 = | <5> <4> <3> <2> |

melody1 |> jazz_transform
melody2 |> jazz_transform
```

## Higher-Order Functions

Functions that take or return other functions:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Function that returns a transposition function
let make_transposer = \interval -> (\b -> b |> transpose interval)

let up_fifth = make_transposer P5
let up_octave = make_transposer P8

| <1> <3> <5> | |> up_fifth
| <1> <3> <5> | |> up_octave
```

## Practical Example: Theme and Variations

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Original theme
let theme = | <1> <3> <5> <3> <1>~ - - - |

-- Variation functions
let retrograde = \b -> b |> reverse
let inversion = \b -> b |> transpose P8 |> reverse
let augmentation = \b -> b |> repeat 2
let diminution = \b -> b |> double_time

-- Apply variations
let var1 = theme |> retrograde
let var2 = theme |> inversion
let var3 = theme |> augmentation
let var4 = theme |> diminution

-- Combine all
theme ++ var1 ++ var2 ++ var3 ++ var4
```

## Best Practices

1. **Name transformations**: Give meaningful names to composed functions
2. **Keep functions pure**: No side effects, same input = same output
3. **Compose small functions**: Build complex behavior from simple pieces
4. **Use partial application**: `transpose P5` creates a reusable function
5. **Document with comments**: Use `--` to explain complex transformations
