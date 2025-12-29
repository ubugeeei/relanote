# Blocks

Blocks are sequences of musical events - notes, rests, and chords - that form the basic unit of composition.

## Basic Block Syntax

A block is enclosed in pipe delimiters `| |`:

```rela
-- A simple melody using intervals
| R M3 P5 M3 |

-- Using scale degrees
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <2> <3> <4> <5> |

melody
```

## Rests

Use `-` for rests:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> - <3> - <5> |    -- Note, rest, note, rest, note

melody
```

## Duration

By default, each slot is one beat. Modify with `:n`:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Each note with specific duration
let melody = | <1>:2 <3>:1 <5>:1 |    -- 2 beats, 1 beat, 1 beat

melody
```

## Articulations

Add articulations after notes:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let staccato = | <1>' <3>' <5> |      -- Staccato (')
let accented = | <1>^ <3>^ <5> |      -- Accent (^)
```

## Block Operations

### Concatenation

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let a = | <1> <3> |
let b = | <5> <8> |
let combined = a ++ b    -- | <1> <3> <5> <8> |

combined
```

### Repetition

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let pattern = | <1> <3> <5> |
let repeated = pattern |> repeat(4)    -- Play 4 times

repeated
```

### Transformation

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <3> <5> <3> |

-- Reverse
let backwards = melody |> reverse

-- Transpose
let higher = melody |> transpose(P5)

backwards
```

### Mapping

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let melody = | <1> <2> <3> |

-- Add octave to each note
let octaveUp = melody |> map(\n -> n + P8)

octaveUp
```
