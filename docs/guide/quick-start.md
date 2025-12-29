# Quick Start

Let's create your first Relanote composition in 5 minutes.

## Hello, Music!

Create a file called `hello.rela`:

```rela
-- Define a Major scale
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Create a simple melody using scale degrees
let melody = | <1> <2> <3> <4> <5> |

-- Output the melody
melody
```

Run it:

```bash
relanote run hello.rela
```

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

### Pipes

```rela
melody |> repeat(2)
```

The pipe `|>` applies a transformation to a value, reading left-to-right.

## Render to MIDI

```bash
relanote render hello.rela -o hello.mid
```

Open `hello.mid` in any music software to hear your composition!

## Next Steps

- Learn about [Intervals](/guide/intervals) in depth
- Explore [Scales & Chords](/guide/scales-and-chords)
- Try the [Tutorial](/tutorial/getting-started)
