# Quick Start

Get up and running with Relanote in 5 minutes.

## Hello, Music!

Create a file called `hello.rela`:

```rela
-- Set the key and tempo
set key = C4
set tempo = 120

-- Define a major scale
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Create a simple melody using scale degrees
let melody = | <1> <3> <5> <3> <1> |

-- Play it!
melody
```

Run it:

```bash
relanote run hello.rela
```

Or try it in the [Web Playground](https://ubugeeei.github.io/relanote/).

## Understanding the Code

### Intervals

`R, M2, M3, P4, P5, M6, M7` are **intervals**:
- `R` = Root (unison)
- `P` = Perfect (4th, 5th, octave)
- `M` = Major (2nd, 3rd, 6th, 7th)
- `m` = Minor
- `A` = Augmented
- `d` = Diminished

The number indicates the scale degree.

### Scales

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }
```

A `scale` defines a set of intervals from a root note using curly braces.

### Scale Degrees

```rela
| <1> <2> <3> <4> <5> |
```

`<n>` refers to the nth degree of the current scale. The `| |` delimiters create a block of notes.

### Relative Rhythm

The number of slots in a block determines the rhythm:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

| <1> <2> <3> <4> |    -- 4 notes in 1 beat = each is 0.25 beats
| <1> <5> |            -- 2 notes in 1 beat = each is 0.5 beats
| <1> |                -- 1 note fills the whole beat
```

Use `:n` to set the block's total duration:

```rela
| <1> <2> <3> <4> |:4  -- 4 notes in 4 beats = quarter notes
```

### Block Concatenation

Combine blocks with `++`. Each block keeps its own rhythm:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

let fast = | <1> <2> <3> <4> |      -- 4 notes = fast
let slow = | <1> <5> |              -- 2 notes = slower
let melody = fast ++ slow           -- Both rhythms preserved!

melody
```

### Pipes

```rela
melody |> repeat(2)
melody |> transpose(P5)
melody |> reverse
```

The pipe `|>` applies a transformation to a value, reading left-to-right.

## Render to MIDI

```bash
relanote render hello.rela -o hello.mid
```

Open `hello.mid` in any music software to hear your composition!

## Setting the Key

By default, the root note is C4 (middle C). You can specify a different key:

```rela
set key = Bb3   -- B-flat below middle C
set tempo = 140 -- 140 BPM

scale Major = { R, M2, M3, P4, P5, M6, M7 }
| <1> <3> <5> |
```

## Quick Reference

| Syntax | Meaning |
|--------|---------|
| `R, M3, P5` | Intervals |
| `C4, Bb3, F#4` | Absolute pitches |
| `scale Name = { ... }` | Define a scale |
| `<n>` | nth scale degree |
| `\| ... \|` | Block (sequence) |
| `\| ... \|:n` | Block with n beats |
| `-` | Rest |
| `++` | Concatenate |
| `\|>` | Pipe |
| `[ ... ]` | Chord |
| `set key = C4` | Set root note |
| `set tempo = 120` | Set tempo |

## Next Steps

- Learn about [Intervals](/guide/intervals) in depth
- Explore [Blocks](/guide/blocks) and rhythm
- Try the [Tutorial](/tutorial/getting-started)
