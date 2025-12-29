# Getting Started

Welcome to Relanote! This tutorial will guide you through creating your first musical composition using relative intervals and functional programming.

## What You'll Learn

1. Understanding intervals
2. Creating melodies with scale degrees
3. Using pipes for transformation
4. Rendering to MIDI

## Prerequisites

Make sure you have Relanote installed. If not, see the [Installation Guide](/guide/installation).

Or use the [Web Playground](https://relanote.dev/playground) to follow along in your browser.

## Your First Program

Create a new file called `tutorial.rela` and add:

```rela
-- My first Relanote program!
scale Major = { R, M2, M3, P4, P5, M6, M7 }

| <1> <3> <5> |
```

Run it:

```bash
relanote run tutorial.rela
```

You should see output showing three intervals: the root, major third, and perfect fifth. This is a **major triad**!

## Understanding the Output

```
Block {
  slots: [
    Note { interval: R (0 semitones) },
    Note { interval: M3 (4 semitones) },
    Note { interval: P5 (7 semitones) }
  ]
}
```

Relanote shows you the internal representation. Notice how intervals are measured in semitones from the root.

## Adding a Scale

Let's use scale degrees instead of raw intervals:

```rela
-- Define a major scale
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- Use scale degrees
let melody = | <1> <3> <5> |

melody
```

`<1>`, `<3>`, `<5>` refer to the 1st, 3rd, and 5th degrees of the scale. This is the same major triad, but now expressed in terms of scale degrees!

## Creating a Melody

Let's make something more interesting:

```rela
scale Major = { R, M2, M3, P4, P5, M6, M7 }

-- A simple melody
let melody = | <1> <2> <3> <4> <5> <5> <3> <4> <5> <5> <1> |

melody
```

This creates a familiar melody using the major scale.

## Render to MIDI

Let's hear it! Render to a MIDI file:

```bash
relanote render tutorial.rela -o melody.mid
```

Open `melody.mid` in your favorite music software (GarageBand, Logic, Ableton, etc.) to hear your creation!

## What's Next?

- [Your First Melody](/tutorial/first-melody) - Create a complete melody with rhythm
- [Building Chords](/tutorial/building-chords) - Learn to create chord progressions
- [Creating a Song](/tutorial/creating-a-song) - Put it all together

## Quick Reference

| Syntax | Meaning |
|--------|---------|
| `R, M3, P5` | Intervals (Root, Major 3rd, Perfect 5th) |
| `scale Name = { ... }` | Define a scale from intervals |
| `<n>` | Reference the nth scale degree |
| `\|>` | Pipe operator (apply left to right) |
| `let x = ...` | Define a variable |
| `\| ... \|` | Create a block (sequence of notes) |
| `-` | Rest |
